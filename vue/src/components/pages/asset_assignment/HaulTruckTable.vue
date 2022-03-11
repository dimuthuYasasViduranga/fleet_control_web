<template>
  <div class="haul-truck-table">
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No haul trucks have been assigned to devices"
      :data="haulTrucks"
      :show-caption="false"
      :show-filter="false"
    >
      <table-column cell-class="table-edit-cel">
        <template slot-scope="row">
          <span>
            <Icon v-tooltip="'Edit'" :icon="editIcon" @click="onEdit(row)" />
          </span>
        </template>
      </table-column>

      <table-column cell-class="table-cel" label="Asset" show="assetName" />

      <table-column cell-class="table-icon-cel">
        <template slot-scope="row">
          <span :class="acknowledgeIconColor(row)">
            <Icon v-tooltip="acknowledgeTooltip(row)" :icon="manIcon" />
          </span>
        </template>
      </table-column>

      <table-column cell-class="table-icon-cel">
        <template slot-scope="row">
          <NIcon
            v-tooltip="{ content: presenceTooltip(row) }"
            class="asset-icon"
            :class="row.status"
            :icon="truckIcon"
            :secondaryIcon="getSecondaryIcon(row)"
          />
        </template>
      </table-column>

      <table-column cell-class="table-cel" label="Operator" show="operatorName" />

      <table-column label="Allocation" cell-class="table-cel">
        <template slot-scope="row">
          <TimeAllocationDropDown
            :value="row.activeTimeAllocation.timeCodeId"
            :allowedTimeCodeIds="allowedTimeCodeIds"
            @change="setTimeAllocation(row, $event)"
          />
        </template>
      </table-column>

      <table-column label="Dig Unit (location)" cell-class="table-cel">
        <template slot-scope="row">
          <DropDown
            :value="row.digUnitId"
            :options="digUnitsWithLocations"
            label="label"
            :disabled="readonly"
            @change="setDigUnitId(row, $event)"
          />
        </template>
      </table-column>

      <table-column label="Load Location" cell-class="table-cel">
        <template slot-scope="row">
          <DropDown
            :value="row.loadId"
            :options="loadLocationOptions"
            label="name"
            :disabled="readonly"
            @change="setLoadId(row, $event)"
          />
        </template>
      </table-column>

      <table-column label="Dump Location" cell-class="table-cel">
        <template slot-scope="row">
          <DropDown
            v-model="row.dumpId"
            :options="dumpLocationOptions"
            label="name"
            :disabled="readonly"
            @change="setHaulTruckDispatch(row)"
          />
        </template>
      </table-column>

      <table-column
        label
        :sortable="false"
        :filterable="false"
        cell-class="table-btn-cel"
        :hidden="readonly"
      >
        <template slot-scope="row">
          <a :id="`${row.device_id}`" @click="clearHaulTruckDispatch(row)">Clear</a>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import { DropDown } from 'hx-vue';
import NIcon from '@/components/NIcon.vue';
import TimeAllocationDropDown from '../../TimeAllocationDropDown.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import { attributeFromList } from '@/code/helpers';
import { getAssetTileSecondaryIcon } from '@/code/common';

import ManIcon from '../../icons/Man.vue';
import EditIcon from '../../icons/Edit.vue';
import TruckIcon from '../../icons/asset_icons/HaulTruck.vue';

function noneLocation() {
  return {
    id: null,
    name: 'None',
  };
}

