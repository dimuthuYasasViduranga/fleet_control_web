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
import { chunkEvery } from '@/code/helpers';
import { haversineDistanceM, pixelsToMeters } from '@/code/distance';

const STAGES = ['create', 'restrict', 'review'];

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