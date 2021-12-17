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
import { getNodeGroups, graphToSegments, segmentsToPolylines } from '../../common';
import { Graph } from '@/code/graph';

function createSegmentPolyline(polyline, selectedSegments) {
  if (selectedSegments[polyline.segment.id]) {
    polyline.color = 'darkgreen';
  } else {
    polyline.color = 'black';
  }

  return polyline;
}

function initialiseSelectedSegments(segments, edgeIds) {
  // for each segment, determine if the edge id is given
  return segments.reduce((acc, s) => {
    if (s.edges.some(e => edgeIds.includes(e.id))) {
      acc[s.id] = true;
    }

    return acc;
  }, {});
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
    // this is only needed to initialise the edges
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
      localGraph: new Graph(),
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
      setMapTypeOverlay(map, this.google, this.mapManifest);
    });

    this.localGraph = this.graph.copy();
    this.segments = graphToSegments(this.localGraph);
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
    onSegmentClick(poly) {
      if (this.selectedSegments[poly.segment.id]) {
        delete this.selectedSegments[poly.segment.id];
      } else {
        this.selectedSegments[poly.segment.id] = true;
      }

      this.selectedSegments = { ...this.selectedSegments };
    },
    onAccept() {
      const segmentLookup = toLookup(this.segments, 'id');

      const edgeIds = Object.keys(this.selectedSegments)
        .map(sId => segmentLookup[parseInt(sId, 10)].edges.map(e => e.id))
        .flat();

      this.close(edgeIds);
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