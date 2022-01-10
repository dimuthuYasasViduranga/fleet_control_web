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
        <ReviewPane
          v-else-if="selectedStage === 'review'"
          :graph="graph"
          :restrictionGroups="restrictionGroups"
          @reset="onResetAll()"
          @cancel="close()"
          @submit="onSubmit()"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';

import CreatorPane from './panes/creator/CreatorPane.vue';
import RestrictionPane from './panes/restriction/RestrictionPane.vue';
import ReviewPane from './panes/ReviewPane.vue';

import FullscreenIcon from '@/components/icons/Fullscreen.vue';
import MinimiseIcon from '@/components/icons/Minimise.vue';

import { exitFullscreen, isElementFullscreen, requestFullscreen } from '@/code/fullscreen';
import { fromRoute, Graph } from '@/code/graph';
import { addPolylineToGraph, editGraph } from './route.js';
import { attributeFromList, IdGen, toLookup } from '@/code/helpers';
import { graphToSegments, nextDirection } from './common';
import ConfirmModal from '@/components/modals/ConfirmModal.vue';
import LoadingModal from '@/components/modals/LoadingModal.vue';

const STAGES = ['create', 'restrict', 'review'];
const SNAP_DISTANCE_PX = 10;
const RestrictionIDGen = new IdGen(-1, -1);

function segmentToEdges(seg, vertices) {
  if (seg.direction === 'both') {
    return seg.edges.map(e => {
      return {
        id: e.id,
        edgeId: e.data.edgeId,
        vertexStartId: vertices[e.startVertexId].data.vertexId,
        vertexEndId: vertices[e.endVertexId].data.vertexId,
      };
    });
  }

  if (seg.direction === 'positive') {
    const edge = seg.edges.find(e => e.endVertexId === seg.endVertexId);
    return [
      {
        id: edge.id,
        edgeId: edge.data.edgeId,
        vertexStartId: vertices[edge.startVertexId].data.vertexId,
        vertexEndId: vertices[edge.endVertexId].data.vertexId,
      },
    ];
  }

  const edge = seg.edges.find(e => e.endVertexId === seg.startVertexId);
  return [
    {
      id: edge.id,
      edgeId: edge.data.edgeId,
      vertexStartId: vertices[edge.startVertexId].data.vertexId,
      vertexEndId: vertices[edge.endVertexId].data.vertexId,
    },
  ];
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
      activeRoute: state => state.activeRoute,
    }),
    routeRestrictionGroups() {
      const lookup = toLookup(
        this.assetTypes,
        e => e.id,
        e => e.type,
      );
      const active = this.activeRoute || {};
      return (active.restrictionGroups || []).map(r => {
        const assetTypes = r.assetTypeIds.map(id => lookup[id]);

        return {
          id: r.id,
          name: r.name,
          assetTypes,
          edgeIds: r.edgeIds.slice(),
        };
      });
    },
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
    close(resp) {
      this.$emit('close', resp);
    },
    outerClickIntercept(payload) {
      return new Promise(resolve => {
        const opts = {
          title: 'Are you sure you want to quit?',
          body: 'Any progress made will be loss',
          ok: 'Yes',
        };

        this.$modal.create(ConfirmModal, opts).onClose(resp => {
          if (resp !== opts.ok) {
            payload.ignore = true;
          }
          resolve();
        });
      });
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
      this.graph = fromRoute(this.activeRoute);
    },
    reloadGraphSegments() {
      this.segments = graphToSegments(this.graph, this.segments);
    },
    reloadRestrictionGroups() {
      let groups = this.routeRestrictionGroups.slice();
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
    onSubmit() {
      const vertices = Object.values(this.graph.vertices).map(v => {
        return {
          id: v.id,
          vertexId: v.data.vertexId,
          lat: v.data.lat,
          lng: v.data.lng,
        };
      });

      const edges = this.segments.map(s => segmentToEdges(s, this.graph.vertices)).flat();

      const restrictionGroups = this.restrictionGroups.map(r => {
        const assetTypeIds = r.assetTypes.map(t =>
          attributeFromList(this.assetTypes, 'type', t, 'id'),
        );

        return {
          name: r.name,
          asset_type_ids: assetTypeIds,
          edge_ids: r.edgeIds,
        };
      });

      const formattedVertices = vertices.map(n => {
        return {
          id: n.vertexId,
          lat: n.lat,
          lng: n.lng,
        };
      });

      const formattedEdges = edges.map(e => {
        return {
          id: e.edgeId,
          vertex_start_id: e.vertexStartId,
          vertex_end_id: e.vertexEndId,
        };
      });

      const payload = {
        route_id: this.activeRoute?.id,
        vertices: formattedVertices,
        edges: formattedEdges,
        restriction_groups: restrictionGroups,
      };

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'updating routes' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('routing:update', payload)
        .receive('ok', () => {
          this.$toaster.info('Route update successful');
          loading.close();
          this.close();
        })
        .receive('error', error => {
          console.error(error);
          loading.close();
          if (error.error === 'race') {
            this.$toaster.error('Route updated by another user, please try again');
            this.close();
            return;
          }
          this.$toaster.error(error.error);
        })
        .receive('timeout', () => {
          this.$toaster.noComms('unable to update routes at this time');
          loading.close();
        });
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