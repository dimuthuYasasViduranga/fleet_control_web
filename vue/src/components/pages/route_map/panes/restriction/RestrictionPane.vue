<template>
  <div class="restriction-pane">
    <div class="modes">
      <button
        class="hx-btn"
        v-for="mode in modes"
        :key="mode"
        :class="{ selected: mode === selectedMode }"
        @click="setMode(mode)"
      >
        {{ mode }}
      </button>
    </div>

    <RestrictionGroupEditor
      v-if="selectedMode === 'editor'"
      v-model="localRestrictionGroups"
      :assetTypes="assetTypes"
    />

    <div v-show="selectedMode === 'map'" class="map-wrapper">
      <div class="groups">
        <div
          class="group-tile"
          v-for="(group, index) in localRestrictionGroups"
          :key="index"
          :class="{ unset: !group.graph }"
        >
          <div class="name">{{ group.name }}</div>
          <div class="actions">
            <div>
              <button class="hx-btn" @click="onSetGraph(group)">Set</button>
              <button class="hx-btn" :disabled="!group.graph" @click="onLoadGraph(group)">
                Load
              </button>
            </div>
            <div>
              <button class="hx-btn" :disabled="!group.graph" @click="onClearGraph(group)">
                Clear
              </button>
            </div>
          </div>
        </div>
      </div>
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
            :options="{ fillOpacity: 0.2, strokeOpacity: 0.2 }"
          />
        </GmapMap>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { gmapApi } from 'gmap-vue';

import GMapGeofences from '@/components/gmap/GMapGeofences.vue';

import PolygonIcon from '@/components/gmap/PolygonIcon.vue';
import RecenterIcon from '@/components/gmap/RecenterIcon.vue';
import ResetZoomIcon from '@/components/gmap/ResetZoomIcon.vue';

import RestrictionGroupEditor from './RestrictionGroupEditor.vue';

import { attachControl } from '@/components/gmap/gmapControls';
import { setMapTypeOverlay } from '@/components/gmap/gmapCustomTiles';
import { copy } from '@/code/helpers';

const MODES = ['editor', 'map'];

export default {
  name: 'RestrictionPane',
  components: {
    GMapGeofences,
    PolygonIcon,
    RecenterIcon,
    ResetZoomIcon,
    RestrictionGroupEditor,
  },
  props: {
    graph: { type: Object },
    locations: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
    restrictionGroups: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      mapType: 'satellite',
      center: {
        lat: 0,
        lng: 0,
      },
      localRestrictionGroups: [],
      zoom: 0,
      showLocations: true,
      modes: MODES,
      selectedMode: MODES[1],
    };
  },
  computed: {
    google: gmapApi,
    ...mapState('constants', {
      mapManifest: state => state.mapManifest,
      defaultCenter: ({ mapCenter }) => ({ lat: mapCenter.latitude, lng: mapCenter.longitude }),
      defaultZoom: state => state.mapZoom,
    }),
  },
  watch: {
    restrictionGroups: {
      immediate: true,
      handler(groups) {
        this.localRestrictionGroups = groups.map(copy);
      },
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
    stopGEvent(event) {
      event.stop();
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
    setMode(mode) {
      this.selectedMode = mode;
    },
    onGroupUpdate(index, newGroup) {
      this.localRestrictionGroups[index] = newGroup;
      this.localRestrictionGroups = this.localRestrictionGroups.slice();
    },
    onSetGraph(group) {
      console.dir('---- set graph');
      group.graph = true;
      this.localRestrictionGroups = this.localRestrictionGroups.slice();
    },
    onLoadGraph(group) {
      console.dir('=--- load graph');
    },
    onClearGraph(group) {
      console.dir('---- clear graph');
      group.graph = false;
      this.localRestrictionGroups = this.localRestrictionGroups.slice();
    },
  },
};
</script>

<style>
/* modes */

.restriction-pane > .modes {
  margin-top: 1rem;
  width: 100%;
  display: flex;
}

.restriction-pane > .modes > button {
  opacity: 0.75;
  width: 100%;
}

.restriction-pane > .modes > button.selected {
  border-color: #b6c3cc;
  opacity: 1;
}

/* groups */
.restriction-pane .groups {
  display: inline-flex;
}

.restriction-pane .groups .group-tile {
  min-width: 8rem;
  text-align: center;
  border: 1px solid gray;
  margin: 0.1rem;
}

.restriction-pane .groups .group-tile.unset {
  border-color: orange;
}

.restriction-pane .groups .group-tile .actions > * {
  display: flex;
}

.restriction-pane .groups .group-tile .actions button {
  margin: 2px;
  width: 100%;
}

.restriction-pane .groups .group-tile .actions button[disabled] {
  opacity: 0.5;
  pointer-events: none;
}

.restriction-pane .groups .group-tile .name {
  font-size: 1.6rem;
  padding: 0 0.5rem;
}

/* map */
.restriction-pane .map-wrapper {
  position: relative;
  height: 60vh;
  width: 100%;
}

.restriction-pane .gmap-map {
  height: 100%;
  width: 100%;
}

.restriction-pane .gmap-map .vue-map-container {
  height: 100%;
}
</style>