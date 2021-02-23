<template>
  <div class="message-tree-editor">
    <div class="asset-selector">
      <select class="hx-select" v-model="selectedAssetTypeId" @change="onAssetTypeChange">
        <option v-if="!selectedAssetTypeId" :value="null" class="hx-option" disabled>
          Asset Type
        </option>
        <option v-else :value="null" class="hx-option">None</option>
        <option class="hx-option" v-for="a in assetTypes" :value="a.id" :key="a.id">
          {{ a.type }}
        </option>
      </select>
      <button v-show="selectedAssetTypeId" class="hx-btn submit" @click="onSubmit">Submit</button>
    </div>
    <div v-if="selectedAssetTypeId" class="message-list">
      <div class="column source">
        <div class="title">Available</div>
        <Container
          class="message-item"
          group-name="message-type"
          :drop-placeholder="containerPlaceholderOptions"
          :get-child-payload="sourcePayload"
          @drop="onDrop('source', $event)"
        >
          <Draggable v-for="item in sourceItems" :key="item.id">
            {{ item.type }}
          </Draggable>
        </Container>
      </div>
      <div class="column target">
        <div class="title">Assigned</div>
        <Container
          class="message-item"
          group-name="message-type"
          :drop-placeholder="containerPlaceholderOptions"
          :get-child-payload="targetPayload"
          @drop="onDrop('target', $event)"
        >
          <Draggable v-for="item in targetItems" :key="item.id">
            {{ item.type }}
          </Draggable>
        </Container>
      </div>
    </div>
  </div>
</template>

<script>
import { Container, Draggable } from 'vue-smooth-dnd';
import LoadingModal from '../../../modals/LoadingModal.vue';

function applyDrag(arr, { removedIndex, addedIndex, payload }) {
  if (removedIndex === null && addedIndex === null) {
    return arr;
  }

  const newArr = [...arr];
  let itemToAdd = payload;

  if (removedIndex !== null) {
    itemToAdd = newArr.splice(removedIndex, 1)[0];
  }

  if (addedIndex !== null) {
    newArr.splice(addedIndex, 0, itemToAdd);
  }

  return newArr;
}

function getUnassignedTypes(messageTree, availableTypes, assetTypeId) {
  const assignedTypeIds = messageTree.filter(e => e.assetTypeId === assetTypeId).map(e => e.messageTypeId);

  const unassignedTypes = availableTypes.filter(m => !assignedTypeIds.includes(m.id));
  unassignedTypes.sort((a, b) => a.type.localeCompare(b.type));
  return unassignedTypes;
}

function getAssignedTypes(messageTree, availableTypes, assetTypeId) {
  const assignedTreeElements = messageTree.filter(t => t.assetTypeId === assetTypeId);
  assignedTreeElements.sort((a, b) => (a.order || 0) - (b.order || 0));
  return assignedTreeElements
    .map(e => availableTypes.find(m => m.id === e.messageTypeId))
    .filter(e => e);
}

export default {
  name: 'MessageTreeEditor',
  components: {
    Container,
    Draggable,
  },
  props: {
    messageTypes: { type: Array, default: () => [] },
    messageTree: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      selectedAssetTypeId: null,
      localElements: [],
      sourceItems: [],
      targetItems: [],
      containerPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
    };
  },
  computed: {
    availableMessageTypes() {
      return this.messageTypes.filter(m => !m.deleted);
    },
  },
  methods: {
    onAssetTypeChange(event) {
      const newTypeId = parseInt(event.target.value, 10) || null;
      this.sourceItems = getUnassignedTypes(
        this.messageTree,
        this.availableMessageTypes,
        newTypeId,
      );
      this.targetItems = getAssignedTypes(this.messageTree, this.availableMessageTypes, newTypeId);
    },
    onDrop(container, dropResults) {
      if (container === 'source') {
        this.sourceItems = applyDrag(this.sourceItems, dropResults);
      } else if (container === 'target') {
        this.targetItems = applyDrag(this.targetItems, dropResults);
      }
    },
    sourcePayload(index) {
      return this.sourceItems[index];
    },
    targetPayload(index) {
      return this.targetItems[index];
    },
    onSubmit() {
      if (!this.selectedAssetTypeId) {
        console.error('[MessageTreeEditor] No asset type selected');
        return;
      }

      const typeIds = this.targetItems.map(i => i.id);

      const payload = {
        asset_type_id: this.selectedAssetTypeId,
        ids: typeIds,
      };

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'Updating Message Tree' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('set operator message type tree', payload)
        .receive('ok', () => {
          loading.close();
          this.$toasted.global.info('Message tree updated');
        })
        .receive('error', resp => {
          loading.close();
          this.$toasted.global.error(resp.error);
        })
        .receive('timeout', () => {
          loading.close();
          this.$toasted.global.noComms('Unable to update message tree');
        });
    },
  },
};
</script>

<style>
.message-tree-editor .message-list {
  display: flex;
}

.message-tree-editor .message-item {
  width: 100%;
  height: 60vh;
  overflow-y: auto;
}

.message-tree-editor .column {
  width: 100%;
}

.message-tree-editor .title {
  font-size: 2rem;
  text-align: center;
  margin-bottom: 0.5rem;
}

.message-tree-editor .asset-selector {
  padding-bottom: 1rem;
}

.message-tree-editor .hx-btn.submit {
  margin-left: 0.25rem;
}

.message-tree-editor .message-list .source {
  border-right: 1px solid #677e8c;
}

/* ------ drag and drop wrappers ----- */
.message-tree-editor .smooth-dnd-draggable-wrapper {
  cursor: pointer;
  background-color: #2c404c;
  width: 100%;
  font-size: 1.25rem;
  text-align: center;
  height: 4rem;
  line-height: 4rem;
  border-top: 0.001em solid #677e8c;
  border-bottom: 0.001em solid #677e8c;
  margin: 10px 0;
}

.message-tree-editor .tile-drop-preview {
  height: 4rem;
  border: 1px dashed grey;
  background-color: rgba(150, 150, 200, 0.1);
}
</style>