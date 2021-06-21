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
          <AssetTile v-if="digUnit" class="dig-unit-tile" :asset="digUnit" />
          <div v-else class="no-dig-unit"></div>
        </div>
      </div>
    </div>

    <div class="dumps">
      <DumpH
        v-for="dump in dumps"
        :key="dump.id"
        :dumpId="dump.id"
        :dumpName="dump.name"
        :haulTrucks="assignedHaulTrucks"
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
  },
  data: () => {
    return {
      editIcon: EditIcon,
      trashIcon: TrashIcon,
      crossIcon: CrossIcon,
      addIcon: AddIcon,
      hovering: false,
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
      return this.dumpIds
        .map(id => {
          const name = attributeFromList(this.locations, 'id', id, 'name') || '';
          return { id, name };
        })
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
    onDragStart(asset) {
      this.$emit('drag-start', asset);
    },
    onDragEnd() {
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
  height: calc(100% - 4rem);
}

.dig-unit-region .dig-unit-tile-wrapper .dig-unit-tile {
  margin: auto;
}

.dig-unit-region .dig-unit-tile-wrapper .no-dig-unit {
  width: 6rem;
  height: 6rem;
  margin: auto;
  border: 1px dashed rgb(66, 66, 66);
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

/* --- dumps ---- */

.add-dump-icon {
  font-size: 1.5rem;
  line-height: 2.2rem;
  height: 2rem;
  width: 2rem;
  margin-top: 0.25rem;
  margin-right: 0.25rem;
  min-width: 0;
  padding: 0;
}

.add-dump-icon.wide {
  width: 100%;
  margin-left: 0.25rem;
}
</style>