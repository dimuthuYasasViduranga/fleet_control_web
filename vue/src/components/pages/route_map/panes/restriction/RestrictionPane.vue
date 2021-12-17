<template>
  <div class="restriction-pane">
    <RestrictionGroup
      v-for="(group, index) in localRestrictionGroups"
      :key="index"
      :name.sync="group.name"
      :graph="graph"
      :edges="group.edges"
      :assetTypes="group.assetTypes"
      :locations="locations"
      :canEditName="group.canEditName"
      :canRemove="group.canRemove"
      :showPreview="group.showPreview"
      @update="onGroupUpdate(index, $event)"
      @added="onAssetTypeAdded(index, $event)"
      @remove="onRemove(index)"
    />
    <button class="hx-btn" @click="onAddGroup">Add</button>
  </div>
</template>

<script>
import RestrictionGroup from './RestrictionGroup.vue';
import { uniq } from '@/code/helpers';

function removeAssetType(groups, assetType) {
  return groups.map(g => {
    return {
      ...g,
      assetTypes: g.assetTypes.filter(t => t !== assetType),
    };
  });
}

export default {
  name: 'RestrictionPane',
  components: {
    RestrictionGroup,
  },
  props: {
    graph: { type: Object },
    locations: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
    restrictionGroups: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      localRestrictionGroups: [],
    };
  },
  computed: {
    nextId() {
      const ids = this.localRestrictionGroups.map(g => g.id || 0);
      return Math.min(...ids, 0) - 1;
    },
  },
  watch: {
    restrictionGroups: {
      immediate: true,
      handler(groups) {
        const validGroups = groups.map(g => {
          return {
            id: g.id,
            name: g.name,
            assetTypes: g.assetTypes.slice(),
            // TODO need to work out how to do this part becuase we need to handle
            // if the source graph is different
          };
        });

        const usedAssetTypes = uniq(validGroups.map(g => g.assetTypes).flat());
        const remainingAssetTypes = this.assetTypes
          .map(at => at.type)
          .filter(t => !usedAssetTypes.includes(t));

        const unusedGroup = {
          name: '-- Unused --',
          assetTypes: remainingAssetTypes,
          canEditName: false,
          canRemove: false,
          showPreview: false,
          edges: [],
        };

        validGroups.unshift(unusedGroup);
        this.localRestrictionGroups = validGroups;
      },
    },
  },
  methods: {
    onGroupUpdate(index, group) {
      const groups = this.localRestrictionGroups.slice();
      groups[index] = group;
      this.localRestrictionGroups = groups;
    },
    updateLocalGroups(groups) {
      this.localRestrictionGroups = groups || this.localRestrictionGroups;
    },
    onSetAssetTypeUnused({ assetType }) {
      // remove asset type from everywhere
      this.localRestrictionGroups = removeAssetType(this.localRestrictionGroups, assetType);
    },
    onAssetTypeAdded(groupIndex, { assetType }) {
      // remove asset type from everywhere
      const filteredGroups = removeAssetType(this.localRestrictionGroups, assetType);

      // add it into the new group
      const types = filteredGroups[groupIndex].assetTypes;
      types.push(assetType);
      types.sort((a, b) => a.localeCompare(b));

      this.updateLocalGroups(filteredGroups);
    },
    onRemove(groupId) {
      const groups = this.localRestrictionGroups.slice();
      groups.splice(groupId, 1);

      this.updateLocalGroups(groups);
    },
    onAddGroup() {
      const groups = this.localRestrictionGroups.slice();
      groups.push({ id: this.nextId, name: 'New Group', assetTypes: [] });
      this.updateLocalGroups(groups);
    },
  },
};
</script>

<style>
</style>