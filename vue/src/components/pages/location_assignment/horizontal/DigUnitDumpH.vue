<template>
  <div class="dig-unit-dump-h" @mouseleave="hovering = false" @mouseenter="hovering = true">
    <div class="dump-name">{{ dumpName || 'Unknown Dump' }}</div>
    <div class="haul-truck">
      <div class="actions">
        <template v-if="hovering">
          <template v-if="filteredHaulTrucks.length">
            <Icon
              v-tooltip="'Clear Trucks'"
              class="clear"
              :icon="trashIcon"
              @click="onClearDump(dumpId)"
            />

            <Icon v-tooltip="'Move Trucks'" class="move" :icon="editIcon" @click="onMoveDump()" />
          </template>

          <Icon
            v-else
            v-tooltip="'Remove Dump'"
            class="remove"
            :icon="crossIcon"
            @click="onRemoveDump(dumpId)"
          />
        </template>
      </div>

      <Container
        class="haul-truck-container"
        orientation="horizontal"
        group-name="draggable"
        :should-accept-drop="(_src, asset) => shouldAcceptIntoHaulTruck(asset)"
        :drop-placeholder="dropPlaceholderOptions"
        :get-child-payload="index => getChildPayload(index)"
        @drop="onDropIntoHaulTruck"
        @drag-end="onDragEnd()"
      >
        <Draggable v-for="haulTruck in filteredHaulTrucks" :key="haulTruck.id">
          <AssetTile :asset="haulTruck" />
        </Draggable>
      </Container>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { Container, Draggable } from 'vue-smooth-dnd';
import AssetTile from './../AssetTile.vue';

import TrashIcon from '@/components/icons/Trash.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import EditIcon from '@/components/icons/Edit.vue';
import { attributeFromList } from '@/code/helpers';

export default {
  name: 'DigUnitDumpH',
  components: {
    Icon,
    Container,
    Draggable,
    AssetTile,
  },
  props: {
    dumpId: { type: [Number, String], default: null },
    dumpName: { type: String, default: '' },
    haulTrucks: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      hovering: false,
      crossIcon: CrossIcon,
      trashIcon: TrashIcon,
      editIcon: EditIcon,
      dropPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
    };
  },
  computed: {
    filteredHaulTrucks() {
      const haulTrucks = this.haulTrucks.filter(h => h.dispatch.dumpId === this.dumpId);
      haulTrucks.sort((a, b) => a.name.localeCompare(b.name));
      return haulTrucks;
    },
  },
  methods: {
    getChildPayload(index) {
      const asset = this.filteredHaulTrucks[index];
      this.$emit('drag-start', asset);
      return asset;
    },
    onDragEnd() {
      this.$emit('drag-end');
    },
    onDropIntoHaulTruck({ addedIndex, removedIndex, payload }) {
      // is added
      if (addedIndex !== null && removedIndex === null) {
        this.$emit('add', payload);
      }
    },
    shouldAcceptIntoHaulTruck(asset) {
      return asset && asset.type === 'Haul Truck';
    },
    onRemoveDump() {
      this.$emit('remove-dump', this.dumpId);
    },
    onClearDump() {
      this.$emit('clear-dump', this.dumpId);
    },
    onMoveDump() {
      this.$emit('move-dump', this.dumpId);
    },
  },
};
</script>

<style>
.dig-unit-dump-h .smooth-dnd-container .tile-drop-preview {
  border: 1px dashed grey;
  height: 7rem;
  width: 7rem;
  background-color: rgba(150, 150, 200, 0.1);
}

.dig-unit-dump-h .smooth-dnd-container .smooth-dnd-drop-preview-constant-class {
  top: 0;
  width: 7rem;
}
</style>

<style scoped>
.dig-unit-dump-h {
  min-width: 15rem;
}

.smooth-dnd-draggable-wrapper {
  cursor: move;
}

.dump-name {
  height: 2.25rem;
  line-height: 2rem;
  font-size: 1.25rem;
  text-align: center;
  background-color: #23343f;
  padding: 0.25rem;
}

/* --- haul truck ---- */
.haul-truck .actions {
  height: 2rem;
  display: flex;
  justify-content: flex-start;
}

.haul-truck .actions .hx-icon {
  cursor: pointer;
  padding: 0.4rem 0;
}

.haul-truck .actions .remove:hover {
  stroke: red;
}

.haul-truck .actions .clear:hover {
  stroke: red;
}

.haul-truck .haul-truck-container {
  width: 100%;
  min-height: 7rem;
  padding: 0.25rem;
  padding-left: 0.5rem;
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  overflow: hidden;
}

.haul-truck .asset-tile {
  background-color: #121f26;
}
</style>