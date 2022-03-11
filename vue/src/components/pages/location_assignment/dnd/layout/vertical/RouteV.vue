<template>
  <div class="route-v">
    <div v-if="readonly" class="heading" readonly>
      {{ heading }}
    </div>
    <div v-else v-tooltip="'Change Source'" class="heading" @click="onMoveDumps">
      {{ heading }}
    </div>

    <div
      class="target-load"
      :style="minWidthStyle"
      @mouseenter="hovering = true"
      @mouseleave="hovering = false"
    >
      <div class="dig-unit-tile-wrapper">
        <div style="margin: auto">
          <div class="container-wrapper" :class="{ empty: !this.digUnit || draggingDigUnit }">
            <Container
              class="dig-unit-container"
              orientation="vertical"
              group-name="draggable"
              :should-accept-drop="(_src, asset) => shouldAcceptIntoDigUnit(asset)"
              :drop-placeholder="dropPlaceholderOptions"
              :get-child-payload="index => getChildPayload(index)"
              @drop="onDropIntoDigUnit"
              @drag-end="onDragEnd()"
            >
              <Draggable :disabled="readonly">
                <AssetTile
                  v-if="digUnit && !draggingDigUnit"
                  class="dig-unit-tile"
                  :asset="digUnit"
                />
              </Draggable>
            </Container>
          </div>
        </div>
      </div>
      <div class="actions">
        <template v-if="!readonly && hovering">
          <Icon
            v-if="assignedHaulTrucks.length"
            v-tooltip="'Clear All'"
            class="clear"
            :icon="trashIcon"
            @click="onClearRoute()"
          />
          <Icon
            v-else
            v-tooltip="'Remove'"
            class="remove"
            :icon="crossIcon"
            @click="onRemoveRoute()"
          />

          <Icon v-tooltip="'Add Dump'" class="add" :icon="addIcon" @click="onRequestAddDump()" />
        </template>
      </div>
    </div>

    <div class="dumps">
      <DumpV
        v-for="dump in dumps"
        :key="dump.id"
        :readonly="readonly"
        :dumpId="dump.id"
        :dumpName="dump.extendedName"
        :haulTrucks="assignedHaulTrucks"
        :columns="cols"
        @drag-start="onDragStart"
        @drag-end="onDragEnd"
        @set-haul-truck="onSetHaulTruck(digUnitId, loadId, dump.id, $event)"
        @remove-dump="onRemoveDump(dump.id)"
        @clear-dump="onClearDump(dump.id)"
        @move-trucks="onMoveTrucks"
      />
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { Container } from 'vue-smooth-dnd';

import AssetTile from '../../asset_tile/AssetTile.vue';
import Draggable from '../../Draggable.vue';
import DumpV from './DumpV.vue';

import TrashIcon from '@/components/icons/Trash.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import AddIcon from '@/components/icons/Add.vue';
import EditIcon from '@/components/icons/Edit.vue';
import { attributeFromList } from '@/code/helpers';

const NO_LOC = 'No Location';

