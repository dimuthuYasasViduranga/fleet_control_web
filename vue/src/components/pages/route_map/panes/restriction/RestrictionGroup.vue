<template>
  <div class="restriction-group">
    <input
      ref="input"
      class="search typeable"
      type="text"
      placeholder="Group Name"
      :value="name"
      :disabled="!canEditName"
      @change="onNameChange"
    />
    <button
      v-if="canRemove && assetTypes.length === 0"
      class="hx-btn"
      style="float: right"
      @click="onRemove()"
    >
      Remove
    </button>
    <div class="content">
      <div v-show="showPreview" class="preview">
        <div class="map-wrapper">
          <div class="gmap-map" hide-info>
            <GmapMap
              ref="gmap"
              :map-type-id="mapType"
              :center="center"
              :zoom="zoom"
              @zoom_changed="zoomChanged"
              :options="{
                tilt: 0,
                fullscreenControl: false,
              }"
            >
              <g-map-geofences
                :geofences="locations"
                :options="{ fillOpacity: 0.2, strokeOpacity: 0.2 }"
              />

              <gmap-polyline
                v-for="(poly, index) in polylineSegments"
                :key="`segment-${index}`"
                :path="poly.path"
                :options="{
                  strokeColor: poly.color,
                  strokeWeight: 10,
                  icons: poly.icons,
                  zIndex: 10,
                  clickable: false,
                }"
              />
            </GmapMap>
          </div>
        </div>
        <button class="hx-btn edit-btn" @click="onEdit()">Edit</button>
      </div>
      <Container
        orientation="horizontal"
        group-name="restriction"
        :drop-placeholder="containerPlaceholderOptions"
        :get-child-payload="index => getPayload(index)"
        @drop="onDrop"
      >
        <Draggable v-for="type in assetTypes" :key="type">
          <Icon v-tooltip="type" class="asset-type-icon" :icon="icons[type]" />
        </Draggable>
      </Container>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { gmapApi } from 'gmap-vue';
import { Container, Draggable } from 'vue-smooth-dnd';

import Icon from 'hx-layout/Icon.vue';

import GMapGeofences from '@/components/gmap/GMapGeofences.vue';

import RestrictionMapModal from './RestrictionMapModal.vue';

import { setMapTypeOverlay } from '@/components/gmap/gmapCustomTiles';
import { graphToSegments, segmentsToPolylines } from '../../common';

const FIT_PADDING = 20;

function edgesToSegments(graph, edgeIds) {
  const edgeLookup = edgeIds.reduce((acc, id) => {
    acc[id] = true;
    return acc;
  }, {});

  return graphToSegments(graph)
    .map(s => {
      const aId = s.edges.find(e => e.endVertexId === s.vertexBId)?.data?.edgeId;
      const bId = s.edges.find(e => e.endVertexId === s.vertexAId)?.data?.edgeId;

      const e1 = edgeLookup[aId];
      const e2 = edgeLookup[bId];

      if (!e1 && !e2) {
        return;
      }

      if (e1 && !e2) {
        s.direction = 'positive';
      } else if (!e1 && e2) {
        s.direction = 'negative';
      }

      return s;
    })
    .filter(s => s);
}

export default {
  name: 'RestrictionGroup',
  components: {
    Container,
    Draggable,
    Icon,
    GMapGeofences,
  },
  props: {
    name: { type: String, default: '' },
    assetTypes: { type: Array, default: () => [] },
    graph: { type: Object },
    edgeIds: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    canEditName: { type: Boolean, default: true },
    canRemove: { type: Boolean, default: true },
    showPreview: { type: Boolean, default: true },
  },
  data: () => {
    return {
      mapType: 'satellite',
      center: {
        lat: 0,
        lng: 0,
      },
      zoom: 0,
      containerPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
    };
  },
  computed: {
    google: gmapApi,
    ...mapState('constants', {
      icons: state => state.icons,
      mapManifest: state => state.mapManifest,
      defaultCenter: ({ mapCenter }) => ({ lat: mapCenter.latitude, lng: mapCenter.longitude }),
      defaultZoom: state => state.mapZoom,
    }),
    segments() {
      return edgesToSegments(this.graph, this.edgeIds);
    },
    polylineSegments() {
      return segmentsToPolylines(this.segments);
    },
  },
  watch: {
    polylineSegments() {
      this.fitSegments();
    },
  },
  mounted() {
    this.reCenter();
    this.resetZoom();

    this.gPromise().then(map => {
      // set greedy mode so that scroll is enabled anywhere on the page
      map.setOptions({ gestureHandling: 'greedy' });

      setMapTypeOverlay(map, this.google, this.mapManifest);
      // trigger fit bounds on the graph
    });

    this.fitSegments();
  },
  methods: {
    gPromise() {
      return this.$refs.gmap?.$mapPromise || Promise.reject('not_loaded');
    },
    getPayload(index) {
      return this.assetTypes[index];
    },
    onDrop({ addedIndex, removedIndex, payload }) {
      // is added
      if (addedIndex != null && removedIndex == null) {
        this.$emit('added', { assetType: payload });
      }
    },
    fitSegments() {
      const segments = this.segments;
      if (!segments.length) {
        this.resetZoom();
        this.reCenter();
      }

      const bounds = new this.google.maps.LatLngBounds();
      segments.forEach(s => s.path.forEach(p => bounds.extend(p)));

      this.gPromise().then(map => {
        map.fitBounds(bounds, FIT_PADDING);
      });
    },
    onNameChange(event) {
      this.$emit('update:name', event.target.value);
    },
    onRemove() {
      this.$emit('remove');
    },
    onEdit() {
      const opts = {
        locations: this.locations,
        graph: this.graph,
        edgeIds: this.edgeIds || [],
      };
      this.$modal.create(RestrictionMapModal, opts).onClose(resp => {
        if (resp) {
          this.$emit('edges-changed', resp);
        }
      });
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
  },
};
</script>

<style>
.restriction-group {
  border: 1px solid orange;
}

.restriction-group input[disabled] {
  border: none;
  font-style: italic;
}

.restriction-group .content {
  display: flex;
}

.restriction-group .content .preview {
  width: 11rem;
  min-width: 11rem;
  background-color: orange;
}

.restriction-group .content .preview .edit-btn {
  width: 100%;
}

/* dnd wrappers */
.restriction-group .smooth-dnd-container.horizontal {
  width: 100%;
  min-height: 5rem;
  padding: 0.25rem;
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  overflow: hidden;
  position: relative;
}

.restriction-group .smooth-dnd-container.horizontal > .smooth-dnd-draggable-wrapper {
  cursor: pointer;
  background-color: #2c404c;
  height: 4rem;
  width: 4rem;
  margin: 2px;
}

.restriction-group .tile-drop-preview {
  height: 4rem;
  width: 4rem;
  border: 1px dashed grey;
  background-color: rgba(150, 150, 200, 0.1);
  margin: 2px;
}

.restriction-group .asset-type-icon {
  height: 4rem;
  width: 4rem;
  padding: 4px;
}

/* map */
.restriction-group .map-wrapper {
  position: relative;
  height: 10rem;
  width: 100%;
}

.restriction-group .gmap-map {
  height: 100%;
  width: 100%;
}

.restriction-group .gmap-map .vue-map-container {
  height: 100%;
}
</style>