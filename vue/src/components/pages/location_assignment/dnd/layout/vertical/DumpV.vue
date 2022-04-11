<template>
  <div
    v-tooltip="invalid ? 'This dump location is no longer active. Please re-assign' : ''"
    class="dump-v"
    :class="{ invalid }"
    @mouseleave="hovering = false"
    @mouseenter="hovering = true"
  >
    <div v-if="readonly" class="heading" readonly>
      {{ dumpName || 'No Dump' }}
    </div>
    <div v-else v-tooltip="'Move Trucks'" class="heading" @click="onMoveTrucks()">
      {{ dumpName || 'No Dump' }}
    </div>
    <div class="haul-trucks">
      <div class="actions">
        <template v-if="!readonly && hovering">
          <template v-if="assignedHaulTrucks.length">
            <Icon
              v-tooltip="'Clear Trucks'"
              class="clear"
              :icon="trashIcon"
              @click="onClearDump()"
            />

            <Icon v-tooltip="'Move Trucks'" class="move" :icon="editIcon" @click="onMoveTrucks()" />
          </template>

          <Icon
            v-else
            v-tooltip="'Remove Dump'"
            class="remove"
            :icon="crossIcon"
            @click="onRemoveDump()"
          />
        </template>
      </div>

      <Container
        class="haul-truck-container"
        :style="containerWidth"
        orientation="horizontal"
        group-name="draggable"
        :should-accept-drop="(_src, asset) => shouldAcceptIntoHaulTruck(asset)"
        :drop-placeholder="dropPlaceholderOptions"
        :get-child-payload="index => getChildPayload(index)"
        @drop="onDropIntoHaulTruck"
        @drag-end="onDragEnd()"
      >
        <Draggable v-for="haulTruck in assignedHaulTrucks" :key="haulTruck.id" :disabled="readonly">
          <AssetTile :asset="haulTruck" />
        </Draggable>
      </Container>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { Container } from 'vue-smooth-dnd';

import Draggable from '../../Draggable.vue';
import AssetTile from '../../asset_tile/AssetTile.vue';

import TrashIcon from '@/components/icons/Trash.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import EditIcon from '@/components/icons/Edit.vue';

export default {
  name: 'DumpV',
  components: {
    Icon,
    Container,
    Draggable,
    AssetTile,
  },
  props: {
    readonly: Boolean,
    dumpId: { type: [String, Number] },
    dumpName: { type: String, default: '' },
    haulTrucks: { type: Array, default: () => [] },
    columns: { type: Number, default: 2 },
    invalid: Boolean,
  },
  data: () => {
    return {
      crossIcon: CrossIcon,
      trashIcon: TrashIcon,
      editIcon: EditIcon,
      hovering: false,
      dropPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
    };
  },
  computed: {
    assignedHaulTrucks() {
      return this.haulTrucks.filter(h => h.dispatch.dumpId === this.dumpId);
    },
    containerWidth() {
      return `width: ${this.columns * 7 + 1}rem;`;
    },
  },
  methods: {
    getChildPayload(index) {
      const ht = this.assignedHaulTrucks[index];
      this.$emit('drag-start', ht);
      return ht;
    },
    onDragEnd() {
      this.$emit('drag-end');
    },
    shouldAcceptIntoHaulTruck(asset) {
      return asset && asset.type === 'Haul Truck';
    },
    onDropIntoHaulTruck({ addedIndex, removedIndex, payload }) {
      // is added
      if (addedIndex !== null && removedIndex === null) {
        this.$emit('set-haul-truck', payload);
      }
    },
    onRemoveDump() {
      this.$emit('remove-dump', this.dumpId);
    },
    onClearDump() {
      this.$emit('clear-dump', this.dumpId);
    },
    onMoveTrucks() {
      const assetIds = this.assignedHaulTrucks.map(a => a.id);
      this.$emit('move-trucks', { dumpId: this.dumpId, assetIds });
    },
  },
};
</script>

<style>
.dump-v .smooth-dnd-container .tile-drop-preview {
  border: 1px dashed grey;
  height: 7rem;
  width: 7rem;
  background-color: rgba(150, 150, 200, 0.1);
}

.dump-v .smooth-dnd-container .smooth-dnd-drop-preview-constant-class {
  top: 0;
  width: 7rem;
}
</style>

<style scoped>
.invalid {
  background-color: #ff65652c;
}

.smooth-dnd-draggable-wrapper {
  cursor: move;
}

.heading {
  height: 2.25rem;
  line-height: 2rem;
  font-size: 1.25rem;
  text-align: center;
  background-color: #23343f;
  cursor: pointer;
}

.heading:hover {
  opacity: 0.75;
}

.heading[readonly] {
  cursor: default;
}

.heading[readonly]:hover {
  opacity: 1;
}

/* --- assets ---- */
.haul-trucks .actions {
  height: 2rem;
  display: flex;
  justify-content: flex-start;
}

.haul-trucks .actions .hx-icon {
  cursor: pointer;
  padding: 0.4rem 0;
}

.haul-trucks .actions .remove:hover {
  stroke: red;
}

.haul-trucks .actions .clear:hover {
  stroke: red;
}

.haul-trucks .haul-truck-container {
  width: 100%;
  min-height: 7rem;
  padding: 0.25rem;
  padding-left: 0.5rem;
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  overflow: hidden;
}

.haul-trucks .asset-tile {
  background-color: #121f26;
}
</style>