<template>
  <div class="route-map-page">
    <hxCard title="Route Map" :icon="lineIcon">
      <div class="map-selector">
        <button
          v-for="mode in ['routing', 'traversal', 'segment']"
          :key="mode"
          class="hx-btn"
          :class="{ selected: mapMode === mode }"
          @click="setMapMode(mode)"
        >
          {{ mode }}
        </button>
      </div>
      <RouteMap
        v-if="mapMode === 'routing'"
        :graph="graph"
        :snapDistancePx="snapDistancePx"
        @create="onRouteCreate"
        @delete="onRouteDelete"
      />
      <TraversalMap v-else-if="mapMode === 'traversal'" :graph="graph" />
      <SegmentMap v-else :graph="graph" />
    </hxCard>
  </div>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import LineIcon from '@/components/icons/Line.vue';
import RouteMap from './RouteMap.vue';
import TraversalMap from './TraversalMap.vue';
import SegmentMap from './SegmentMap.vue';
import { Graph } from './graph';
import { haversineDistanceM, pixelsToMeters } from '@/code/distance';
import { chunkEvery } from '@/code/helpers';
import { createTempGraph } from './graphData';

function addPolylineToGraph(graph, path, zoom, snapDistancePx) {
  const snapDistance = pixelsToMeters(snapDistancePx, zoom);
  const existingVertices = graph.getVerticesList();
  const usedVertices = path.map(point => {
    const existingV = existingVertices.find(v => haversineDistanceM(point, v.data) < snapDistance);
    return existingV || graph.addVertex({ lat: point.lat, lng: point.lng });
  });

  chunkEvery(usedVertices, 2, 1, 'discard').forEach(([v1, v2]) => {
    const distance = haversineDistanceM(v1.data, v2.data);
    graph.addEdge(v1.id, v2.id, { distance });
    graph.addEdge(v2.id, v1.id, { distance });
  });

  return graph.copy();
}

function removePolylineFromGraph(graph, vertices) {
  chunkEvery(vertices, 2, 1, 'discard').map(([v1, v2]) => {
    graph.removeEdge(v1, v2);
    graph.removeEdge(v2, v1);
  });
  graph.removeOrphanVertices();

  return graph.copy();
}

export default {
  name: 'RouteMapPage',
  components: {
    hxCard,
    RouteMap,
    TraversalMap,
    SegmentMap,
  },
  data: () => {
    return {
      lineIcon: LineIcon,
      graph: new Graph(),
      snapDistancePx: 10,
      // mapMode: 'routing',
      // mapMode: 'traversal',
      mapMode: 'segment',
    };
  },
  mounted() {
    this.graph = createTempGraph();
  },
  methods: {
    onRouteCreate({ path, zoom }) {
      this.graph = addPolylineToGraph(this.graph, path, zoom, this.snapDistancePx);
      // console.dir('----------');
      // console.dir(JSON.stringify(this.graph.vertices, null, 2));
      // console.dir(JSON.stringify(this.graph.adjacency, null, 2));
    },
    onRouteDelete(vertices) {
      this.graph = removePolylineFromGraph(this.graph, vertices);
    },
    setMapMode(mode) {
      this.mapMode = mode;
    },
  },
};
</script>

<style>
.route-map-page .route-map,
.route-map-page .traversal-map,
.route-map-page .segment-map {
  height: 50vh;
}

.route-map-page .map-selector {
  width: 100%;
  display: flex;
}

.route-map-page .map-selector button {
  width: 100%;
}

.route-map-page .map-selector .selected {
  border: 1px solid white;
}
</style>