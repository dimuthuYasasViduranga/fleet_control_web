<template>
  <div class="route-editor-modal">
    <div ref="fullscreenable" class="container" :class="{ fullscreen: isFullscreen }">
      <div
        class="fullscreen-button"
        v-tooltip="{ content: isFullscreen ? 'Minimise' : 'Fullscreen', placement: 'left' }"
      >
        <Icon :icon="isFullscreen ? minimiseIcon : fullscreenIcon" @click="onToggleFullscreen()" />
      </div>
      <div class="stages">
        <button
          class="hx-btn"
          v-for="(stage, index) in stages"
          :key="index"
          :class="{ selected: stage === selectedStage }"
          @click="setStage(stage)"
        >
          {{ stage }}
        </button>
      </div>
      <div class="pane">
        <CreatorPane
          v-if="selectedStage === 'create'"
          :graph="graph"
          :locations="locations"
          :snapDistancePx="snapDistancePx"
          @create="onAddPolyline"
          @edit="onEditPolyline"
          @delete="onRemovePolyline"
        />
        <RestrictionPane v-else-if="selectedStage === 'restrict'" />
        <ReviewPane v-else-if="selectedStage === 'review'" />
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';

import CreatorPane from './panes/CreatorPane.vue';
import RestrictionPane from './panes/RestrictionPane.vue';
import ReviewPane from './panes/ReviewPane.vue';

import FullscreenIcon from '@/components/icons/Fullscreen.vue';
import MinimiseIcon from '@/components/icons/Minimise.vue';

import { exitFullscreen, isElementFullscreen, requestFullscreen } from '@/code/fullscreen';
import { fromRoute, Graph } from './graph';
import { chunkEvery, Dictionary, IdGen, toLookup } from '@/code/helpers';
import { haversineDistanceM, pixelsToMeters } from '@/code/distance';

const STAGES = ['create', 'restrict', 'review'];
const NodeDbIds = new IdGen(-1, -1);
const EdgeDbIds = new IdGen(-1, -1);

function addPolylineToGraph(graph, path, zoom, snapDistancePx) {
  const snapDistance = pixelsToMeters(snapDistancePx, zoom);
  const existingVertices = graph.getVerticesList();

  const usedVertices = path.map(point =>
    addOrGetVertex(graph, existingVertices, point, snapDistance),
  );

  chunkEvery(usedVertices, 2, 1, 'discard').forEach(([v1, v2]) => {
    addOrGetEdge(graph, v1, v2);
    addOrGetEdge(graph, v2, v1);
  });

  return graph.copy();
}

function editGraph(graph, path, oldVertices, zoom, snapDistancePx) {
  const snapDistance = pixelsToMeters(snapDistancePx, zoom);

  const existingVertices = graph.getVerticesList();

  // for each path, try to associate with an existing vertex
  const usedVertices = path.map(point =>
    addOrGetVertex(graph, existingVertices, point, snapDistance),
  );

  // remove unused edges
  const newSegmentDict = new Dictionary();
  chunkEvery(usedVertices, 2, 1, 'discard').forEach(([a, b]) => {
    const key = [a.id, b.id].sort();
    newSegmentDict.add(key, true);
  });
  chunkEvery(oldVertices, 2, 1, 'discard').forEach(([aId, bId]) => {
    const key = [aId, bId].sort();
    if (!newSegmentDict.get(key)) {
      graph.removeEdge(aId, bId);
      graph.removeEdge(bId, aId);
    }
  });

  // remove the unused vertices
  const usedVertexLookup = toLookup(usedVertices, 'id');
  oldVertices.forEach(id => {
    if (!usedVertexLookup[id]) {
      graph.removeVertex(id);
    }
  });

  // const oldVertexDict = new Dictionary();

  // chunkEvery(oldVertices, 2, 1, 'discard').forEach(([aId, bId]) => {
  //   const key = [aId, bId].sort();
  //   oldVertexDict.add(key, true);
  // });

  // console.dir(JSON.stringify(oldVertices));
  // console.dir(JSON.stringify(usedVertices.map(e => e.id)));

  // add the new edges
  chunkEvery(usedVertices, 2, 1, 'discard').forEach(([v1, v2]) => {
    addOrGetEdge(graph, v1, v2);
    addOrGetEdge(graph, v2, v1);
  });

  // then need to remove edges not used (i guess compare usedVertices id with oldVertices)
  // and remove the missing ones

  return graph.copy();
}

