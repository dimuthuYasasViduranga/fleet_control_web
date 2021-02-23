<template>
  <component
    :is="node.parentId === null ? 'div' : Draggable"
    class="tree-node"
    :class="{ 'is-root': node.parentId === null }"
  >
    <div class="node" :class="getClass" @mouseenter="onMouseEnter" @mouseleave="onMouseLeave">
      <span class="tree-node-caret-wrapper" :class="caretPointerClass" @click="toggleOpen">
        <span v-if="hasChildren" class="tree-node-caret" :class="caretClass"></span>
      </span>

      <Icon class="node-icon folder-icon" v-if="!node.isLeaf" :icon="addNodeIcon" />
      <Icon class="node-icon hyphen-icon" v-else :icon="hyphenIcon" />

      <div class="row-body-wrapper">
        <slot v-if="node.isLeaf" name="row-body-leaf" class="row-body-leaf" :node="node">
          <div class="edit-text" v-show="isEditing">
            <input
              ref="leaf-input"
              class="typeable"
              type="text"
              v-model="name"
              @keydown="onKeyDown"
              @focusout="onFocusOut"
            />
          </div>
          <div class="text" v-if="!isEditing && node.name" @click="onEditName('leaf-input')">
            {{ node.name }}
          </div>
          <div class="blank-italic" v-else-if="!isEditing" @click="onEditName('leaf-input')">
            blank
          </div>
        </slot>
        <slot v-else name="row-body-node" class="row-body-node" :node="node">
          <div class="edit-text" v-show="isEditing">
            <input
              ref="node-input"
              class="typeable"
              type="text"
              v-model="name"
              @keydown="onKeyDown"
              @focusout="onFocusOut"
            />
          </div>
          <div class="text" v-if="!isEditing && node.name" @click="onEditName('node-input')">
            {{ node.name }}
          </div>
          <div class="blank-italic" v-else-if="!isEditing" @click="onEditName('node-input')">
            blank
          </div>
        </slot>
      </div>

      <div class="padding"></div>

      <div class="tree-node-buttons" v-if="isHighlighted">
        <Icon
          class="node-icon add-node-icon"
          v-if="!node.isLeaf"
          :icon="addNodeIcon"
          v-tooltip="addNodeText"
          @click="onAddNode"
        />

        <Icon
          class="node-icon add-leaf-icon"
          v-if="!node.isLeaf"
          :icon="addLeafIcon"
          v-tooltip="addLeafText"
          @click="onAddLeaf"
        />

        <Icon
          class="node-icon delete-icon"
          v-if="showDelete"
          :icon="deleteIcon"
          v-tooltip="deleteText"
          @click="onDelete"
        />
      </div>
    </div>
    <div class="children">
      <Container
        v-if="this.isOpen"
        orientation="vertical"
        group-name="tn-children"
        :drop-placeholder="containerPlaceholderOptions"
        :get-child-payload="index => getDragPayload(index)"
        @drop="onDrop($event)"
      >
        <tree-node
          v-for="node in children"
          :key="node.id"
          :node="node"
          :canDeleteRoots="canDeleteRoots"
          :addNodeText="addNodeText"
          :addLeafText="addLeafText"
          :deleteText="deleteText"
          :addNodeIcon="addNodeIcon"
          :addLeafIcon="addLeafIcon"
          :deleteIcon="deleteIcon"
          :defaultLeafName="defaultLeafName"
          :defaultNodeName="defaultNodeName"
          @addNode="onPropogateAddNode"
          @deleteNode="onPropogateDeleteNode"
          @nameChange="onPropogateNameChange"
          @swap="onPropogateSwap"
        >
          <!-- pass all given slots to child -->
          <template v-for="(_, slot) of $scopedSlots" :slot="slot" slot-scope="{ node }">
            <slot :name="slot" :node="node" />
          </template>
        </tree-node>
      </Container>
    </div>
  </component>
</template>

<script>
import { Container, Draggable } from 'vue-smooth-dnd';

import Icon from 'hx-layout/Icon.vue';

import AddIcon from '@/components/icons/Add.vue';
import FolderClosedIcon from '@/components/icons/FolderClosed.vue';
import TrashIcon from '@/components/icons/Trash.vue';
import HyphenIcon from '@/components/icons/Hyphen.vue';
import ArrowUpIcon from '@/components/icons/ArrowUp.vue';
import ArrowDownIcon from '@/components/icons/ArrowDown.vue';

const ENTER = 13;

const DEFAULT_DATA_FN = () => ({});

