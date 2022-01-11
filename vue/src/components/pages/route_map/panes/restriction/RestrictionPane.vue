<template>
  <div class="restriction-pane">
    <RestrictionGroup
      v-for="(group, index) in restrictionGroups"
      :key="index"
      :name.sync="group.name"
      :graph="directionalGraph"
      :edgeIds="group.edgeIds"
      :assetTypes="group.assetTypes"
      :locations="locations"
      :canEditName="group.canEditName"
      :canRemove="group.canRemove"
      :showPreview="group.showPreview"
      @update="onGroupUpdate(index, $event)"
      @added="onAssetTypeAdded(index, $event)"
      @remove="onRemove(index)"
      @edges-changed="onEdgesChanged(index, $event)"
    />
    <button class="hx-btn" @click="onAddGroup">Add</button>
  </div>
</template>

<script>
import RestrictionGroup from './RestrictionGroup.vue';
import { copy } from '@/code/helpers';

export default {
  name: 'RestrictionPane',
  components: {
    RestrictionGroup,
  },
  props: {
    graph: { type: Object },
    segments: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
    restrictionGroups: { type: Array, default: () => [] },
  },
  computed: {
    nextId() {
      const ids = this.restrictionGroups.map(g => g.id || 0);
      return Math.min(...ids, 0) - 1;
    },
    directionalGraph() {
      const graph = this.graph.copy();

      this.segments
        .filter(s => s.direction !== 'both')
        .forEach(s => {
          if (s.direction === 'positive') {
            graph.removeEdge(s.vertexBId, s.vertexAId);
          } else {
            graph.removeEdge(s.vertexAId, s.vertexBId);
          }
        });
      return graph;
    },
  },

  methods: {
    onGroupUpdate(index, newGroup) {
      this.$emit('edit', { index, newGroup });
    },
    onAssetTypeAdded(index, { assetType }) {
      this.$emit('move', { index, assetType });
    },
    onRemove(groupIndex) {
      this.$emit('remove', groupIndex);
    },
    onAddGroup() {
      this.$emit('add');
    },
    onEdgesChanged(index, edgeIds) {
      const newGroup = copy(this.restrictionGroups[index]);
      newGroup.edgeIds = edgeIds;
      this.$emit('edit', { index, newGroup });
    },
  },
};
</script>

<style>
</style>