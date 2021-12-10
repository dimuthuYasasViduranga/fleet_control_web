<template>
  <div class="route-map">
    <button class="hx-btn" @click="onLogStructure()">Log</button>
    <div class="map-wrapper">
      <div class="gmap-map">
        <div style="display: none">
          <PolygonIcon
            class="geofence-control"
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
          <GMapDrawingControls :show="!canEdit" :modes="['polyline']" @create="onShapeCreate" />
          <GMapEditable
            ref="gmap-editable"
            :edit.sync="canEdit"
            :clickToEdit="false"
            direction="vertical"
            :polylines="editablePolylines"
            :removeDeleted="false"
            @accept="onEditAccept"
            @reject="onEditReject"
          />

          <g-map-geofences
            v-if="showLocations"
            :geofences="locations"
            :options="{ fillOpacity: 0.2, strokeOpacity: 0.2 }"
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
            :key="`circle-${index}`"
            :center="circle.center"
            :radius="snapDistance"
            :options="{
              clickable: false,
              zIndex: 5,
              strokeOpacity: 0.5,
            }"
          />
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
import PolygonIcon from '@/components/gmap/PolygonIcon.vue';
import { hasOrderedSubArray } from '@/code/helpers.js';
import { getUniqPaths } from './graph';
import { pixelsToMeters } from '@/code/distance';
import { attachControl } from '@/components/gmap/gmapControls';

const ROUTE_COLOR = 'darkred';
const ROUTE_EDIT_COLOR = 'purple';
const ROUTE_WIDTH = 10;

function graphToPolylines(graph) {
  const adjacency = graph.adjacency;
  const vertices = graph.vertices;

  const uniqPaths = getUniqPaths(adjacency, vertices);

  return uniqPaths.map(path => {
    const points = path.map(id => {
      const data = vertices[id].data;
      return {
        lat: data.lat,
        lng: data.lng,
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
  name: 'RouteMap',
  components: {
    GMapDrawingControls,
    GMapEditable,
    GMapGeofences,
    PolygonIcon,
  },
  props: {
    graph: { type: Object, required: true },
    locations: { type: Array, default: () => [] },
    snapDistancePx: { type: Number, default: 0 },
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
      shapes: {
        polylines: [],
      },
      selectedPolyline: null,
      showLocations: true,
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
      return this.shapes.polylines.filter(p => p !== this.selectedPolyline);
    },
    editablePolylines() {
      if (this.selectedPolyline) {
        const poly = { ...this.selectedPolyline, color: ROUTE_EDIT_COLOR };
        return [poly];
      }
      return [];
    },
    snapDistance() {
      return pixelsToMeters(this.snapDistancePx, this.zoom);
    },
    circles() {
      return this.graph.getVerticesList().map(v => {
        const center = { lat: v.data.lat, lng: v.data.lng };
        return { center };
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
      attachControl(map, this.google, '.geofence-control', 'LEFT_TOP');
      setMapTypeOverlay(map, this.google, this.mapManifest);
    });
  },
  methods: {
    gPromise() {
      return this.$refs.gmap.$mapPromise;
    },
    refreshGraphPolylines() {
      this.shapes.polylines = graphToPolylines(this.graph);
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
    onShapeCreate({ type, props }) {
      if (type === 'polyline') {
        this.$emit('create', { path: props.path, zoom: this.zoom });
      }
    },
    onEditAccept(shapes) {
      const polyline = shapes.polylines[0];
      if (!polyline || !this.selectedPolyline) {
        this.selectedPolyline = null;
        return;
      }

      // if no change, dont emit
      if (!polyline.deleted && pathsEqual(this.selectedPolyline.path, polyline.path)) {
        this.selectedPolyline = null;
        return;
      }

      this.$emit('delete', this.selectedPolyline.vertices.slice());

      if (!polyline.deleted) {
        this.$emit('create', { path: polyline.path, zoom: this.zoom });
      }

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

      if (polyline !== this.selectedPolyline) {
        this.$refs['gmap-editable'].onAction('accept');
        this.selectedPolyline = null;
        setTimeout(() => {
          const newPolyline = this.shapes.polylines.find(({ vertices }) => {
            const doubledVerts = vertices.slice(0, vertices.length - 1).concat(vertices);
            return (
              hasOrderedSubArray(doubledVerts, polyline.vertices) ||
              hasOrderedSubArray(doubledVerts, polyline.vertices.slice().reverse())
            );
          });
          this.onPolylineClick(newPolyline);
        }, 100);
      }
    },
    onLogStructure() {
      console.dir('---- structure');
      console.dir(this.graph);
    },
    toggleShowLocations() {
      this.showLocations = !this.showLocations;
    },
  },
};
</script>

<style>
.route-map .map-wrapper {
  position: relative;
  height: 100%;
  width: 100%;
}

.route-map .gmap-map {
  height: 100%;
  width: 100%;
}
</style>