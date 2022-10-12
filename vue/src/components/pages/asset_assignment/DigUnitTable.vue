<template>
  <div class="dig-unit-table">
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No dig units have been assigned to devices"
      :data="digUnits"
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

      <table-column label cell-class="table-icon-cel">
        <template slot-scope="row">
          <NIcon
            v-tooltip="{ content: presenceTooltip(row) }"
            class="asset-icon"
            :class="row.status"
            :icon="getIcon(row)"
            :secondaryIcon="getSecondaryIcon(row)"
          />
        </template>
      </table-column>

      <table-column cell-class="table-cel" label="Operator" show="operator" />

      <table-column label="Allocation" cell-class="table-cel">
        <template slot-scope="row">
          <TimeAllocationDropDown
            :value="row.activeTimeAllocation.timeCodeId"
            :allowedTimeCodeIds="getAllowedTimeCodeIds(row.assetTypeId)"
            @change="setTimeAllocation(row, $event)"
          />
        </template>
      </table-column>

      <table-column label="Location" cell-class="table-cel">
        <template slot-scope="row">
          <DropDown
            v-tooltip="
              row.hasInactiveLocation ? 'Location is no longer active. Please re-assign' : ''
            "
            :class="{ 'inactive-location': row.hasInactiveLocation }"
            value-is-id
            v-model="row.locationId"
            :options="row.locationOptions"
            label="name"
            :disabled="readonly"
            @change="setActivity(row)"
          />
        </template>
      </table-column>

      <table-column label="Material Type" cell-class="table-cel">
        <template slot-scope="row">
          <DropDown
            v-model="row.materialTypeId"
            :options="materialTypeOptions"
            label="commonName"
            placeholder="None"
            :disabled="readonly"
            @change="setActivity(row)"
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
          <a :id="`${row.device_id}`" @click="onClearActivity(row)">Clear</a>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import { mapState } from 'vuex';

import NIcon from '@/components/NIcon.vue';
import Icon from 'hx-layout/Icon.vue';
import { DropDown } from 'hx-vue';
import TimeAllocationDropDown from '../../TimeAllocationDropDown.vue';
import { TableComponent, TableColumn } from 'vue-table-component';

import { attributeFromList } from '@/code/helpers';
import { getAssetTileSecondaryIcon } from '@/code/common';

import EditIcon from '@/components/icons/Edit.vue';

function toDigUnit(asset, activities, dimLocations, locationOpts) {
  const activity = attributeFromList(activities, 'assetId', asset.id) || {};

  const [hasInactiveLocation, locationOptions] = getLocationOptions(
    locationOpts,
    activity.locationId,
    dimLocations,
  );

  return {
    assetId: asset.id,
    assetName: asset.name,
    assetType: asset.type,
    assetTypeId: asset.typeId,
    operator: asset.operator.fullname || '',
    locationId: activity.locationId,
    materialTypeId: activity.materialTypeId,
    loadStyleId: activity.loadStyleId,
    activeTimeAllocation: asset.activeTimeAllocation,
    present: asset.present,
    status: asset.status,
    hasDevice: asset.hasDevice,
    locationOptions,
    hasInactiveLocation,
  };
}

function getLocationOptions(options, locationId, dimLocations) {
  if (!locationId || options.find(o => o.id === locationId)) {
    return [false, options];
  }

  const name = attributeFromList(dimLocations, 'id', locationId, 'name');

  const opts = options.slice();
  opts.push({ id: locationId, name });
  return [true, opts];
}

export default {
  name: 'DigUnitTable',
  components: {
    NIcon,
    Icon,
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
      editIcon: EditIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      icons: state => state.icons,
      dimLocations: state => state.dimLocations,
      locations: state => state.locations,
      materialTypes: state => state.materialTypes,
    }),
    ...mapState('digUnit', {
      digUnitActivities: state => state.currentActivities,
    }),
    locationOptions() {
      const locations = this.locations.map(l => ({ id: l.id, name: l.name }));
      return [{ id: null, name: 'None' }].concat(locations);
    },
    materialTypeOptions() {
      return [{ id: null, commonName: 'None' }].concat(this.materialTypes);
    },
    digUnits() {
      const activities = this.digUnitActivities;
      return this.$store.getters.fullAssets
        .filter(fa => fa.secondaryType === 'Dig Unit')
        .map(asset => toDigUnit(asset, activities, this.dimLocations, this.locationOptions));
    },
    fullTimeCodes() {
      return this.$store.getters['constants/fullTimeCodes'];
    },
  },
  methods: {
    onEdit(row) {
      this.$eventBus.$emit('asset-assignment-open', row.assetId);
    },
    getIcon(row) {
      return this.icons[row.assetType];
    },
    getSecondaryIcon(asset) {
      return getAssetTileSecondaryIcon(asset);
    },
    getAllowedTimeCodeIds(assetTypeId) {
      return this.fullTimeCodes
        .filter(tc => tc.assetTypeIds.includes(assetTypeId))
        .map(tc => tc.id);
    },
    presenceTooltip(row) {
      const alloc = row.activeTimeAllocation;
      if (alloc.id) {
        return `${alloc.groupAlias || alloc.groupName} - ${alloc.name}`;
      }
      if (!row.hasDevice) {
        return 'No tablet assigned!';
      }
      if (row.present) {
        return 'Active';
      }
      return 'Not Connected';
    },
    onClearActivity(asset) {
      asset.locationId = null;
      asset.materialTypeId = null;
      asset.loadStyleId = null;
      this.setActivity(asset);
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
        .push('time-allocation:set', payload)
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to update allocation'));
    },
    setActivity(asset) {
      const activity = {
        asset_id: asset.assetId,
        location_id: asset.locationId || null,
        material_type_id: asset.materialTypeId || null,
        load_style_id: asset.loadStyleId || null,
        timestamp: Date.now(),
      };

      this.$channel
        .push('dig:set activity', activity)
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to update activity'));
    },
  },
};
</script>

<style>
.dig-unit-table .table-icon-cel {
  width: 0.1em;
}

.dig-unit-table .dropdown-wrapper {
  width: 100%;
  height: 2rem;
}

.dig-unit-table .table-edit-cel {
  width: 2rem;
}

.dig-unit-table .table-edit-cel .hx-icon {
  width: 1.25rem;
  cursor: pointer;
}

.dig-unit-table .table-edit-cel .hx-icon:hover {
  stroke: orange;
}

.dig-unit-table .asset-icon {
  width: 2.5rem;
}

.dig-unit-table .drop-down.inactive-location {
  border: 2px solid #ff6565;
}
</style>