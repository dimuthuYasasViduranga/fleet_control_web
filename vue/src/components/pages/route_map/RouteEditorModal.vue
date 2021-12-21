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
          :segments="segments"
          :locations="locations"
          :snapDistancePx="snapDistancePx"
          @create="onAddPolyline"
          @edit="onEditPolyline"
          @toggle-segment="onToggleSegment"
        />
        <RestrictionPane
          v-else-if="selectedStage === 'restrict'"
          :graph="graph"
          :segments="segments"
          :locations="locations"
          :restrictionGroups="restrictionGroups"
          :assetTypes="assetTypes"
          @add="onAddRestrictionGroup"
          @move="onRestrictionAssetTypeMove"
          @edit="onEditRestrictionGroup"
          @remove="onRemoveRestrictionGroup"
        />
        <ReviewPane v-else-if="selectedStage === 'review'" />
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';

import CreatorPane from './panes/CreatorPane.vue';
import RestrictionPane from './panes/restriction/RestrictionPane.vue';
import ReviewPane from './panes/ReviewPane.vue';

import FullscreenIcon from '@/components/icons/Fullscreen.vue';
import MinimiseIcon from '@/components/icons/Minimise.vue';

import { exitFullscreen, isElementFullscreen, requestFullscreen } from '@/code/fullscreen';
import { fromRoute, Graph } from '@/code/graph';
import { addPolylineToGraph, editGraph } from './route.js';
import { IdGen, toLookup } from '@/code/helpers';
import { graphToSegments, nextDirection } from './common';

const STAGES = ['create', 'restrict', 'review'];
const SNAP_DISTANCE_PX = 10;
const RestrictionIDGen = new IdGen(-1, -1);

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
      segments: [],
      restrictionGroups: [],
      snapDistancePx: SNAP_DISTANCE_PX,
      selectedStage: STAGES[0],
      fullscreenIcon: FullscreenIcon,
      minimiseIcon: MinimiseIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      assetTypes: state => state.assetTypes,
      locations: state => state.locations,
      nodes: state => state.routeNodes,
      edges: state => state.routeEdges,
      routes: state => state.routes,
      routeRestrictionGroups: state => {
        const lookup = toLookup(
          state.assetTypes,
          e => e.id,
          e => e.type,
        );
        return state.routeRestrictionGroups.map(r => {
          const assetTypes = r.assetTypeIds.map(id => lookup[id]);
          return {
            id: r.id,
            name: r.name,
            assetTypes,
            edgeIds: [],
          };
        });
      },
    }),
  },
  watch: {
    graph: {
      immediate: true,
      handler() {
        this.reloadGraphSegments();
        this.cullRestrictionGroups();
      },
    },
    routeRestrictionGroups: {
      immediate: true,
      handler() {
        this.reloadRestrictionGroups();
      },
    },
  },
  mounted() {
    document.addEventListener('fullscreenchange', this.onFullscreenChange, false);
    this.reloadGraph();
    this.reloadGraphSegments();
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
    reloadGraphSegments() {
      this.segments = graphToSegments(this.graph, this.segments);
    },
    reloadRestrictionGroups() {
      const groups = this.routeRestrictionGroups.slice();
      if (groups.length === 0) {
        groups = [
          {
            id: RestrictionIDGen.next(),
            name: 'Default',
            assetTypes: this.assetTypes.map(at => at.type),
            edgeIds: [],
          },
        ];
      }
      this.restrictionGroups = groups;
    },
    cullRestrictionGroups() {
      const availableEdges = Object.values(this.graph.adjacency).flat();
      const edgeLookup = toLookup(
        availableEdges,
        e => e.data.edgeId,
        () => true,
      );
      this.restrictionGroups.forEach(r => {
        r.edgeIds = r.edgeIds.filter(id => edgeLookup[id]);
      });
      this.restrictionGroups = this.restrictionGroups.slice();
    },
    onEditPolyline({ newPath, oldPath, zoom }) {
      this.graph = editGraph(this.graph, newPath, oldPath, zoom, this.snapDistancePx);
    },
    onAddPolyline({ path, zoom }) {
      this.graph = addPolylineToGraph(this.graph, path, zoom, this.snapDistancePx);
    },
    onToggleSegment(segment) {
      segment.direction = nextDirection(segment.direction);
    },
    onAddRestrictionGroup() {
      const groups = this.restrictionGroups.slice();
      groups.push({
        id: RestrictionIDGen.next(),
        name: 'New Group',
        assetTypes: [],
        edgeIds: [],
      });
      this.restrictionGroups = groups;
    },
    onEditRestrictionGroup({ index, newGroup }) {
      const groups = this.restrictionGroups.slice();
      groups[index] = newGroup;
      this.restrictionGroups = groups;
    },
    onRemoveRestrictionGroup(index) {
      const groups = this.restrictionGroups.slice();
      groups.splice(index, 1);
      this.restrictionGroups = groups;
    },
    onRestrictionAssetTypeMove({ index, assetType }) {
      const groups = this.restrictionGroups.map(g => {
        return {
          ...g,
          assetTypes: g.assetTypes.filter(t => t !== assetType),
        };
      });

      groups[index].assetTypes.push(assetType);
      groups[index].assetTypes.sort((a, b) => a.localeCompare(b));

      this.restrictionGroups = groups;
    },
  },
};
</script>

<style>
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