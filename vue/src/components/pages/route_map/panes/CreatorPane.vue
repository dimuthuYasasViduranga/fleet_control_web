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
                strokeWeight: 10,
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
                strokeWeight: 10,
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

import { copy, Dictionary, uniq } from '@/code/helpers.js';
import { getUniqPaths } from '@/code/graph';
import { pixelsToMeters } from '@/code/distance';
import { attachControl } from '@/components/gmap/gmapControls';
import { stronglyConnectedComponents } from '@/code/graph_traversal';

const ROUTE_COLOR = 'darkred';
const ROUTE_EDIT_COLOR = 'purple';
const ROUTE_WIDTH = 10;
const MODES = ['drawing', 'directions'];
const DIRECTIONS = ['both', 'positive', 'negative'];
const SCC_COLORS = ['#007300', '#005a00', '#004000', '#339933', '#66b366', '#99cc99', '#cce6cc'];

const POLYLINE_SYMBOLS = {
  diamond: {
    path: 'M 0,1 1,0 -1,0 z',
    strokeColor: '#F00',
    fillColor: '#F00',
    fillOpacity: 1,
    scale: 1,
  },
  arrow: {
    path: 'M -2,0 0,-4 2,0 z',
    strokeColor: 'black',
    fillColor: null,
    fillOpacity: 1,
    scale: 1,
    // anchor units are based off path space
    anchor: { x: 0, y: -1.5 },
  },
};

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

function getSegmentOpts(seg, groupLookup) {
  const icons = getSegmentIcons(seg.direction);
  const color = getSegmentColor(seg, groupLookup);

  return {
    color,
    icons,
  };
}

function getSegmentIcons(direction) {
  const arrowOpts = {
    strokeOpacity: 1,
    strokeColor: 'black',
    strokeWeight: 2,
    fillOpacity: 1,
    fillColor: 'green',
    scale: 4,
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

function getSegmentColor(seg, groupLookup) {
  if (!groupLookup) {
    return 'darkgreen';
  }

  if (groupLookup[seg.nodeAId] !== groupLookup[seg.nodeBId]) {
    return '#444444';
  }

  return SCC_COLORS[groupLookup[seg.nodeAId] % SCC_COLORS.length];
}

function getNodeGroups(graph, segments) {
  const adjacency = copy(graph.adjacency);

  // for each segment that isnt both, remove the other direction
  const directionalSegments = segments
    .filter(s => s.direction !== 'both')
    .map(s => {
      const [a, b] = s.direction === 'positive' ? [s.nodeAId, s.nodeBId] : [s.nodeBId, s.nodeAId];
      return {
        startId: a,
        endId: b,
      };
    });

  directionalSegments.forEach(s => {
    adjacency[s.endId] = adjacency[s.endId].filter(e => e.endVertexId !== s.startId);
  });

  const sccVertices = stronglyConnectedComponents(graph.vertices, adjacency);

  const normaliseGroups = uniq(sccVertices.map(v => v.group)).reduce((acc, group, index) => {
    acc[group] = index;
    return acc;
  }, {});

  return sccVertices.reduce((acc, v) => {
    acc[graph.vertices[v.id].id] = normaliseGroups[v.group];
    return acc;
  }, {});
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
      // selectedMode: MODES[0],
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
      const groupLookup = this.nodeToSCCGroup;
      return this.shapes.segments.map(s => {
        const opts = getSegmentOpts(s, groupLookup);

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
    nodeToSCCGroup() {
      const group = getNodeGroups(this.graph, this.shapes.segments);
      if (uniq(Object.values(group)).length < 2) {
        return;
      }

      return group;
    },
    sccSegments() {
      const nodeToGroup = getNodeGroups(this.graph, this.shapes.segments);

      if (uniq(Object.values(nodeToGroup)).length < 2) {
        return [];
      }

      return this.shapes.segments
        .map(s => {
          // start and end ids must have same group
          if (nodeToGroup[s.nodeAId] !== nodeToGroup[s.nodeBId]) {
            return null;
          }

          const color = SCC_COLORS[nodeToGroup[s.nodeAId] % SCC_COLORS.length];
          return {
            path: s.path,
            color: color,
          };
        })
        .filter(s => s);
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
      const newPath = shapes.polylines[0].path;
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