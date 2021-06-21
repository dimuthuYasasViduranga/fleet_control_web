<template>
  <div class="segment-map">
    <div class="map-wrapper">
      <div class="gmap-map">
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
          <!-- all graph lines -->
          <gmap-polyline
            v-for="(segment, index) in segments"
            :key="`segment-${index}`"
            :path="[segment.posStart, segment.posEnd]"
            :options="{
              strokeColor: selectedSegment === segment ? 'orange' : 'green',
              strokeWeight: 10,
              strokeOpacity: 1,
              icons: polylineIcons,
              geodesic: true,
            }"
            @click="onSegmentClick(segment)"
          />

          <!-- draw vertices -->
          <gmap-circle
            v-for="(vertex, index) in vertices"
            :key="`vertex-${index}`"
            :center="vertex.center"
            :radius="1"
            :options="{
              clickable: false,
              zIndex: 2,
              strokeOpacity: 0.5,
              strokeWeight: 5,
            }"
          />

          <!-- when selected, split lines in two (directional) -->

          <!-- this gives access to two separate lines for setting efficiency/direction -->
        </GmapMap>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { gmapApi } from 'gmap-vue';
import { setMapTypeOverlay } from '@/components/gmap/gmapCustomTiles';

function graphToSegments(graph, google) {
  const adjacency = graph.adjacency;
  const vertexMap = graph.vertices;

  const edgePairs = {};
  // group where vertex start and end are the same (order does not matter)
  Object.values(adjacency).forEach(edges => {
    edges.forEach(edge => {
      const id1 = `${edge.startVertexId}|${edge.endVertexId}`;
      const id2 = `${edge.endVertexId}|${edge.startVertexId}`;

      const pair1 = edgePairs[id1];

      if (pair1) {
        pair1.push(edge);
        return;
      }

      const pair2 = edgePairs[id2];
      if (pair2) {
        pair2.push(edge);
        return;
      }

      edgePairs[id1] = [edge];
    });
  });

  return Object.values(edgePairs).map(([edge1, edge2]) => {
    const posStart = vertexMap[edge1.startVertexId].data;
    const posEnd = vertexMap[edge1.endVertexId].data;
    return {
      edge1,
      edge2,
      posStart,
      posEnd,
      // icons: [
      //   {
      //     icon: {
      //       path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
      //       strokeColor: 'darkgreen',
      //       strokeWeight: 2,
      //       fillColor: 'green',
      //       fillOpacity: 1,
      //       scale: 4,
      //     },
      //   },
      //   {
      //     icon: {
      //       path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
      //       strokeColor: 'darkgreen',
      //       strokeWeight: 2,
      //       fillColor: 'green',
      //       fillOpacity: 1,
      //       scale: 4,
      //     },
      //   },
      // ],
      data: {},
    };
  });
}

export default {
  name: 'SegmentMap',
  props: {
    graph: { type: Object, required: true },
  },
  data: () => {
    return {
      mapType: 'satellite',
      center: {
        lat: 0,
        lng: 0,
      },
      zoom: 0,
      segments: [],
      selectedSegment: null,
    };
  },
  computed: {
    google: gmapApi,
    ...mapState('constants', {
      mapManifest: state => state.mapManifest,
      defaultCenter: ({ mapCenter }) => ({ lat: mapCenter.latitude, lng: mapCenter.longitude }),
      defaultZoom: state => state.mapZoom,
    }),
    vertices() {
      return this.graph.getVerticesList().map(v => {
        const center = { lat: v.data.lat, lng: v.data.lng };
        return { center };
      });
    },
    polylineIcons() {
      const scale = this.zoom > 16 ? 5 : 0;
      const baseIcon = {
        strokeColor: 'darkgreen',
        strokeWeight: 2,
        fillColor: 'green',
        fillOpacity: 1,
        scale,
      };
      return [
        {
          icon: {
            path: google.maps.SymbolPath.BACKWARD_CLOSED_ARROW,
            ...baseIcon,
          },
          offset: '0%',
        },
        {
          icon: {
            path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
            ...baseIcon,
          },
          offset: '100%',
        },
      ];
    },
  },
  watch: {
    graph: {
      immediate: true,
      handler() {
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
      setMapTypeOverlay(map, this.google, this.mapManifest);
      this.refreshGraphSegments();
    });
  },
  methods: {
    gPromise() {
      return this.$refs.gmap.$mapPromise;
    },
    refreshGraphSegments() {
      if (this.google) {
        this.segments = graphToSegments(this.graph, this.google);
      }
    },
    reCenter() {
      this.moveTo(this.defaultCenter);
    },
    moveTo(latLng) {
      this.gPromise().then(map => map.panTo(latLng));
    },
    zoomChanged(level) {
      this.zoom = level;
    },
    resetZoom() {
      this.zoom = this.defaultZoom;
    },
    onSegmentClick(segment) {
      if (this.selectedSegment === segment) {
        this.selectedSegment = null;
      } else {
        this.selectedSegment = segment;
      }
    },
  },
};
</script>

<style>
.segment-map .map-wrapper {
  position: relative;
  height: 100%;
  width: 100%;
}

.segment-map .gmap-map {
  height: 100%;
  width: 100%;
}
</style>