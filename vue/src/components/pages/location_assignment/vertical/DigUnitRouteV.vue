<template>
  <div class="dig-unit-route-v">
    <div class="load-location">{{ locationName || '--' }}</div>

    <div
      class="dig-unit"
      :style="minWidthStyle"
      @mouseenter="hovering = true"
      @mouseleave="hovering = false"
    >
      <div class="asset-tile-wrapper">
        <AssetTile
          v-if="digUnit.id"
          class="dig-unit-tile"
          :class="{ 'no-dig-unit': !digUnit.id }"
          :asset="digUnit"
        />
      </div>
      <div class="actions">
        <template v-if="hovering">
          <Icon
            v-if="digUnitHaulTrucks.length"
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

          <Icon v-tooltip="'Add Dump'" class="add" :icon="addIcon" @click="onSelectDump" />
        </template>
      </div>
    </div>

    <div class="dumps">
      <DigUnitDumpV
        v-for="dump in dumps"
        :key="dump.id"
        :digUnitId="digUnitId"
        :dumpId="dump.id"
        :dumpName="dump.name"
        :locations="locations"
        :haulTrucks="digUnitHaulTrucks"
        :columns="cols"
        @drag-start="onDragStart"
        @drag-end="onDragEnd"
        @add="onAddHaulTruck(digUnitId, dump.id, $event)"
        @remove-dump="onRemoveDump(dump.id)"
        @clear-dump="onClearDump(dump.id)"
        @move-dump="onMoveDump(dump.id)"
      />
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { Container, Draggable } from 'vue-smooth-dnd';
import AssetTile from './../AssetTile.vue';
import DigUnitDumpV from './DigUnitDumpV.vue';
import DropDown from '@/components/dropdown/DropDown.vue';

import TrashIcon from '@/components/icons/Trash.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import AddIcon from '@/components/icons/Add.vue';
import { attributeFromList } from '@/code/helpers';

export default {
  name: 'DigUnitRouteV',
  components: {
    Icon,
    Container,
    Draggable,
    AssetTile,
    DigUnitDumpV,
    DropDown,
  },
  props: {
    digUnitId: { type: [Number, String], default: null },
    dumpIds: { type: Array, default: () => [] },
    digUnits: { type: Array, default: () => [] },
    haulTrucks: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    columns: { type: Number, default: 2 },
  },
  data: () => {
    return {
      addIcon: AddIcon,
      trashIcon: TrashIcon,
      crossIcon: CrossIcon,
      hovering: false,
    };
  },
  computed: {
    digUnit() {
      return this.digUnits.find(a => a.id === this.digUnitId) || {};
    },
    digUnitHaulTrucks() {
      return this.haulTrucks.filter(h => h.dispatch.digUnitId === this.digUnitId);
    },
    locationName() {
      const locationId = (this.digUnit.activity || {}).locationId;
      return attributeFromList(this.locations, 'id', locationId, 'name');
    },
    dumps() {
      const dumps = this.dumpIds.map(id => {
        return {
          id,
          name: attributeFromList(this.locations, 'id', id, 'name') || '',
        };
      });
      dumps.sort((a, b) => a.name.localeCompare(b.name));
      return dumps;
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
    onDragStart(asset) {
      this.$emit('drag-start', asset);
    },
    onDragEnd() {
      this.$emit('drag-end');
    },
    onAddHaulTruck(digUnitId, dumpId, asset) {
      this.$emit('set-haul-truck', { digUnitId, dumpId, asset });
    },
    onSelectDump() {
      this.$emit('select-dump');
    },
    onRemoveRoute() {
      this.$emit('remove-dig-unit', this.digUnitId);
    },
    onClearRoute() {
      this.$emit('clear-dig-unit', this.digUnitId);
    },
    onRemoveDump(dumpId) {
      this.$emit('remove-dump', dumpId);
    },
    onClearDump(dumpId) {
      this.$emit('clear-dump', dumpId);
    },
    onMoveDump(dumpId) {
      this.$emit('move-dump', dumpId);
    },
  },
};
</script>

<style scoped>
.load-location {
  height: 2.25rem;
  line-height: 2.25rem;
  font-size: 1.5rem;
  padding: 0.25rem 1rem;
  text-align: center;
  background-color: #23343f;
}

/* --- dig unit ---- */

.dig-unit {
  background-color: #111c22;
}

.dig-unit .asset-tile-wrapper {
  display: flex;
  justify-content: center;
}

/* actions */
.dig-unit .actions {
  height: 2rem;
  width: 100%;
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
}

.dig-unit .actions .hx-icon {
  cursor: pointer;
  padding: 0.4rem 0;
}

.dig-unit .actions .add:hover {
  stroke: green;
}

.dig-unit .actions .remove:hover {
  stroke: red;
}

.dig-unit .actions .clear:hover {
  stroke: red;
}

/* --- dumps ---- */
.dumps {
  display: flex;
  justify-content: center;
}

.dig-unit-dump-v {
  border-left: 1px solid #23343f;
  border-right: 1px solid #23343f;
  margin: 0 0.25rem;
}

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