export default {
  name: 'RouteB',
  components: {
    Icon,
    AssetTile,
    DumpV,
    Container,
    Draggable,
  },
  props: {
    readonly: Boolean,
    digUnitId: { type: [Number, String] },
    loadId: { type: [Number, String] },
    dumpIds: { type: Array, default: () => [] },
    digUnits: { type: Array, default: () => [] },
    haulTrucks: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    columns: { type: Number, default: 2 },
  },
  data: () => {
    return {
      editIcon: EditIcon,
      addIcon: AddIcon,
      trashIcon: TrashIcon,
      crossIcon: CrossIcon,
      hovering: false,
      dropPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
      draggingDigUnit: false,
    };
  },
  computed: {
    dumps() {
      return this.locations
        .filter(l => this.dumpIds.includes(l.id))
        .sort((a, b) => a.name.localeCompare(b.name));
    },
    digUnit() {
      return this.digUnits.find(a => a.id === this.digUnitId);
    },
    loadLocation() {
      return this.locations.find(l => l.id === this.loadId);
    },
    heading() {
      const digUnit = this.digUnit;
      if (digUnit) {
        const digUnitLocName = attributeFromList(
          this.locations,
          'id',
          digUnit.activity.locationId,
          'name',
        );
        return digUnitLocName ? `${digUnit.name} (${digUnitLocName || NO_LOC})` : digUnit.name;
      }

      return this.loadLocation ? this.loadLocation.name : NO_LOC;
    },
    assignedHaulTrucks() {
      return this.haulTrucks.filter(h => {
        const dispatch = h.dispatch || {};
        return (
          dispatch.digUnitId === this.digUnitId &&
          dispatch.loadId === this.loadId &&
          this.dumpIds.includes(dispatch.dumpId)
        );
      });
    },
    cols() {
      const columns = this.columns || 2;
      return columns < 1 ? 1 : columns;
    },
    minWidthStyle() {
      return `min-width: ${this.cols * 7 + 1}rem;`;
    },
  },
  methods: {
    getChildPayload() {
      this.draggingDigUnit = true;
      this.$emit('drag-start', this.digUnit);
      return this.digUnit;
    },
    shouldAcceptIntoDigUnit(asset) {
      const doesNotHaveDigUnit = !this.digUnitId;
      const isDigUnit = asset && asset.secondaryType === 'Dig Unit';
      const assignedHaulTruckCount = this.haulTrucks.filter(
        h => (h.dispatch || {}).digUnitId === asset.id,
      ).length;

      return doesNotHaveDigUnit && isDigUnit && assignedHaulTruckCount === 0;
    },
    onDropIntoDigUnit({ addedIndex, removedIndex, payload }) {
      // is added
      if (addedIndex !== null && removedIndex === null) {
        const change = {
          digUnitId: payload.id,
          loadId: this.loadId,
          dumpIds: this.dumpIds,
        };
        this.$emit('set-dig-unit', change);
      }
    },
    onDragStart(asset) {
      this.$emit('drag-start', asset);
    },
    onDragEnd() {
      this.draggingDigUnit = false;
      this.$emit('drag-end');
    },
    onSetHaulTruck(digUnitId, loadId, dumpId, asset) {
      this.$emit('set-haul-truck', { digUnitId, loadId, dumpId, asset });
    },
    onRemoveRoute() {
      const payload = { digUnitId: this.digUnitId, loadId: this.loadId };
      this.$emit('remove-route', payload);
    },
    onClearRoute() {
      const payload = { digUnitId: this.digUnitId, loadId: this.loadId };
      this.$emit('clear-route', payload);
    },
    onRequestAddDump() {
      const payload = { digUnitId: this.digUnitId, loadId: this.loadId };
      this.$emit('request-add-dump', payload);
    },
    onRemoveDump(dumpId) {
      const payload = { digUnitId: this.digUnitId, loadId: this.loadId, dumpId };
      this.$emit('remove-dump', payload);
    },
    onClearDump(dumpId) {
      const payload = { digUnitId: this.digUnitId, loadId: this.loadId, dumpId };
      this.$emit('clear-dump', payload);
    },
    onMoveTrucks({ dumpId, assetIds }) {
      console.dir('--- move trucks')
      const payload = { digUnitId: this.digUnitId, loadId: this.loadId, dumpId, assetIds };
      this.$emit('move-trucks', payload);
    },
    onMoveDumps() {
      const payload = { digUnitId: this.digUnitId, loadId: this.loadId, dumpIds: this.dumpIds };
      this.$emit('move-dumps', payload);
    },
  },
};
</script>

<style>
.route-v .dig-unit-tile-wrapper .smooth-dnd-container .tile-drop-preview {
  border: 1px dashed grey;
  height: 7rem;
  width: 7rem;
  background-color: rgba(150, 150, 200, 0.1);
}
</style>

<style scoped>
.heading {
  cursor: pointer;
  height: 2.25rem;
  line-height: 2.25rem;
  font-size: 1.5rem;
  padding: 0.25rem 1rem;
  text-align: center;
  background-color: #23343f;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
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

.target-load {
  background-color: #111c22;
}

.target-load .dig-unit-tile-wrapper {
  display: flex;
  justify-content: center;
  height: 8rem;
}

.target-load .dig-unit-tile-wrapper .dig-unit-container {
  width: 7rem;
  min-height: 8rem;
  margin: auto;
}

.target-load .dig-unit-tile-wrapper .empty .dig-unit-container {
  border: 1px dashed rgb(66, 66, 66);
}

.target-load .dig-unit-tile-wrapper .dig-unit-container :not([disabled]) .asset-tile {
  cursor: move;
}

/* actions */
.target-load .actions {
  height: 2rem;
  width: 100%;
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
}

.target-load .actions .hx-icon {
  cursor: pointer;
  padding: 0.4rem 0;
}

.target-load .actions .add:hover {
  stroke: green;
}

.target-load .actions .remove:hover {
  stroke: red;
}

.target-load .actions .clear:hover {
  stroke: red;
}

/* --- dumps ---- */
.dumps {
  display: flex;
  justify-content: center;
}

.dumps .dump-v {
  border-left: 1px solid #23343f;
  border-right: 1px solid #23343f;
  margin: 0 0.25rem;
}
</style>