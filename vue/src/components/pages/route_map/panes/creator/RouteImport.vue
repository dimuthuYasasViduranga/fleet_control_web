<template>
  <div class="route-import">
    <div>Supported types</div>
    <div class="supported-definitions">
      <button
        class="hx-btn"
        v-for="(definition, index) in definitions"
        :key="index"
        :class="{ selected: definition === selectedDefinition }"
        @click="onSetDefinition(definition)"
      >
        {{ definition.type }}
      </button>
    </div>
    <div v-if="selectedDefinition" class="definition">
      <div class="extensions">Expected extensions: {{ selectedDefinition.extensions }}</div>
      <div class="notes">
        <ul>
          <li v-for="(item, index) in selectedDefinition.notes" :key="index">
            <template v-if="Array.isArray(item)">
              {{ item[0] }}
              <ul>
                <li v-for="(subItem, index) in item[1]" :key="`sub-${index}`">
                  {{ subItem }}
                </li>
              </ul>
            </template>
            <template v-else>
              {{ item }}
            </template>
          </li>
        </ul>
      </div>
      <pre class="example">{{ selectedDefinition.example }}</pre>
      <button class="hx-btn" @click="onDownload(selectedDefinition)">Download Example</button>
    </div>
    <div class="import-area">
      <FileInput
        :accepts="validExtensions"
        :multiple="true"
        :loading="processingFiles"
        @upload="onUploadFiles"
      />
    </div>
    <div class="map-wrapper">
      <div class="gmap-map">
        <div style="display: none">
          <RecenterIcon ref="recenter-control" tooltip="right" @click.native="reCenter" />
          <ResetZoomIcon ref="reset-zoom-control" tooltip="right" @click.native="resetZoom" />
          <PolygonIcon
            ref="geofence-control"
            tooltip="right"
            :highlight="!showLocations"
            @click.native="toggleShowLocations()"
          />
        </div>
        <GmapMap
          ref="gmap"
          :map-type-id="mapType"
          :center="center"
          :zoom="zoom"
          @zoom_changed="zoomChanged"
          :options="{
            tilt: 0,
          }"
        >
          <g-map-geofences
            v-if="showLocations"
            :geofences="locations"
            :options="{ fillOpacity: 0.3, strokeOpacity: 0.2 }"
          />

          <gmap-polyline
            v-for="(path, index) in existingSegmentPaths"
            :key="`existing-${index}`"
            :path="path"
            :options="{
              strokeColor: 'darkgreen',
              strokeWeight: 10,
              zIndex: 1,
              clickable: false,
            }"
          />

          <gmap-polyline
            v-for="(item, index) in pendingPaths"
            :key="`pending-${index}`"
            :path="item.path"
            :options="{
              strokeColor: selectedPathId === item.id ? 'blue' : 'orange',
              strokeWeight: 10,
              zIndex: selectedPathId === item.id ? 10 : 5,
            }"
            @click="onSetSelectedPathId(item.id)"
            @dblclick="e => e.stop()"
          />
        </GmapMap>
      </div>
    </div>
    <div v-if="pendingPaths.length" class="processed-paths">
      <table-component
        table-wrapper="#content"
        table-class="table"
        tbody-class="table-body"
        thead-class="table-head"
        filterNoResults="No dig units have been assigned to devices"
        :data="pendingPaths"
        :show-caption="false"
        :show-filter="false"
      >
        <table-column cell-class="table-select-cel">
          <template slot-scope="row">
            <span>
              <input
                type="checkbox"
                :checked="row.id === selectedPathId"
                @change="onSetSelectedPathId(row.id)"
              />
            </span>
          </template>
        </table-column>

        <table-column cell-class="table-cel" label="name" show="name" />

        <table-column cell-class="table-cel" label="Points" show="pathLength" data-type="numeric" />

        <table-column cell-class="table-cel">
          <template slot-scope="row">
            <div class="actions">
              <Icon
                v-tooltip="'Accept'"
                class="accept-icon"
                :icon="tickIcon"
                @click="onAccept(row)"
              />
              <Icon
                v-tooltip="'Reject'"
                class="reject-icon"
                :icon="crossIcon"
                @click="onReject(row)"
              />
            </div>
          </template>
        </table-column>
      </table-component>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { gmapApi } from 'gmap-vue';
