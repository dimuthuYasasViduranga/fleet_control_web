<template>
  <div class="general-asset-table">
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No other assets have been assigned to devices"
      :data="assets"
      :show-caption="false"
      :show-filter="false"
      :cache-lifetime="0"
    >
      <table-column cell-class="table-edit-cel">
        <template slot-scope="row">
          <span>
            <Icon v-tooltip="'Edit'" :icon="editIcon" @click="onEdit(row)" />
          </span>
        </template>
      </table-column>

      <table-column cell-class="table-cel table-asset-cel" label="Asset" show="assetName" />

      <table-column label cell-class="table-icon-cel">
        <template slot-scope="row">
          <span v-tooltip="{ content: presenceTooltip(row) }">
            <div :class="presenceIconColor(row)">
              <NIcon
                class="asset-icon"
                :icon="getIcon(row)"
                :secondaryIcon="getSecondaryIcon(row)"
              />
            </div>
          </span>
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
    </table-component>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import NIcon from '@/components/NIcon.vue';
import Icon from 'hx-layout/Icon.vue';
import TimeAllocationDropDown from '@/components/TimeAllocationDropDown.vue';
import { TableComponent, TableColumn } from 'vue-table-component';

import EditIcon from '@/components/icons/Edit.vue';
import TabletIcon from '@/components/icons/Tablet.vue';

const TAKEN_TYPES = ['Haul Truck', 'Excavator', 'Loader'];

export default {
  name: 'GeneralAssetTable',
  components: {
    Icon,
    NIcon,
    TimeAllocationDropDown,
    TableComponent,
    TableColumn,
  },
  data: () => {
    return {
      editIcon: EditIcon,
      tabletIcon: TabletIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      icons: state => state.icons,
    }),
    fullTimeCodes() {
      return this.$store.getters['constants/fullTimeCodes'];
    },
    assets() {
      return this.$store.getters.fullAssets
        .filter(fa => !TAKEN_TYPES.includes(fa.type))
        .map(asset => {
          return {
            assetId: asset.id,
            assetName: asset.name,
            assetType: asset.type,
            assetTypeId: asset.typeId,
            operator: asset.operator.fullname || '',
            activeTimeAllocation: asset.activeTimeAllocation || {},
            present: asset.present,
            hasDevice: asset.hasDevice,
          };
        });
    },
  },
  methods: {
    onEdit(row) {
      this.$eventBus.$emit('asset-assignment-open', row.assetId);
    },
    getIcon(row) {
      return this.icons[row.assetType] || this.icons.Unknown;
    },
    getSecondaryIcon(row) {
      return row.hasDevice ? undefined : TabletIcon;
    },
    getAllowedTimeCodeIds(assetTypeId) {
      return this.fullTimeCodes
        .filter(tc => tc.assetTypeIds.includes(assetTypeId))
        .map(tc => tc.id);
    },
    presenceTooltip(row) {
      const alloc = row.activeTimeAllocation;
      if (!row.hasDevice) {
        return 'No tablet assigned!';
      }
      if (alloc.id) {
        return `${alloc.groupAlias || alloc.groupName} - ${alloc.name}`;
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
  },
};
</script>

<style>
.general-asset-table .dropdown-wrapper {
  min-width: 15rem;
  max-width: 30rem;
  height: 2rem;
}

.general-asset-table .table-icon-cel {
  width: 1rem;
}

.general-asset-table .table-edit-cel {
  width: 1rem;
}

.general-asset-table .table-edit-cel .hx-icon {
  width: 1.25rem;
  cursor: pointer;
}

.general-asset-table .table-edit-cel .hx-icon:hover {
  stroke: orange;
}

.general-asset-table .asset-icon {
  width: 2.5rem;
}

.general-asset-table .asset-icon .secondary-icon {
  stroke: orange;
  stroke-dasharray: 1;
}
</style>