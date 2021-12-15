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

            <GMapCustomPolyline
              v-for="(poly, index) in polylineSegments"
              :key="`segment-${index}`"
              :path="poly.path"
              :options="{
                strokeColor: poly.color,
                strokeWeight: 10,
                icons: poly.icons,
                zIndex: 9,
              }"
              :labelPosition="0.5"
              @click="onSegmentClick(poly)"
              @dblclick="stopGEvent"
            >
              <div style="background-color: white; color: black; text-align: center; width: 120px">
                <div>Seg: {{ poly.segment.id }}</div>
                <div>Edges: {{ poly.segment.edges.map(e => e.id) }}</div>
                <div>Db Edges: {{ poly.segment.edges.map(e => e.data.edgeId) }}</div>
              </div>
            </GMapCustomPolyline>

            <GMapLabel
              v-for="(circle, index) in circles"
              :key="`circle-label-${index}`"
              :position="circle.center"
              :zIndex="500"
            >
              <div style="width: 100px; background-color: gray; color: black; text-align: center;">
                <div>Vertex: {{ circle.id }}</div>
                <div>Db Node: {{ circle.nodeId }}</div>
              </div>
            </GMapLabel>

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
            <GMapCustomPolyline
              v-for="(poly, index) in polylineSegments"
              :key="`segment-${index}`"
              :path="poly.path"
              :options="{
                strokeColor: poly.color,
                strokeWeight: 10,
                icons: poly.icons,
                zIndex: 10,
              }"
              :labelPosition="0.5"
              @click="onSegmentClick(poly)"
              @dblclick="stopGEvent"
            >
              <div style="background-color: white; color: black; text-align: center; width: 50px">
                <span
                  >{{ poly.segment.id }} | {{ poly.segment.nodeAId }} --
                  {{ poly.segment.nodeBId }}</span
                >
              </div>
            </GMapCustomPolyline>

            <gmap-circle
              v-for="(circle, index) in circles"
              :key="`segment-circle-${index}`"
              :center="circle.center"
              :radius="0"
              :options="{
                clickable: false,
                zIndex: 20,
                strokeOpacity: 0.5,
                strokeWeight: 10,
              }"
            />
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
import PolygonIcon from '@/components/gmap/PolygonIcon.vue';
import GMapCustomPolyline from '@/components/gmap/GMapCustomPolyline.vue';
import GMapLabel from '@/components/gmap/GMapLabel.vue';

import { Dictionary, hasOrderedSubArray } from '@/code/helpers.js';
import { getUniqPaths } from '../graph';
import { pixelsToMeters } from '@/code/distance';
import { attachControl } from '@/components/gmap/gmapControls';

const ROUTE_COLOR = 'darkred';
const ROUTE_EDIT_COLOR = 'purple';
const ROUTE_WIDTH = 10;
const MODES = ['drawing', 'directions'];
const DIRECTIONS = ['both', 'positive', 'negative'];

const POLYLINE_SYMBOLS = {
  diamond: {
    path: 'M 0,1 1,0 -1,0 z',
    strokeColor: '#F00',
    fillColor: '#F00',
    fillOpacity: 1,
    scale: 1,
  },
  arrow: {
    path: 'M -2,0 0,-4 2,0',
    strokeColor: 'black',
    fillColor: null,
    fillOpacity: 1,
    scale: 1,
  },
};

function graphToPolylines(graph) {
  const adjacency = graph.adjacency;
  const vertices = graph.vertices;

  const uniqPaths = getUniqPaths(adjacency);

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

function graphToSegments(graph, existingSegments = []) {
  const existingDirections = new Dictionary();
  existingSegments.forEach(seg => {
    existingDirections.add([seg.nodeAId, seg.nodeBId], seg.direction);
  });

  // need to handle existing segments so that data is not lost
  const vertices = graph.vertices;

  // group edges into segment (a segment contains both directions if avialable)
  const dict = new Dictionary();
  Object.values(graph.adjacency).forEach(edges => {
    edges.forEach(edge => {
      const orderedIndex = [edge.startVertexId, edge.endVertexId].sort();
      dict.append(orderedIndex, edge);
    });
  });

  const segments = dict.map(([nodeAId, nodeBId], edges, index) => {
    const nodeStartPosition = vertices[nodeAId].data;
    const nodeEndPosition = vertices[nodeBId].data;
    const path = [nodeStartPosition, nodeEndPosition];

    const direction = existingDirections.get([nodeAId, nodeBId]) || 'both';

    return {
      id: index,
      edges: edges,
      direction,
      nodeAId,
      nodeBId,
      path,
    };
  });

  return segments;
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

function nextDirection(dir) {
  const index = DIRECTIONS.indexOf(dir);
  return DIRECTIONS[index + 1] || DIRECTIONS[0];
}

function getSymbol(name, opts) {
  return { ...POLYLINE_SYMBOLS[name], ...(opts || {}) };
}

function getSegmentOpts(seg) {
  const icons = getSegmentIcons(seg.direction);
  const color = seg.direction === 'both' ? 'darkgreen' : 'green';

  return {
    color,
    icons,
  };
}

function getSegmentIcons(direction) {
  const arrowOpts = {
    strokeOpacity: 1,
    fillOpacity: 1,
    scale: 2,
  };
  switch (direction) {
    case 'positive':
      return [
        {
          icon: getSymbol('arrow', arrowOpts),
          offset: '50%',
        },
      ];
    case 'negative':
      return [
        {
          icon: getSymbol('arrow', { ...arrowOpts, rotation: 180 }),
          offset: '50%',
        },
      ];
    default:
      return [];
  }
}

export default {
  name: 'CreatorPane',
  components: {
    GMapDrawingControls,
    GMapEditable,
    GMapGeofences,
    PolygonIcon,
    GMapCustomPolyline,
    GMapLabel,
  },
  props: {
    graph: { type: Object },
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
      shapes: {
        polylines: [],
        segments: [],
      },
      selectedPolyline: null,
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
    polylineSegments() {
      return this.shapes.segments.map(s => {
        const opts = getSegmentOpts(s);

        return {
          segment: s,
          path: s.path,
          ...opts,
        };
      });
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
        this.refreshGraphSegments();
      },
    },
  },
  mounted() {
    this.reCenter();
    this.resetZoom();

    this.gPromise().then(map => {
      // set greedy mode so that scroll is enabled anywhere on the page
      map.setOptions({ gestureHandling: 'greedy' });
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
      this.shapes.polylines = graphToPolylines(this.graph);
      this.selectedPolyline = null;
    },
    refreshGraphSegments() {
      this.shapes.segments = graphToSegments(this.graph, this.shapes.segments);
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

      const payload = {
        oldPath: this.selectedPolyline.path.slice(),
        newPath: polyline.path,
        oldVertices: this.selectedPolyline.vertices.slice(),
        zoom: this.zoom,
      };

      this.$emit('edit', payload);

      // this.$emit('delete', this.selectedPolyline.vertices.slice());

      // if (!polyline.deleted) {
      //   this.$emit('create', { path: polyline.path, zoom: this.zoom });
      // }

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
    onSegmentClick(poly) {
      poly.segment.direction = nextDirection(poly.segment.direction);
    },
    toggleShowLocations() {
      this.showLocations = !this.showLocations;
    },
  },
};
</script>

<style>
.creator-pane {
  height: 60vh;
}

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
  height: 100%;
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