import { TableComponent, TableColumn } from 'vue-table-component';

import Icon from 'hx-layout/Icon.vue';

import GMapGeofences from '@/components/gmap/GMapGeofences.vue';
import PolygonIcon from '@/components/gmap/PolygonIcon.vue';
import RecenterIcon from '@/components/gmap/RecenterIcon.vue';
import ResetZoomIcon from '@/components/gmap/ResetZoomIcon.vue';

import TickIcon from '@/components/icons/Tick.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';

import ConfirmModal from '@/components/modals/ConfirmModal.vue';
import FileInput from '@/components/FileInput.vue';

import { getDefinitions, parseFile } from './parsers/parsers';
import { attachControl } from '@/components/gmap/gmapControls';
import { setMapTypeOverlay } from '@/components/gmap/gmapCustomTiles';

export default {
  name: 'RouteImport',
  components: {
    TableComponent,
    TableColumn,
    Icon,
    FileInput,
    GMapGeofences,
    PolygonIcon,
    RecenterIcon,
    ResetZoomIcon,
  },
  props: {
    segments: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      selectedDefinition: null,
      definitions: getDefinitions(),
      processingFiles: false,
      pendingPaths: [],
      mapType: 'satellite',
      center: {
        lat: 0,
        lng: 0,
      },
      zoom: 0,
      showLocations: true,
      selectedPathId: null,
      tickIcon: TickIcon,
      crossIcon: CrossIcon,
    };
  },
  computed: {
    google: gmapApi,
    ...mapState('constants', {
      mapManifest: state => state.mapManifest,
      defaultCenter: ({ mapCenter }) => ({ lat: mapCenter.latitude, lng: mapCenter.longitude }),
      defaultZoom: state => state.mapZoom,
    }),
    supportedDefinitions() {
      return this.definitions.map(t => t.type);
    },
    validExtensions() {
      return this.definitions.reduce((acc, definition) => {
        return acc.concat(definition.extensions);
      }, []);
    },
    existingSegmentPaths() {
      return this.segments.map(s => s.path);
    },
  },
  mounted() {
    this.reCenter();
    this.resetZoom();

    this.gPromise().then(map => {
      // set greedy mode so that scroll is enabled anywhere on the page
      map.setOptions({ gestureHandling: 'greedy' });
      attachControl(map, this.google, this.$refs['recenter-control'], 'LEFT_TOP');
      attachControl(map, this.google, this.$refs['reset-zoom-control'], 'LEFT_TOP');
      attachControl(map, this.google, this.$refs['geofence-control'], 'LEFT_TOP');
      setMapTypeOverlay(map, this.google, this.mapManifest);
    });
  },
  methods: {
    gPromise() {
      return this.$refs.gmap.$mapPromise;
    },
    reCenter() {
      this.moveTo(this.defaultCenter);
    },
    moveTo(latLng) {
      this.gPromise().then(map => map.panTo(latLng));
    },
    zoomChanged(zoomLevel) {
      this.zoom = zoomLevel;
    },
    resetZoom() {
      this.zoom = this.defaultZoom;
    },
    toggleShowLocations() {
      this.showLocations = !this.showLocations;
    },
    onSetDefinition(definition) {
      if (this.selectedDefinition === definition) {
        this.selectedDefinition = null;
      } else {
        this.selectedDefinition = definition;
      }
    },
    onSetSelectedPathId(id) {
      if (this.selectedPathId === id) {
        this.selectedPathId = null;
      } else {
        this.selectedPathId = id;
      }
    },
    onDownload(definition) {
      definition.download();
    },
    onUploadFiles(files) {
      if (!this.pendingPaths.length) {
        this.uploadFiles(files);
        return;
      }

      const opts = {
        title: 'You have pending data',
        body: 'There are pending paths recently uploaded, what would you like to do?',
        actions: ['Append New', 'Override Existing', 'Cancel'],
      };

      this.$modal.create(ConfirmModal, opts).onClose(resp => {
        if (resp === 'Append New') {
          this.uploadFiles(files, 'append');
        } else if (resp === 'Override Existing') {
          this.uploadFiles(files, 'override');
        }
      });
    },
    uploadFiles(files, action = 'override') {
      this.processingFiles = true;
      Promise.all(files.map(f => parseFile(f, this.definitions)))
        .then(resps => {
          this.processingFiles = false;
          const pendingPaths = resps.flat().filter(p => p.path.length);

          if (pendingPaths.length === 0) {
            this.$toaster.error('No valid data found in the file(s)');
            return;
          }

          const offset = Math.max(...this.pendingPaths.map(p => p.id), 0) + 1;
          pendingPaths.forEach((p, index) => {
            p.id = index + offset;
            p.pathLength = p.path.length;
            if (!p.name || p.name === 'Path') {
              return `path-${p.id}`;
            }
          });

          if (action === 'append') {
            this.setPendingPaths(this.pendingPaths.concat(pendingPaths));
          } else {
            this.setPendingPaths(pendingPaths);
          }
        })
        .catch(error => {
          if (files.length === 1) {
            this.$toaster.error('Could not process the uploaded file');
          } else {
            this.$toaster.error('Could not process one of the uploaded files');
          }
          console.error(error);
          this.processingFiles = false;
        });
    },
    setPendingPaths(paths) {
      this.pendingPaths = paths;
    },
    onAccept(row) {
      this.$emit('add', row.path);
      this.pendingPaths = this.pendingPaths.filter(p => p.id !== row.id);
    },
    onReject(row) {
      this.pendingPaths = this.pendingPaths.filter(p => p.id !== row.id);
    },
  },
};
</script>

