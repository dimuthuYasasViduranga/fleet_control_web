<template>
  <div class="cycle-tally-table">
    <loaded>
      <table-component
        table-wrapper="#content"
        table-class="table"
        filterNoResults="No information to display"
        :data="localCycles"
        :show-caption="false"
        :show-filter="false"
        sort-by="startTimeEpoch"
        :cache-lifetime="0"
        sort-order="desc"
      >
        <table-column
          cell-class="table-cel"
          label="Start"
          show="startTimeEpoch"
          :formatter="relativeFormatter"
        />
        <table-column
          cell-class="table-cel"
          label="End"
          show="endTimeEpoch"
          :formatter="relativeFormatter"
        />

        <table-column cell-class="table-cel" label="Asset" show="asset" />
        <table-column cell-class="table-cel" label="Operator" show="operator" />
        <table-column cell-class="table-cel" label="Load Unit" show="loadUnit" />
        <table-column cell-class="table-cel" label="Material" show="materialType" />
        <table-column cell-class="table-cel" label="Load" show="loadLocation" />
        <table-column cell-class="table-cel" label="RL" show="relativeLevel" />
        <table-column cell-class="table-cel" label="Shot" show="shot" />
        <table-column cell-class="table-cel" label="Dump" show="dumpLocation" />
        <table-column cell-class="table-cel actions-cell" label="">
          <template slot-scope="row">
            <div class="actions">
              <Icon
                class="header-icon edit-icon"
                :icon="editIcon"
                v-tooltip="{ content: 'Edit' }"
                @click="onEdit(row)"
              />
              <Icon v-tooltip="{ content: `Copy content` }" :icon="copyIcon" @click="onCopy(row)" />
              <Icon
                class="header-icon delete-icon"
                :icon="trashIcon"
                v-tooltip="{ content: 'Delete' }"
                @click="onDelete(row)"
              />
            </div>
          </template>
        </table-column>
      </table-component>
    </loaded>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import Loaded from '../../Loaded.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import { attributeFromList } from '../../../code/helpers';
import { copyDate, todayRelativeFormat } from '../../../code/time';
import EditIcon from '../../icons/Edit.vue';
import TrashIcon from '../../icons/Trash.vue';
import CopyIcon from '../../icons/Copy.vue';

export default {
  name: 'CycleTallyTable',
  components: {
    Loaded,
    TableComponent,
    TableColumn,
    Icon,
  },
  props: {
    cycles: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    materialTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      editIcon: EditIcon,
      trashIcon: TrashIcon,
      copyIcon: CopyIcon,
    };
  },
  computed: {
    localCycles() {
      return this.cycles.map(c => {
        const asset = attributeFromList(this.assets, 'id', c.assetId, 'name');
        const loadUnit = attributeFromList(this.assets, 'id', c.loadUnitId, 'name');
        const operator = attributeFromList(this.operators, 'id', c.operatorId, 'fullname');
        const loadLocation = attributeFromList(this.locations, 'id', c.loadLocationId, 'name');
        const dumpLocation = attributeFromList(this.locations, 'id', c.dumpLocationId, 'name');
        const materialType = attributeFromList(
          this.materialTypes,
          'id',
          c.materialTypeId,
          'commonName',
        );

        return {
          id: c.id,
          assetId: c.assetId,
          asset,
          operatorId: c.operatorId,
          operator,
          startTimeEpoch: c.startTime.getTime(),
          endTimeEpoch: c.endTime.getTime(),
          startTime: copyDate(c.startTime),
          endTime: copyDate(c.endTime),
          loadUnitId: c.loadUnitId,
          loadUnit,
          loadLocationId: c.loadLocationId,
          loadLocation,
          dumpLocationId: c.dumpLocationId,
          dumpLocation,
          relativeLevel: c.relativeLevel,
          shot: c.shot,
          materialTypeId: c.materialTypeId,
          materialType,
          deleted: c.deleted || false,
        };
      });
    },
  },
  methods: {
    relativeFormatter(date) {
      return todayRelativeFormat(new Date(date));
    },
    onEdit(cycle) {
      this.$emit('edit', cycle);
    },
    onDelete(cycle) {
      this.$emit('delete', cycle);
    },
    onCopy(cycle) {
      this.$emit('copy', cycle);
    },
  },
};
</script>

<style>
.cycle-tally-table .edit-icon:hover {
  stroke: orange;
}

.cycle-tally-table .actions-cell {
  max-width: 8rem;
}

.cycle-tally-table .actions {
  display: flex;
  justify-content: center;
}

.cycle-tally-table .actions .hx-icon {
  cursor: pointer;
  width: 1.5rem;
  margin: 0 0.5rem;
}
</style>