<template>
  <div class="asset-roster-page">
    <hxCard title="Available Assets" :icon="haulTruckIcon">
      <table-component
        table-wrapper="#content"
        table-class="table"
        tbody-class="table-body"
        thead-class="table-head"
        filterNoResults="No Assets Available"
        :data="assets"
        :show-caption="false"
        :show-filter="true"
        sort-by="formattedDeviceName"
      >
        <table-column cell-class="table-icon-cel">
          <template slot-scope="row">
            <div class="icon-wrapper">
              <Icon :icon="getIcon(row)" />
            </div>
          </template>
        </table-column>

        <table-column cell-class="table-cel" label="Asset" show="name" />

        <table-column cell-class="table-cel" label="Type" show="type" />

        <table-column
          label="Enabled"
          :sortable="false"
          :filterable="false"
          cell-class="table-btn-cel action-cel"
        >
          <template slot-scope="row">
            <toggle-button
              :css-colors="true"
              :value="row.enabled"
              :sync="true"
              @input="onToggle(row, $event)"
            />
          </template>
        </table-column>
      </table-component>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { TableComponent, TableColumn } from 'vue-table-component';
import { ToggleButton } from 'vue-js-toggle-button';

import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';

import ConfirmModal from '@/components/modals/ConfirmModal.vue';

import HaulTruckIcon from '@/components/icons/asset_icons/HaulTruck.vue';

export default {
  name: 'AssetRoaster',
  components: {
    hxCard,
    Icon,
    TableComponent,
    TableColumn,
    ToggleButton,
  },
  data: () => {
    return {
      haulTruckIcon: HaulTruckIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets.slice().sort((a, b) => a.name.localeCompare(b.name)),
      assetIcons: state => state.icons,
    }),
  },
  methods: {
    getIcon(asset) {
      return this.assetIcons[asset.type] || this.assetIcons.Unknown;
    },
    onToggle(asset, bool) {
      if (!asset.enabled) {
        this.setEnabled(asset, bool);
        return;
      }

      const opts = {
        title: 'Disable Asset?',
        body: 'Are you sure you want to hide this asset from FleetControl?\nAll assignments and time allocations will be removed until it is re-enabled',
      };

      this.$modal.create(ConfirmModal, opts).onClose(answer => {
        if (answer === 'ok') {
          this.setEnabled(asset, bool);
        }
      });
    },
    setEnabled(asset, bool) {
      const payload = {
        asset_id: asset.id,
        state: bool,
      };
      this.$channel
        .push('asset:set enabled', payload)
        .receive('ok', () => {
          const stateName = bool ? 'Enabled' : 'Disabled';
          asset.enabled = bool;
          this.$toaster.info(`${asset.name} | ${stateName}`);
        })
        .receive('error', error => this.$toaster.error(error.error))
        .receive('timeout', () => {
          const stateName = bool ? 'enable' : 'isable';

          this.$toaster.noComms(`${asset.name} | Unable to ${stateName} asset at this time`);
        });
    },
  },
};
</script>

<style>
.asset-roster-page .hxCard {
  padding-bottom: 2rem;
}
.asset-roster-page .table-btn-cel {
  text-align: center;
}

.asset-roster-page .action-cel {
  min-width: 6rem;
}

.asset-roster-page .icon-wrapper {
  display: flex;
  justify-content: center;
}

.asset-roster-page .table-icon-cel {
  width: 0.1rem;
}
</style>