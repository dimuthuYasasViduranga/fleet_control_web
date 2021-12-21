<template>
  <div class="restriction-map-modal">
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
          <button ref="selection-all-control" class="g-button" @click="onSelectAll()">
            Select All
          </button>
          <button ref="selection-clear-control" class="g-button" @click="onClearSelected()">
            Clear All
          </button>
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
            @rightclick="onSegmentRightClick(poly)"
            @dblclick="stopGEvent"
          />
        </GmapMap>
      </div>
    </div>
    <div class="actions">
      <button class="hx-btn" @click="onAccept()">Accept</button>
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

import { attachControl } from '@/components/gmap/gmapControls';
import { setMapTypeOverlay } from '@/components/gmap/gmapCustomTiles';
import { toLookup, uniq } from '@/code/helpers';
import { getNodeGroups, graphToSegments, nextDirection, segmentsToPolylines } from '../../common';

function createSegmentPolyline(polyline, selectedSegments) {
  const isSelected = selectedSegments[polyline.segment.id];
  const color = isSelected ? 'darkgreen' : 'black';
  polyline.color = color;

  if (!isSelected && polyline.icons) {
    polyline.icons.forEach(i => (i.icon.fillColor = 'black'));
  }

  return polyline;
}

function initialiseSelectedSegments(segments, edgeIds) {
  // for each segment, determine if the edge id is given
  return segments.reduce((acc, s) => {
    if (s.edges.some(e => edgeIds.includes(e.data.edgeId))) {
      acc[s.id] = true;
    }

    return acc;
  }, {});
}

function getSegmentEdgeIds(graph, segment) {
  switch (segment.direction) {
    case 'positive':
      return [graph.getEdge(segment.nodeAId, segment.nodeBId)?.data?.edgeId];
    case 'negative':
      return [graph.getEdge(segment.nodeBId, segment.nodeAId)?.data?.edgeId];
    default:
      return segment.edges.map(e => e.data.edgeId);
  }
}

function edgesToSegments(graph, edgeIds) {
  const edgeLookup = edgeIds.reduce((acc, id) => {
    acc[id] = true;
    return acc;
  }, {});
  return graphToSegments(graph).map(s => {
    if (s.edges.length === 2) {
      s.direction = 'both';
    } else {
      // TODO: something is not producing the edge correctly

      const aId = s.edges.find(e => e.endVertexId === s.nodeBId)?.data.edgeId;
      const bId = s.edges.find(e => e.endVertexId === s.nodeAId)?.data.edgeId;

      const e1 = edgeLookup[aId];
      const e2 = edgeLookup[bId];

      if (e1 && !e2) {
        s.direction = 'positive';
      } else if (!e1 && e2) {
        s.direction = 'negative';
      }
    }

    return s;
  });
}

export default {
  name: 'RestrictionMapModal',
  components: {
    GMapGeofences,
    PolygonIcon,
    RecenterIcon,
    ResetZoomIcon,
  },
  props: {
    graph: { type: Object, required: true },
    edgeIds: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      mapType: 'satellite',
      center: {
        lat: 0,
        lng: 0,
      },
      zoom: 0,
      showLocations: true,
      segments: [],
      selectedSegments: {},
    };
  },
  computed: {
    google: gmapApi,
    ...mapState('constants', {
      mapManifest: state => state.mapManifest,
      defaultCenter: ({ mapCenter }) => ({ lat: mapCenter.latitude, lng: mapCenter.longitude }),
      defaultZoom: state => state.mapZoom,
    }),
    nodeToSCCGroup() {
      const group = getNodeGroups(this.graph, this.segments);
      if (uniq(Object.values(group)).length < 2) {
        return;
      }

      return group;
    },
    polylineSegments() {
      return segmentsToPolylines(this.segments, this.nodeToSCCGroup).map(s =>
        createSegmentPolyline(s, this.selectedSegments),
      );
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
      attachControl(map, this.google, this.$refs['selection-all-control'], 'TOP_LEFT');
      attachControl(map, this.google, this.$refs['selection-clear-control'], 'TOP_LEFT');
      setMapTypeOverlay(map, this.google, this.mapManifest);
    });

    this.segments = edgesToSegments(this.graph, this.edgeIds);
    this.selectedSegments = initialiseSelectedSegments(this.segments, this.edgeIds);
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
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
    refreshSelectedSegments() {
      this.selectedSegments = { ...this.selectedSegments };
    },
    onSegmentClick(poly) {
      const alreadySelected = this.selectedSegments[poly.segment.id];

      // toggle on
      if (!alreadySelected) {
        this.selectedSegments[poly.segment.id] = true;
      } else if (poly.segment.edges.length !== 1) {
        poly.segment.direction = nextDirection(poly.segment.direction);
      }

      this.refreshSelectedSegments();
    },
    onSegmentRightClick(poly) {
      if (poly.segment.edges.length === 2) {
        poly.segment.direction = 'both';
      }
      delete this.selectedSegments[poly.segment.id];
      this.refreshSelectedSegments();
    },
    onAccept() {
      const segmentLookup = toLookup(this.segments, e => e.id);

      const edgeIds = Object.keys(this.selectedSegments)
        .map(sId => segmentLookup[parseInt(sId, 10)])
        .map(seg => getSegmentEdgeIds(this.graph, seg))
        .flat()
        .filter(id => id);

      this.close(edgeIds);
    },
    onSelectAll() {
      this.selectedSegments = this.segments.reduce((acc, s) => {
        acc[s.id] = true;
        return acc;
      }, {});
    },
    onClearSelected() {
      this.segments.filter(s => s.edges.length === 2).forEach(s => (s.direction = 'both'));
      this.selectedSegments = {};
    },
  },
};
</script>

<style>
/* map */
.restriction-map-modal .map-wrapper {
  position: relative;
  height: 60vh;
  width: 100%;
}

.restriction-map-modal .gmap-map {
  height: 100%;
  width: 100%;
}

.restriction-map-modal .gmap-map .vue-map-container {
  height: 100%;
}
</style>