export default {
  name: 'HaulTruckTable',
  components: {
    Icon,
    NIcon,
    DropDown,
    TimeAllocationDropDown,
    TableComponent,
    TableColumn,
  },
  props: {
    readonly: Boolean,
  },
  data: () => {
    return {
      truckIcon: TruckIcon,
      manIcon: ManIcon,
      editIcon: EditIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      locations: state => state.locations,
      loadLocations: state => state.loadLocations,
      dumpLocations: state => state.dumpLocations,
    }),
    ...mapState({
      haulTruckDispatches: state => state.haulTruck.currentDispatches,
      digUnitActivities: state => state.digUnit.currentActivities,
    }),
    digUnits() {
      const activities = this.digUnitActivities;

      return this.assets
        .filter(a => a.secondaryType === 'Dig Unit')
        .map(a => {
          const activity = attributeFromList(activities, 'assetId', a.id) || {};
          return { ...a, activity: { ...activity } };
        });
    },
    haulTrucks() {
      const dispatches = this.haulTruckDispatches;
      return this.$store.getters.fullAssets
        .filter(fa => fa.type === 'Haul Truck' && fa.hasDevice)
        .map(asset => {
          const dispatch = attributeFromList(dispatches, 'assetId', asset.id) || {};
          return {
            assetId: asset.id,
            assetName: asset.name,
            operator: asset.operator,
            operatorName: asset.operator.fullname || '',
            digUnitId: dispatch.digUnitId,
            loadId: dispatch.loadId,
            dumpId: dispatch.dumpId,
            nextId: dispatch.nextId,
            acknowledged: dispatch.acknowledged,
            activeTimeAllocation: asset.activeTimeAllocation || {},
            present: asset.present,
            status: asset.status,
            hasDevice: asset.hasDevice,
          };
        });
    },
    digUnitsWithLocations() {
      const locations = this.locations;

      const options = this.digUnits
        .map(d => {
          const locationId = (d.activity || {}).locationId;
          const locName = attributeFromList(locations, 'id', locationId, 'name');

          const label = locName ? `${d.name} (${locName})` : d.name;
          return {
            id: d.id,
            name: d.name,
            label,
          };
        })
        .sort((a, b) => a.name.localeCompare(b.name));

      return [{ id: null, label: 'None' }].concat(options);
    },
    loadLocationOptions() {
      return [noneLocation()].concat(this.loadLocations);
    },
    dumpLocationOptions() {
      return [noneLocation()].concat(this.dumpLocations);
    },
    allowedTimeCodeIds() {
      return this.$store.getters['constants/fullTimeCodes']
        .filter(tc => tc.assetTypeNames.includes('Haul Truck'))
        .map(tc => tc.id);
    },
  },
  methods: {
    getSecondaryIcon(asset) {
      return getAssetTileSecondaryIcon(asset);
    },
    onEdit(row) {
      this.$eventBus.$emit('asset-assignment-open', row.assetId);
    },
    clearHaulTruckDispatch(haulTruck) {
      if (!haulTruck || !(haulTruck.digUnitId || haulTruck.loadId || haulTruck.dumpId)) {
        return;
      }

      const asset = {
        assetId: haulTruck.assetId,
        digUnitId: null,
        loadId: null,
        dumpId: null,
      };

      this.setHaulTruckDispatch(asset);
    },
    presenceTooltip(row) {
      const alloc = row.activeTimeAllocation;
      if (alloc.id) {
        return `${alloc.groupAlias || alloc.groupName} - ${alloc.name}`;
      }
      if (row.present) {
        return 'Active';
      }
      return 'Not Connected';
    },
    acknowledgeTooltip(row) {
      if (row.acknowledged === true) {
        return 'Operator has responded';
      }
      return 'Waiting for operator response';
    },
    acknowledgeIconColor(row) {
      if (row.acknowledged === true) {
        return { 'green-icon': true };
      }
      return { 'orange-icon': true };
    },
    setTimeAllocation(row, timeCodeId) {
      const payload = {
        asset_id: row.assetId,
        time_code_id: timeCodeId,
        start_time: Date.now(),
        end_time: null,
        deleted: false,
      };

      this.$channel
        .push('set allocation', payload)
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to update allocation'));
    },
    setDigUnitId(row, assetId) {
      row.loadId = null;
      row.digUnitId = assetId;
      this.setHaulTruckDispatch(row);
    },
    setLoadId(row, locationId) {
      row.loadId = locationId;
      row.digUnitId = null;
      this.setHaulTruckDispatch(row);
    },
    setHaulTruckDispatch(asset) {
      const dispatch = {
        asset_id: asset.assetId,
        dig_unit_id: asset.digUnitId,
        load_location_id: asset.loadId,
        dump_location_id: asset.dumpId,
        timestamp: Date.now(),
      };

      this.$channel
        .push('haul:set dispatch', dispatch)
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to update dispatch'));
    },
  },
};
</script>

<style>
.haul-truck-table .table-icon-cel {
  width: 0.1em;
}

.haul-truck-table .table-edit-cel {
  width: 2rem;
}

.haul-truck-table .table-edit-cel .hx-icon {
  width: 1.25rem;
  cursor: pointer;
}

.haul-truck-table .table-edit-cel .hx-icon:hover {
  stroke: orange;
}

.haul-truck-table .asset-icon {
  width: 2.5rem;
}
</style>