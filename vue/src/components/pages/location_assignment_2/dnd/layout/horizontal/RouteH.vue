<template>
  <div class="route-h">
    <div class="target-load">
      <!-- adding a location edit to here could be good, but also quite complicated -->
      <div class="heading">
        <div class="title">{{ heading }}</div>
        <!-- may want to simply make the heading itself be a clickable button -->
        <Icon class="edit-icon" :icon="editIcon" />
      </div>
      <div class="dig-unit-region">
        <div class="actions">
          <template v-if="hovering" @mouseenter="hovering = true" @mouseleave="hovering = false">
            <Icon
              v-if="assignedHaulTrucks.length === 0"
              v-tooltip="'Clear All'"
              class="clear"
              :icon="trashIcon"
            />
            <Icon v-else v-tooltip="'Remove'" class="remove" :icon="crossIcon" />

            <Icon v-tooltip="'Add Dump'" class="add" :icon="addIcon" />
          </template>
        </div>
        <div class="dig-unit-tile-wrapper">
          <AssetTile
            v-if="digUnit"
            class="dig-unit-tile"
            :class="{ 'no-dig-unit': !digUnit }"
            :asset="digUnit"
          />
        </div>
      </div>
    </div>

    <div class="dumps">
      <DumpH
        v-for="dumpId in dumpIds"
        :key="dumpId"
        :dumpId="dumpId"
        :haulTrucks="haulTrucks"
        :locations="locations"
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
    digUnit() {
      return this.digUnits.find(d => d.id === this.digUnitId);
    },
    loadLocation() {
      return this.locations.find(l => l.id === this.loadId);
    },
    heading() {
      const digUnit = this.digUnit;
      if (digUnit) {
        const digUnitLocName = attributeFromList(this.locations, 'id', digUnit.locationId, 'name');
        return digUnitLocName ? `${digUnit.name} (${digUnitLocName || NO_LOC})` : digUnit.name;
      }

      return this.loadLocation ? this.loadLocation.name : NO_LOC;
    },
    assignedHaulTrucks() {
      return this.haulTrucks.filter(h => {
        return (
          h.digUnitId === this.digUnitId &&
          h.loadId === this.loadId &&
          this.dumpIds.includes(h.dumpId)
        );
      });
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
  height: 2.25rem;
  font-size: 1.1rem;
  padding: 0.5rem 1rem;
  text-align: center;
  background-color: #23343f;
  display: flex;
}

.target-load .heading .title {
  height: 100%;
  width: 100%;
  line-height: 1.5rem;
}

.target-load .heading .edit-icon {
  cursor: pointer;
  height: 100%;
  padding: 1px;
  padding-bottom: 3px;
}

.target-load .heading .edit-icon:hover {
  stroke: orange;
}

.dig-unit-region {
  height: calc(100% - 2rem);
  background-color: #111c22;
}

.dig-unit-region .dig-unit-tile-wrapper {
  display: flex;
  height: calc(100% - 4rem);
}

.dig-unit-region .dig-unit-tile-wrapper .asset-tile {
  margin: auto;
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