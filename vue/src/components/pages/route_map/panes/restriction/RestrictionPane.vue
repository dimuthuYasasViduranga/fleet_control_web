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
      selectedMode: MODES[0],
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