<style>
.route-import {
  margin-top: 1rem;
}

/* examples */
.route-import .supported-definitions {
  display: flex;
}

.route-import .supported-definitions button {
  opacity: 0.9;
  border: 1px solid #364c59;
}

.route-import .supported-definitions button.selected {
  border-color: #b6c3cc;
  opacity: 1;
}

.route-import .definition {
  border-bottom: 1px solid #677e8c;
  margin-top: 1rem;
  padding-left: 1rem;
}

.route-import .definition .notes {
  margin-top: 0.5rem;
}

.route-import .definition .notes li {
  padding: 0.1rem 0;
}

.route-import .definition .example {
  padding: 0.5rem;
  background-color: #2c404c;
  overflow-x: auto;
}

/* file import */
.route-import .file-input {
  margin-top: 1rem;
  height: 5rem;
}

/* map */
.route-import .map-wrapper {
  position: relative;
  height: 50vh;
  width: 100%;
}

.route-import .gmap-map {
  height: 100%;
  width: 100%;
}

.route-import .gmap-map .vue-map-container {
  height: 100%;
}

/* table */
.route-import input[type='checkbox'] {
  height: 1.2rem;
  width: 1.2rem;
}

.route-import .table-select-cel {
  width: 2rem;
}

.route-import .table-cel .actions {
  display: inline-flex;
}

.route-import .table-cel .actions > .hx-icon {
  cursor: pointer;
  margin: 0 0.5rem;
}

.route-import .table-cel .actions > .hx-icon:hover {
  opacity: 0.5;
}

.route-import .table-cel .actions > .accept-icon:hover {
  stroke: rgb(0, 255, 0);
}

.route-import .table-cel .actions > .reject-icon:hover {
  stroke: red;
}
</style>