function addOrGetVertex(graph, vertices, point, snapDistance) {
  const existingV = vertices.find(v => haversineDistanceM(point, v.data) < snapDistance);
  return existingV || graph.addVertex({ lat: point.lat, lng: point.lng, nodeId: NodeDbIds.next() });
}

function addOrGetEdge(graph, v1, v2) {
  const edge = graph.getEdge(v1.id, v2.id);
  if (edge) {
    return edge;
  }

  return graph.addEdge(v1.id, v2.id, { ...v1.data, edgeId: EdgeDbIds.next() });
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
  name: 'RouteEditorModal',
  components: {
    Icon,
    CreatorPane,
    RestrictionPane,
    ReviewPane,
  },
  data: () => {
    return {
      isFullscreen: false,
      stages: STAGES,
      graph: new Graph(),
      snapDistancePx: 10,
      selectedStage: STAGES[0],
      fullscreenIcon: FullscreenIcon,
      minimiseIcon: MinimiseIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      locations: state => state.locations,
      nodes: state => state.routeNodes,
      edges: state => state.routeEdges,
      routes: state => state.routes,
    }),
  },
  mounted() {
    document.addEventListener('fullscreenchange', this.onFullscreenChange, false);
    this.reloadGraph();
  },
  beforeDestroy() {
    document.removeEventListener('fullscreenchange', this.onFullscreenChange, false);
  },
  methods: {
    outerClickIntercept(payload) {
      // this can be used to prompt that you will lose some data
      console.log('---- click');
    },
    onFullscreenChange() {
      this.isFullscreen = isElementFullscreen();
    },
    setStage(stage) {
      this.selectedStage = stage;
    },
    onToggleFullscreen() {
      const area = this.$refs['fullscreenable'];

      if (!area) {
        console.error('[GeofenceEditorModal] No area found. Cannot enter fullscreen');
      }

      this.isFullscreen ? exitFullscreen(area) : requestFullscreen(area);
    },
    reloadGraph() {
      const unrestrictedRoute = this.routes.find(r => !r.restrictionGroupId);
      this.graph = fromRoute(this.nodes, this.edges, unrestrictedRoute);
    },
    onEditPolyline({ newPath, oldVertices, zoom }) {
      this.graph = editGraph(this.graph, newPath, oldVertices, zoom, this.snapDistancePx);
      // pair new path points with something from the exists nodes, ie to get
      // this.graph = addPolylineToGraph(this.graph, path, zoom, this.snapDistancePx);
    },
    onAddPolyline({ path, zoom }) {
      this.graph = addPolylineToGraph(this.graph, path, zoom, this.snapDistancePx);
    },
    onRemovePolyline(vertices) {
      this.graph = removePolylineFromGraph(this.graph, vertices);
    },
  },
};
</script>

<style>
.route-editor-modal .modal-container-wrapper > .modal-container {
  height: auto;
}

.route-editor-modal .modal-container-wrapper {
  height: 100%;
  width: 100%;
  padding: 4rem 6rem;
  overflow-y: auto;
}

/* fullscreen container wrapper */

.route-editor-modal > .container {
  display: flex;
  flex-direction: column;
  height: 100%;
  width: 100%;
}

.route-editor-modal > .container.fullscreen {
  background-color: #23343f;
  padding: 2rem;
  overflow-y: auto;
}

/* stage/pane buttons */
.route-editor-modal .stages {
  display: flex;
}

.route-editor-modal .stages > button {
  width: 100%;
  margin: 0 0.1rem;
  text-transform: capitalize;
  opacity: 0.9;
}

.route-editor-modal .stages > button.selected {
  border-color: #b6c3cc;
  opacity: 1;
}

/* fullscreen button */
.route-editor-modal .fullscreen-button {
  cursor: pointer;
  height: 2rem;
  width: 2rem;
  float: right;
  align-self: flex-end;
  margin-right: -1.5rem;
  margin-top: -1.5rem;
  margin-bottom: 0.25rem;
}

.route-editor-modal .fullscreen-button:hover {
  opacity: 0.5;
}
</style>