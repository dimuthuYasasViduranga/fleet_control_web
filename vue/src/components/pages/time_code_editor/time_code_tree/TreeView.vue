<template>
  <div class="tree-view">
    <div class="tree-view-nodes">
      <div class="buttons">
        <Icon
          v-if="!readonly && canAddRoots"
          class="add-root-icon"
          :icon="addRootIcon"
          v-tooltip="addRootText"
          @click="onAddNewRoot"
        />
        <button v-if="!readonly && canAddRoots" class="hx-btn" @click="onAddNewRoot">
          {{ addRootText }}
        </button>
      </div>
      <tree-node
        v-for="root in roots"
        :key="root.id"
        :node="root"
        :readonly="readonly"
        :canDeleteRoots="canDeleteRoots"
        :canEditRoots="canEditRoots"
        :addNodeText="addNodeText"
        :addLeafText="addLeafText"
        :deleteNodeText="deleteNodeText"
        :defaultLeafName="defaultLeafName"
        :defaultNodeName="defaultNodeName"
        :initLeafData="initLeafData"
        :initNodeData="initNodeData"
        @addNode="onAddNode"
        @deleteNode="onDeleteNode"
        @nameChange="onNameChange"
        @swap="onSwap"
      >
        <!-- pass all given slots to child -->
        <template v-for="(_, slot) of $scopedSlots" :slot="slot" slot-scope="{ node }">
          <slot :name="slot" :node="node" />
        </template>
      </tree-node>
    </div>
  </div>
</template>

<script>
import TreeNode from './TreeNode.vue';
import { toTree, getNodes } from './treeView.js';

import FolderClosedIcon from '@/components/icons/FolderClosed.vue';
import Icon from 'hx-layout/Icon.vue';

function arrMove(arr, oldIndex, newIndex) {
  arr.splice(newIndex, 0, arr.splice(oldIndex, 1)[0]);
}

function moveChild(flatTree, nodeToMove, newChildIndex) {
  const parentId = nodeToMove.parentId;
  const children = flatTree.filter(e => e.parentId === parentId);
  const nodeAtReplace = children[newChildIndex];

  let moveToIndex = null;
  let moveFromIndex = null;

  const length = flatTree.length;
  for (let i = 0; i < length; i++) {
    const node = flatTree[i];
    if (node.id === nodeToMove.id) {
      moveFromIndex = i;
    }

    if (node.id === nodeAtReplace.id) {
      moveToIndex = i;
    }
  }

  if (moveToIndex !== null && moveFromIndex !== null) {
    arrMove(flatTree, moveFromIndex, moveToIndex);
  }
}

function setParent(flatTree, nodeToMove, newParentId, childIndex = 0) {
  let targetIndex = -1;
  const existingIndex = flatTree.findIndex(e => e.id === nodeToMove.id);
  if (existingIndex === -1) {
    return;
  }

  const existingNewParentChildren = flatTree.filter(e => e.parentId === newParentId);
  if (childIndex >= existingNewParentChildren.length) {
    targetIndex = flatTree.length;
  } else {
    const targetChild = existingNewParentChildren[childIndex] || {};
    targetIndex = flatTree.findIndex(e => e.id === targetChild.id);
  }

  flatTree[existingIndex].parentId = newParentId;

  if (targetIndex !== -1) {
    arrMove(flatTree, existingIndex, targetIndex - 1);
  }
}

export default {
  name: 'TreeView',
  components: {
    TreeNode,
    Icon,
  },
  props: {
    readonly: Boolean,
    value: { type: Array, required: true },
    canDeleteRoots: { type: Boolean, default: false },
    canAddRoots: { type: Boolean, default: false },
    canEditRoots: { type: Boolean, default: true },
    addRootText: { type: String, default: 'Add Root' },
    addNodeText: { type: String, default: 'Add Node' },
    addLeafText: { type: String, default: 'Add Leaf' },
    addRootIcon: { type: Object, default: () => FolderClosedIcon },
    addLeafIcon: { type: Object },
    addNodeIcon: { type: Object },
    deleteIcon: { type: Object },
    deleteNodeText: { type: String, default: 'Delete' },
    defaultLeafName: { type: String, default: () => 'New Leaf' },
    defaultNodeName: { type: String, default: () => 'New Node' },
    initNodeData: { type: Function, default: null },
    initLeafData: { type: Function, default: null },
  },
  computed: {
    maxId() {
      if (this.value.length === 0) {
        return 0;
      }
      return Math.max(...this.value.map(m => m.id));
    },
    roots() {
      return toTree(this.value);
    },
  },
  methods: {
    onAddNode(newNode) {
      this.insertNode(newNode);
    },
    onAddNewRoot() {
      const rootNode = {
        id: this.maxId + 1,
        parentId: null,
        name: this.defaultNodeName,
        isLeaf: false,
        data: {},
      };
      this.insertNode(rootNode);
    },
    onDeleteNode(node) {
      this.removeNode(node);
    },
    onNameChange(node, name) {
      const newFlatTree = this.value.slice();
      newFlatTree.find(e => e.id === node.id).name = name;
      this.$emit('nameChange', node, name);
      this.emitFlatTree(newFlatTree);
    },
    onSwap(node, { addedIndex, removedIndex, payload }) {
      if (addedIndex === null && removedIndex === null) {
        return;
      }

      if (addedIndex !== null && removedIndex !== null) {
        const newFlatTree = this.value.slice();
        moveChild(newFlatTree, payload, addedIndex);
        this.emitFlatTree(newFlatTree);
        return;
      }

      if (addedIndex !== null && removedIndex === null) {
        const newFlatTree = this.value.slice();
        setParent(newFlatTree, payload, node.id, addedIndex);
        this.emitFlatTree(newFlatTree);
        return;
      }
    },
    insertNode(node) {
      if (!node.id) {
        node.id = this.maxId + 1;
      }
      const newFlatTree = this.value.slice();
      newFlatTree.push(node);
      this.$emit('add', node);
      this.emitFlatTree(newFlatTree);
    },
    removeNode(node) {
      const toRemove = getNodes(node).map(n => n.id);
      const newFlatTree = this.value.filter(e => !toRemove.includes(e.id));
      this.$emit('delete', node);
      this.emitFlatTree(newFlatTree);
    },
    emitFlatTree(flatTree) {
      this.$emit('input', flatTree);
    },
  },
};
</script>

<style>
@import '../../../../assets/hxInput.css';

.tree-view {
  padding: 1rem 0;
}

.tree-view-nodes {
  border-bottom: 0.1em solid #2c404c;
  border-top: 0.1em solid #2c404c;
}

.tree-view .add-root-icon {
  height: 1rem;
  width: 1rem;
  cursor: pointer;
}

.tree-node .add-root-icon:hover {
  stroke: grey;
}
</style>