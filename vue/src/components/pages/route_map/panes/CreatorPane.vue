<template>
  <div class="creator-pane">
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
            :options="{ fillOpacity: 0.2, strokeOpacity: 0.2 }"
          />

          <template v-if="selectedMode === 'drawing'">
            <GMapDrawingControls :show="!canEdit" :modes="['polyline']" @create="onShapeCreate" />
            <GMapEditable
              v-if="canEdit"
              ref="gmap-editable"
              :edit.sync="canEdit"
              :clickToEdit="false"
              direction="vertical"
              :polylines="editablePolylines"
              :removeDeleted="false"
              @accept="onEditAccept"
              @reject="onEditReject"
            />

            <gmap-polyline
              v-for="(poly, index) in uneditablePolylines"
              :key="`polyline-${index}`"
              :path="poly.path"
              :options="{
                strokeColor: poly.color,
                strokeWeight: poly.width,
                zIndex: 10,
              }"
              @click="onPolylineClick(poly)"
            />

            <gmap-circle
              v-for="(circle, index) in circles"
              :key="`polyline-circle-${index}`"
              :center="circle.center"
              :radius="snapDistance"
              :options="{
                clickable: false,
                zIndex: 5,
                strokeOpacity: 0.5,
              }"
            />
          </template>
          <template v-else-if="selectedMode === 'directions'">
            <gmap-polyline
              v-for="(poly, index) in polylineSegments"
              :key="`segment-${index}`"
              :path="poly.path"
              :options="{
                strokeColor: poly.color,
                strokeWeight: 12,
                icons: poly.icons,
                zIndex: 10,
              }"
              @click="onSegmentClick(poly)"
              @dblclick="stopGEvent"
            />

            <gmap-circle
              v-for="(circle, index) in circles"
              :key="`segment-circle-${index}`"
              :center="circle.center"
              :radius="0"
              :options="{
                clickable: false,
                zIndex: 20,
                strokeOpacity: 0.5,
                strokeWeight: 12,
              }"
            />

            <GMapLabel
              v-for="(circle, index) in circles"
              :key="`segment-circle-label-${index}`"
              :position="circle.center"
            >
              {{ circle.id }}
            </GMapLabel>
          </template>
        </GmapMap>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { gmapApi } from 'gmap-vue';
import { setMapTypeOverlay } from '@/components/gmap/gmapCustomTiles';

import GMapDrawingControls from '@/components/gmap/GMapDrawingControls.vue';
import GMapEditable from '@/components/gmap/GMapEditable.vue';
import GMapGeofences from '@/components/gmap/GMapGeofences.vue';
import GMapLabel from '@/components/gmap/GMapLabel.vue';

import PolygonIcon from '@/components/gmap/PolygonIcon.vue';
import RecenterIcon from '@/components/gmap/RecenterIcon.vue';
import ResetZoomIcon from '@/components/gmap/ResetZoomIcon.vue';

import { uniq } from '@/code/helpers.js';
import { getUniqPaths } from '@/code/graph';
import { pixelsToMeters } from '@/code/distance';
import { attachControl } from '@/components/gmap/gmapControls';

import { segmentsToPolylines, getNodeGroups } from '../common.js';

const ROUTE_COLOR = 'darkred';
const ROUTE_EDIT_COLOR = 'purple';
const ROUTE_WIDTH = 12;
const MODES = ['drawing', 'directions'];

function graphToPolylines(graph) {
  const adjacency = graph.adjacency;
  const vertices = graph.vertices;

  const uniqPaths = getUniqPaths(adjacency);

  return uniqPaths.map(path => {
    const points = path.map(id => {
      const { lat, lng, ...rest } = vertices[id].data;
      return {
        id,
        data: rest,
        lat,
        lng,
      };
    });
    return { path: points, color: ROUTE_COLOR, width: ROUTE_WIDTH, vertices: path };
  });
}

function approxEqual(a, b, epsilon = 0.00001) {
  return Math.abs(a - b) <= epsilon;
}

function pathsEqual(a, b) {
  const aLength = a.length;
  if (aLength !== b.length) {
    return false;
  }

  for (let i = 0; i < aLength; i++) {
    const aPoint = a[i];
    const bPoint = b[i];

    if (!approxEqual(aPoint.lat, bPoint.lat) || !approxEqual(aPoint.lng, bPoint.lng)) {
      return false;
    }
  }

  return true;
}

