<template>
  <div class="asset-status-page">
    <hxCard style="width: auto" title="Asset Status" :icon="truckIcon">
      <loaded>
        <table-component
          table-wrapper="#content"
          table-class="table"
          tbody-class="table-body"
          thead-class="table-head"
          filterNoResults="No Assets assigned to devices"
          :data="assets"
          :show-caption="false"
          :show-filter="false"
        >
          <table-column cell-class="table-cel" label="Asset" show="name" />

          <table-column
            cell-class="table-cel"
            label="Last Seen"
            show="lastSeen"
            data-type="date"
            :formatter="formatDate"
          />

          <table-column cell-class="gps-source-cel" label="GPS Source" show="gpsSource">
            <template slot-scope="row">
              <Icon v-tooltip="row.gpsSource" :icon="getSourceIcon(row.gpsSource)" />
            </template>
          </table-column>

          <table-column label="Radio Number" cell-class="table-cel">
            <template slot-scope="row">
              <input
                class="typeable"
                placeholder="Radio Number"
                type="number"
                v-model="row.radioNumber"
              />
            </template>
          </table-column>

          <table-column label :sortable="false" :filterable="false" cell-class="table-btn-cel">
            <template slot-scope="row">
              <a :id="`${row.id}`" @click="setRadioNumber(row)">Update</a>
            </template>
          </table-column>
        </table-component>
      </loaded>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import Loaded from '../../Loaded.vue';

import TruckIcon from '@/components/icons/asset_icons/HaulTruck.vue';
import TabletIcon from '@/components/icons/Tablet.vue';
import DatabaseIcon from '@/components/icons/Database.vue';

import { TableComponent, TableColumn } from 'vue-table-component';
import { formatDateRelativeToIn } from '@/code/time';
import { attributeFromList } from '@/code/helpers';

export default {
  name: 'AssetStatus',
  components: {
    hxCard,
    Icon,
    TableColumn,
    TableComponent,
    Loaded,
  },
  data: () => {
    return {
      truckIcon: TruckIcon,
    };
  },
  computed: {
    ...mapState({
      tracks: state => state.trackStore.tracks,
      radioNumbers: state => state.constants.radioNumbers,
      allAssets: state => state.constants.assets,
    }),
    assets() {
      const radioNumbers = this.radioNumbers;
      const tracks = this.tracks;
      return this.allAssets.map(asset => {
        const radioNumber = attributeFromList(radioNumbers, 'assetId', asset.id, 'number');
        const track = attributeFromList(tracks, 'assetId', asset.id);

        return {
          id: asset.id,
          name: asset.name,
          type: asset.type,
          radioNumber,
          lastSeen: track?.timestamp,
          gpsSource: track?.source,
        };
      });
    },
  },
  methods: {
    setRadioNumber(asset) {
      const payload = {
        asset_id: asset.id,
        radio_number: `${asset.radioNumber}`,
      };

      this.$channel
        .push('set radio number', payload)
        .receive('ok', () => this.$toaster.info('Radio number updated'))
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable update radio number'));
    },
    formatDate(date) {
      const tz = this.$timely.current.timezone;
      return formatDateRelativeToIn(date, tz);
    },
    getSourceIcon(source) {
      if (source === 'device') {
        return TabletIcon;
      }
      return DatabaseIcon;
    },
  },
};
</script>

<style>
@import '../../../assets/styles/table.css';
@import '../../../assets/styles/hxInput.css';
@import '../../../assets/styles/textColors.css';

.asset-status-page .gps-source-cel {
  width: 2rem;
}

.asset-status-page .gps-source-cel .hx-icon {
  width: auto;
}
</style>
