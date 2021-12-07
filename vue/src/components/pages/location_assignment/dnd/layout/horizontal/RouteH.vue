<template>
  <div class="route-h">
    <div class="target-load">
      <div v-tooltip="'Change Source'" class="heading" @click="onMoveDumps">
        {{ heading }}
      </div>
      <div class="dig-unit-region" @mouseenter="hovering = true" @mouseleave="hovering = false">
        <div class="actions">
          <template v-if="hovering">
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
                <Draggable>
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
      </div>
    </div>

    <div class="dumps">
      <DumpH
        v-for="dump in dumps"
        :key="dump.id"
        :dumpId="dump.id"
        :dumpName="dump.extendedName"
        :haulTrucks="assignedHaulTrucks"
        @drag-start="onDragStart"
        @drag-end="onDragEnd()"
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
import { Container, Draggable } from 'vue-smooth-dnd';

import AssetTile from '../../asset_tile/AssetTile.vue';
import DumpH from './DumpH.vue';

import TrashIcon from '@/components/icons/Trash.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import AddIcon from '@/components/icons/Add.vue';
import EditIcon from '@/components/icons/Edit.vue';
import { attributeFromList } from '@/code/helpers';

const NO_LOC = 'No Location';

export default {
  name: 'RouteH',
  components: {
    Icon,
    AssetTile,
    DumpH,
    Container,
    Draggable,
  },
  data: () => {
    return {
      editIcon: EditIcon,
      trashIcon: TrashIcon,
      crossIcon: CrossIcon,
      addIcon: AddIcon,
      hovering: false,
      dropPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
      draggingDigUnit: false,
    };
  },
  props: {
    digUnitId: { type: [String, Number] },
    loadId: { type: [String, Number] },
    dumpIds: { type: Array, default: () => [] },
    digUnits: { type: Array, default: () => [] },
    haulTrucks: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
  },
  computed: {
    dumps() {
      return this.locations
        .filter(l => this.dumpIds.includes(l.id))
        .sort((a, b) => a.name.localeCompare(b.name));
    },
    digUnit() {
      return this.digUnits.find(d => d.id === this.digUnitId);
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
.route-h .dig-unit-region .dig-unit-tile-wrapper .smooth-dnd-container .tile-drop-preview {
  border: 1px dashed grey;
  height: 7rem;
  width: 7rem;
  background-color: rgba(150, 150, 200, 0.1);
}
</style>

<style scoped>
.route-h {
  display: flex;
}

/* --- dig unit ---- */
.target-load {
  display: flex;
  flex-direction: column;
  border-right: 1px solid #121f26;
  min-width: 15rem;
}

.target-load .heading {
  cursor: pointer;
  height: 2.25rem;
  font-size: 1.1rem;
  padding: 0.5rem 1rem;
  text-align: center;
  background-color: #23343f;
}

.target-load .heading:hover {
  opacity: 0.75;
}

.dig-unit-region {
  height: calc(100% - 2rem);
  background-color: #111c22;
}

.dig-unit-region .dig-unit-tile-wrapper {
  display: flex;
  min-height: calc(100% - 4rem);
}

.dig-unit-region .dig-unit-tile-wrapper .dig-unit-tile {
  margin: auto;
}

.dig-unit-region .dig-unit-tile-wrapper .dig-unit-container {
  width: 7rem;
  min-height: 7rem;
  margin: auto;
}

.dig-unit-region .dig-unit-tile-wrapper .empty .dig-unit-container {
  border: 1px dashed rgb(66, 66, 66);
}

.dig-unit-region .dig-unit-tile-wrapper .dig-unit-container .asset-tile {
  cursor: move;
}

/* actions */
.dig-unit-region .actions {
  height: 2rem;
  min-width: 15rem;
  display: flex;
  flex-direction: row;
  justify-content: flex-end;
}

.dig-unit-region .actions .hx-icon {
  cursor: pointer;
  padding: 0.4rem 0;
}

.dig-unit-region .actions .add:hover {
  stroke: green;
}

.dig-unit-region .actions .remove:hover {
  stroke: red;
}

.dig-unit-region .actions .clear:hover {
  stroke: red;
}
</style>