export default {
  name: 'CreatorPane',
  components: {
    GMapDrawingControls,
    GMapEditable,
    GMapGeofences,
    GMapLabel,
    PolygonIcon,
    RecenterIcon,
    ResetZoomIcon,
  },
  props: {
    graph: { type: Object },
    segments: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    snapDistancePx: { type: Number, default: 5 },
  },
  data: () => {
    return {
      mapType: 'satellite',
      center: {
        lat: 0,
        lng: 0,
      },
      zoom: 0,
      canEdit: false,
      polylines: [],
      selectedPolyline: null,
      showLocations: true,
      modes: MODES,
      selectedMode: 'drawing',
    };
  },
  computed: {
    google: gmapApi,
    ...mapState('constants', {
      mapManifest: state => state.mapManifest,
      defaultCenter: ({ mapCenter }) => ({ lat: mapCenter.latitude, lng: mapCenter.longitude }),
      defaultZoom: state => state.mapZoom,
    }),
    uneditablePolylines() {
      return this.polylines.filter(p => p !== this.selectedPolyline);
    },
    editablePolylines() {
      if (this.selectedPolyline) {
        const poly = { ...this.selectedPolyline, color: ROUTE_EDIT_COLOR };
        return [poly];
      }
      return [];
    },
    nodeToSCCGroup() {
      const group = getNodeGroups(this.graph, this.segments);
      if (uniq(Object.values(group)).length < 2) {
        return;
      }

      return group;
    },
    polylineSegments() {
      return segmentsToPolylines(this.segments, this.nodeToSCCGroup);
    },
    snapDistance() {
      return pixelsToMeters(this.snapDistancePx, this.zoom);
    },
    circles() {
      return this.graph.getVerticesList().map(v => {
        const center = { lat: v.data.lat, lng: v.data.lng };
        return { center, id: v.id, nodeId: v.data.nodeId };
      });
    },
  },
  watch: {
    graph: {
      immediate: true,
      handler() {
        this.refreshGraphPolylines();
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
    refreshGraphPolylines() {
      this.polylines = graphToPolylines(this.graph);
      this.selectedPolyline = null;
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
    setMode(mode) {
      if (this.selectedMode === 'drawing') {
        this.canEdit = false;
        this.selectedPolyline = null;
      }

      this.selectedMode = mode;
    },
    onShapeCreate({ type, props }) {
      if (type === 'polyline') {
        this.$emit('create', { path: props.path, zoom: this.zoom });
      }
    },
    onEditAccept({ polylines }) {
      const polyline = polylines[0];
      const newPath = polyline.deleted ? [] : polyline.path;
      const oldPath = this.selectedPolyline.path;

      if (pathsEqual(newPath, oldPath)) {
        console.log('[CreatorPane] Paths equal, no change required');
        this.selectedPolyline = null;
        return;
      }

      const payload = {
        oldPath,
        newPath,
        zoom: this.zoom,
      };

      this.$emit('edit', payload);

      this.selectedPolyline = null;
    },
    onEditReject() {
      this.selectedPolyline = null;
    },
    onPolylineClick(polyline) {
      if (!this.selectedPolyline) {
        this.canEdit = true;
        this.selectedPolyline = polyline;
        return;
      }
    },
    onSegmentClick({ segment }) {
      this.$emit('toggle-segment', segment);
    },
    toggleShowLocations() {
      this.showLocations = !this.showLocations;
    },
  },
};
</script>

<style>
.creator-pane > .modes {
  margin-top: 1rem;
  width: 100%;
  display: flex;
}

.creator-pane > .modes > button {
  opacity: 0.75;
  width: 100%;
}

.creator-pane > .modes > button.selected {
  border-color: #b6c3cc;
  opacity: 1;
}

.creator-pane .map-wrapper {
  position: relative;
  height: 60vh;
  width: 100%;
}

.creator-pane .gmap-map {
  height: 100%;
  width: 100%;
}

.creator-pane .gmap-map .vue-map-container {
  height: 100%;
}
</style>