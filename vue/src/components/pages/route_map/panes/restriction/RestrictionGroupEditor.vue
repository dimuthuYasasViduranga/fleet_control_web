<template>
  <div class="restriction-group-editor">
    <RestrictionGroup
      :value="unusedGroup"
      :canEditName="false"
      :canRemove="false"
      @added="onSetAssetTypeUnused"
    />
    <RestrictionGroup
      v-for="(group, index) in value"
      :key="index"
      :value="group"
      @update="onGroupUpdate(index, $event)"
      @added="onAssetTypeAdded(index, $event)"
      @remove="onRemove(index)"
    />
    <button class="hx-btn" @click="onAddGroup">Add</button>
  </div>
</template>

<script>
import { uniq } from '@/code/helpers';
import RestrictionGroup from './RestrictionGroup.vue';

function removeAssetType(groups, assetType) {
  return groups.map(g => {
    return {
      ...g,
      assetTypes: g.assetTypes.filter(t => t !== assetType),
    };
  });
}

export default {
  name: 'RestrictionGroupEditor',
  components: {
    RestrictionGroup,
  },
  props: {
    value: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
  },
  computed: {
    nextId() {
      const ids = this.value.map(v => v.id);
      return Math.min(...ids, 0) - 1;
    },
    unusedGroup() {
      const usedAssets = uniq(this.value.map(g => g.assetTypes).flat());
      const remainingAssets = this.assetTypes
        .map(at => at.type)
        .filter(t => !usedAssets.includes(t));

      return {
        name: '-- Unused --',
        assetTypes: remainingAssets,
      };
    },
  },
  methods: {
    onGroupUpdate(index, group) {
      const groups = this.value.slice();
      groups[index] = group;
      this.$emit('input', groups);
    },
    onAddGroup() {
      const groups = this.value.slice();
      groups.push({ id: this.nextId, name: 'New Group', assetTypes: [] });
      this.$emit('input', groups);
    },
    onSetAssetTypeUnused({ assetType }) {
      // remove asset type from everywhere
      this.$emit('input', removeAssetType(this.value, assetType));
    },
    onAssetTypeAdded(groupIndex, { assetType }) {
      // remove asset type from everywhere
      const filteredGroups = removeAssetType(this.value, assetType);

      // add it into the new group
      const types = filteredGroups[groupIndex].assetTypes;
      types.push(assetType);
      types.sort((a, b) => a.localeCompare(b));

      this.$emit('input', filteredGroups);
    },
    onRemove(groupIndex) {
      const groups = this.value;
      groups.splice(groupIndex, 1);
      this.$emit('input', groups);
    },
  },
};
</script>