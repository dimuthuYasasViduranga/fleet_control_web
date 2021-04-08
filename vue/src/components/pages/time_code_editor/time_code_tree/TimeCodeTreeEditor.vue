<template>
  <div class="time-code-tree-editor">
    <div class="button-selector">
      <select class="hx-select" v-model="selectedAssetTypeId">
        <option v-if="!selectedAssetTypeId" :value="null" class="hx-option" disabled>
          Asset Type
        </option>
        <option v-else :value="null" class="hx-option">None</option>
        <option class="hx-option" v-for="a in assetTypes" :value="a.id" :key="a.id">
          {{ a.type }}
        </option>
      </select>
      <button v-show="selectedAssetTypeId" class="hx-btn submit" @click="onSubmit">Submit</button>
      <button v-show="selectedAssetTypeId" class="hx-btn reset" @click="onReset">Reset</button>
    </div>

    <tree-view
      v-if="selectedAssetTypeId"
      class="time-code-tree"
      v-model="localTreeElements"
      :canAddRoots="false"
      :canEditRoots="false"
      addNodeText="Add Group"
      addLeafText="Add Time Code"
    >
      <template slot="row-body-leaf" slot-scope="{ node }">
        <TimeAllocationDropDown
          :value="node.data.timeCodeId"
          :showAll="true"
          @input="onTimeCodeChange($event, node)"
        />
      </template>
    </tree-view>
  </div>
</template>

<script>
import TreeView from './TreeView.vue';
import { locateChild } from './treeView.js';
import TimeAllocationDropDown from '../../../TimeAllocationDropDown.vue';
import ConfirmModal from '@/components/modals/ConfirmModal.vue';
import { firstBy } from 'thenby';
import { attributeFromList } from '@/code/helpers';

function toLocalTreeElement(element) {
  const isLeaf = element.timeCodeId !== null;
  return {
    id: element.id,
    parentId: element.parentId,
    name: element.nodeName,
    isLeaf,
    data: {
      timeCodeId: element.timeCodeId,
      timeCodeGroupId: element.timeCodeGroupId,
    },
  };
}

function max(numbers, defVal) {
  const maxVal = Math.max(numbers);
  return maxVal === -Infinity ? defVal : maxVal;
}

function ensureGroupRoots(groups, elements) {
  const highestId = max(
    elements.map(e => e.id),
    1,
  );
  const roots = [];
  const nonRoots = [];
  elements.forEach(e => {
    !e.parentId ? roots.push(e) : nonRoots.push(e);
  });

  // create missing root elements
  const presentGroupIds = roots.map(r => r.data.timeCodeGroupId);
  const missingRoots = groups
    .filter(g => !presentGroupIds.includes(g.id))
    .map((g, index) => {
      return {
        id: highestId + index + 1,
        parentId: null,
        name: g.name,
        isLeaf: false,
        data: {
          timeCodeId: null,
          timeCodeGroupId: g.id,
        },
      };
    });

  // order roots by timeCodeGroupId
  const completeRoots = roots.concat(missingRoots);
  completeRoots.sort((a, b) => a.data.timeCodeGroupId - b.data.timeCodeGroupId);

  // prepend to all other elmenets;
  return completeRoots.concat(nonRoots);
}

function validElement(e, elements) {
  const isRoot = !e.parentId;
  const leafWithTimeCode = e.isLeaf && e.data.timeCodeId;
  const groupWithChildren = !e.isLeaf && elements.filter(el => el.parentId === e.id).length !== 0;
  return isRoot || leafWithTimeCode || groupWithChildren;
}

function removeInvalidElements(elements) {
  const filtered = elements.filter(e => validElement(e, elements));
  if (filtered.length === elements.length) {
    return filtered;
  }

  return removeInvalidElements(filtered);
}

export default {
  name: 'TimeCodeTreeEditor',
  components: {
    TreeView,
    TimeAllocationDropDown,
  },
  props: {
    timeCodeGroups: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      selectedAssetTypeId: null,
      localTreeElements: [],
    };
  },
  computed: {
    timeCodeTreeElements() {
      return this.$store.state.constants.timeCodeTreeElements;
    },
  },
  watch: {
    selectedAssetTypeId(id) {
      this.setAssetType(id);
    },
    timeCodeTreeElements() {
      this.setAssetType(this.selectedAssetTypeId);
    },
  },
  methods: {
    setAssetType(newTypeId) {
      this.errors = [];
      const elements = this.timeCodeTreeElements
        .filter(tc => tc.assetTypeId === newTypeId)
        .map(toLocalTreeElement);
      const elementsWithRoots = ensureGroupRoots(this.timeCodeGroups, elements);
      this.localTreeElements = elementsWithRoots;
    },
    onTimeCodeChange(value, node) {
      const newTree = this.localTreeElements.slice();
      newTree.find(e => e.id === node.id).data.timeCodeId = value;
      this.localTreeElements = newTree;
    },
    onReset() {
      this.setAssetType(this.selectedAssetTypeId);
    },
    onSubmit() {
      const pendingElements = removeInvalidElements(this.localTreeElements);

      if (pendingElements.length === this.localTreeElements.length) {
        this.submit();
        return;
      }

      const ok = 'Yes';
      const opts = {
        title: 'Invalid Tree',
        body: 'There are invalid elements, would you like them to be removed before submitting?',
        ok,
        cancel: 'No',
      };

      this.$modal.create(ConfirmModal, opts).onClose(answer => {
        if (answer === ok) {
          this.localTreeElements = pendingElements;
          this.submit();
        }
      });
    },
    submit() {
      const groupLookup = {};
      const sortedElements = removeInvalidElements(this.localTreeElements);
      sortedElements.sort((a, b) => (a.parentId || 0) - (b.parentId || 0));
      sortedElements.forEach(e => {
        const timeCodeGroupId = e.data.timeCodeGroupId || groupLookup[`${e.parentId}`];
        groupLookup[`${e.id}`] = timeCodeGroupId;
      });

      const elements = sortedElements.map(t => {
        const timeCodeId = parseInt(t.data.timeCodeId, 10) || null;
        const timeCodeGroupId = groupLookup[`${t.id}`];
        const nodeName = timeCodeId ? null : t.name;
        return {
          id: t.id,
          parent_id: t.parentId,
          node_name: nodeName || null,
          time_code_id: timeCodeId,
          time_code_group_id: timeCodeGroupId,
        };
      });

      const payload = {
        asset_type_id: this.selectedAssetTypeId,
        elements,
      };

      this.$channel
        .push('set time code tree elements', payload)
        .receive('ok', () => this.$toaster.info('Time code tree updated'))
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to update time code tree'));
    },
  },
};
</script>

<style>
.time-code-tree-editor .time-code-tree .tree-node .node {
  height: 3rem;
}

.time-code-tree-editor .time-code-tree .dropdown-wrapper {
  width: 20rem;
}

.time-code-tree-editor .button-selector {
  padding-bottom: 0.5rem;
}

.time-code-tree-editor .button-selector .hx-btn {
  width: 10rem;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
  text-transform: capitalize;
}

.time-code-tree-editor .dd-option {
  border-left: 10px solid transparent;
}

.time-code-tree-editor .hx-btn.submit {
  margin-left: 0.25rem;
}
</style>