export default {
  name: 'TreeNode',
  components: {
    Icon,
    Container,
    Draggable,
  },
  props: {
    node: { type: Object, required: true },
    canDeleteRoots: { type: Boolean, default: false },
    canEditRoots: { type: Boolean, default: true },
    addNodeText: { type: String, default: 'Add Node' },
    addLeafText: { type: String, default: 'Add Leaf' },
    moveUpText: { type: String, default: 'Move Up' },
    moveDownText: { type: String, default: 'Move Down' },
    deleteText: { type: String, default: 'Delete' },
    addLeafIcon: { type: Object, default: () => AddIcon },
    addNodeIcon: { type: Object, default: () => FolderClosedIcon },
    deleteIcon: { type: Object, default: () => TrashIcon },
    defaultLeafName: { type: String, default: () => 'New Leaf' },
    defaultNodeName: { type: String, default: () => 'New Node' },
    initNodeData: { type: Function, default: null },
    initLeafData: { type: Function, default: null },
  },
  data: () => {
    return {
      Draggable,
      isOpen: false,
      isHighlighted: false,
      isEditing: false,
      hyphenIcon: HyphenIcon,
      containerPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
    };
  },
  computed: {
    name: {
      get() {
        return this.node.name;
      },
      set(val) {
        this.$emit('nameChange', this.node, val);
      },
    },
    getClass() {
      return {
        'is-left': this.node.isLeaf,
        'is-node': !this.node.isLeaf,
        highlight: this.isHighlighted,
      };
    },
    caretPointerClass() {
      return {
        'caret-pointer': this.hasChildren,
      };
    },
    children() {
      return this.node.children || [];
    },
    hasChildren() {
      return this.children.length > 0;
    },
    showDelete() {
      if (this.node.parentId !== null || this.canDeleteRoots) {
        return true;
      }
      return false;
    },
    caretClass() {
      if (this.isOpen) {
        return 'caret-down';
      }
      return 'caret-right';
    },
  },
  methods: {
    toggleOpen() {
      this.isOpen = !this.isOpen;
    },
    onMouseEnter() {
      this.isHighlighted = true;
    },
    onMouseLeave() {
      this.isHighlighted = false;
    },
    onEditName(ref) {
      if (this.canEditRoots === false) {
        return;
      }
      this.isEditing = true;
      this.$nextTick(() => {
        this.$refs[ref].focus();
      });
    },
    onFocusOut() {
      this.isEditing = false;
    },
    onKeyDown(event) {
      if (event.keyCode === ENTER) {
        this.isEditing = false;
      }
    },
    onAddNode() {
      const data = (this.initNodeData || DEFAULT_DATA_FN)(this.node) || {};
      const newNode = {
        parentId: this.node.id,
        isLeaf: false,
        name: this.defaultNodeName,
        data,
      };
      this.isOpen = true;
      this.$emit('addNode', newNode);
    },
    onAddLeaf() {
      const data = (this.initLeafData || DEFAULT_DATA_FN)(this.node) || {};
      const newLeaf = {
        parentId: this.node.id,
        isLeaf: true,
        name: this.defaultLeafName,
        data,
      };
      this.isOpen = true;
      this.$emit('addNode', newLeaf);
    },
    onDelete() {
      this.$emit('deleteNode', this.node);
    },
    onPropogateAddNode(node) {
      this.$emit('addNode', node);
    },
    onPropogateDeleteNode(node) {
      this.$emit('deleteNode', node);
    },
    onPropogateNameChange(node, name) {
      this.$emit('nameChange', node, name);
    },
    onPropogateSwap(node, event) {
      this.$emit('swap', node, event);
    },
    getDragPayload(index) {
      return this.node.children[index];
    },
    onDrop(event) {
      event.payload.beingDragged = false;
      this.$emit('swap', this.node, event);
    },
  },
};
</script>

<style>
@import '../../../../assets/hxInput.css';

.tree-node {
  padding-left: 2rem;
  display: flex;
  flex-direction: column;
}

.tree-node.is-root {
  padding-left: 0;
}

.tree-node .node {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  padding: 5px 10px;
}

.tree-node .node.highlight {
  background-color: rgba(128, 128, 128, 0.247);
}

.tree-node .row-body-wrapper {
  font-size: 1.25rem;
  padding-top: 6px;
  padding-left: 4px;
}

.tree-node .tree-node-buttons {
  display: inline-flex;
  padding-top: 1px;
  height: 100%;
}

.tree-node .node-icon {
  height: 100%;
  width: 1.75rem;
  padding: 0.7rem 0;
  cursor: pointer;
}

.tree-node .tree-node-buttons .node-icon:hover {
  stroke: grey;
}

.tree-node .folder-icon,
.tree-node .hyphen-icon {
  cursor: default;
}

.tree-node .hyphen-icon {
  padding: 0.5rem;
}

.tree-node .padding {
  width: 1rem;
}

.tree-node .tree-node-caret-wrapper {
  display: flex;
  padding: 5px;
  width: 1rem;
}

.tree-node .caret-pointer {
  cursor: pointer;
}

.tree-node .caret-down {
  width: 0;
  height: 0;
  border-left: 6px solid transparent;
  border-right: 6px solid transparent;

  border-top: 6px solid grey;
}

.tree-node .caret-right {
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;

  border-left: 6px solid grey;
}

.tree-node .text {
  min-width: 2rem;
  cursor: pointer;
}

.tree-node .blank-italic {
  font-style: italic;
  color: grey;
  cursor: pointer;
}

.tree-node .typeable {
  border-bottom: none;
  height: 100%;
  color: black;
}

/* drag and drop outline */
.tree-node .smooth-dnd-container {
  min-height: 0;
}

.tree-node .tile-drop-preview {
  border: 1px dashed grey;
  background-color: rgba(150, 150, 200, 0.1);
}
</style>