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
            <span v-tooltip="acknowledgeTooltip(row)">
              <Icon :icon="manIcon" />
            </span>
          </span>
        </template>
      </table-column>

      <table-column cell-class="table-icon-cel">
        <template slot-scope="row">
          <span v-tooltip="{ content: presenceTooltip(row) }">
            <span :class="presenceIconColor(row)">
              <Icon :icon="truckIcon" />
            </span>
          </span>
        </template>
      </table-column>

      <table-column cell-class="table-cel" label="Operator" show="operator" />

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
            v-model="row.digUnitId"
            :items="digUnitsWithLocations"
            label="label"
            @change="setHaulTruckDispatch(row)"
          />
        </template>
      </table-column>

      <table-column label="Load Location" cell-class="table-cel">
        <template slot-scope="row">
          <DropDown
            v-model="row.loadId"
            :items="loadLocations"
            label="name"
            @change="setHaulTruckDispatch(row)"
          />
        </template>
      </table-column>

      <table-column label="Dump Location" cell-class="table-cel">
        <template slot-scope="row">
          <DropDown
            v-model="row.dumpId"
            :items="dumpLocations"
            label="name"
            @change="setHaulTruckDispatch(row)"
          />
        </template>
      </table-column>

      <table-column label :sortable="false" :filterable="false" cell-class="table-btn-cel">
        <template slot-scope="row">
          <a :id="`${row.device_id}`" @click="clearHaulTruckDispatch(row)">Clear</a>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import DropDown from '../../dropdown/DropDown.vue';
import TimeAllocationDropDown from '../../TimeAllocationDropDown.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import { toFullName, attributeFromList } from '../../../code/helpers';

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
    DropDown,
    TimeAllocationDropDown,
    TableComponent,
    TableColumn,
  },
  data: () => {
    return {
      truckIcon: TruckIcon,
      manIcon: ManIcon,
      editIcon: EditIcon,
    };
  },
  computed: {
    assets() {
      return this.$store.state.constants.assets;
    },
    haulTruckDispatches() {
      return this.$store.state.haulTruck.currentDispatches;
    },
    digUnits() {
      const activities = this.$store.state.digUnit.currentActivities;

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
            operator: asset.operator.fullname || '',
            digUnitId: dispatch.digUnitId,
            loadId: dispatch.loadId,
            dumpId: dispatch.dumpId,
            nextId: dispatch.nextId,
            acknowledged: dispatch.acknowledged,
            activeTimeAllocation: asset.activeTimeAllocation || {},
            present: asset.present,
          };
        });
    },
    digUnitsWithLocations() {
      const locations = this.$store.state.constants.locations;

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
    loadLocations() {
      return [noneLocation()].concat(this.$store.state.constants.loadLocations);
    },
    dumpLocations() {
      return [noneLocation()].concat(this.$store.state.constants.dumpLocations);
    },
    allowedTimeCodeIds() {
      return this.$store.getters['constants/fullTimeCodes']
        .filter(tc => tc.assetTypeNames.includes('Haul Truck'))
        .map(tc => tc.id);
    },
  },
  methods: {
    onEdit(row) {
      this.$eventBus.$emit('asset-assignment-open', row.assetId);
    },
    clearHaulTruckDispatch(haulTruck) {
      if (!haulTruck || (!haulTruck.loadId && !haulTruck.dumpId && !haulTruck.nextId)) {
        return;
      }

      const asset = {
        assetId: haulTruck.assetId,
        loadId: null,
        dumpId: null,
        nextId: null,
      };

      this.setHaulTruckDispatch(asset);
    },
    presenceTooltip(row) {
      const alloc = row.activeTimeAllocation;
      if (alloc.id) {
        return `${alloc.groupName} - ${alloc.name}`;
      }
      if (row.present) {
        return 'Active';
      }
      return 'Not Connected';
    },
    presenceIconColor(row) {
      if (row.activeTimeAllocation.id && !row.activeTimeAllocation.isReady) {
        return ['exception-icon'];
      }
      if (row.present === true) {
        return ['ok-icon'];
      }
      return ['offline-icon'];
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
        .receive('timeout', resp => this.$toaster.noComms('Unable to update allocation'));
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

.haul-truck-table .dropdown-wrapper {
  width: 100%;
  height: 2rem;
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
</style>