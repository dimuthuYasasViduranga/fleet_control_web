<template>
  <div>
    <hxCard style="width: auto" :title="title" :icon="truckIcon">
      <error :error="error" />
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

          <table-column cell-class="table-cel" label="Last Seen" :formatter="lastSeen" />

          <table-column cell-class="table-cel" label="Ignition" :formatter="ignition" />

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
import hxCard from 'hx-layout/Card.vue';
import error from 'hx-layout/Error.vue';
import Loaded from '../../Loaded.vue';

import TruckIcon from '../../icons/asset_icons/HaulTruck.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import { formatDateRelativeToIn } from './../../../code/time';
import { attributeFromList, copy } from '../../../code/helpers';

function getLastSeen(track) {
  if (!track) {
    return null;
  }
  return track.timestamp;
}

export default {
  name: 'AssetStatus',
  components: {
    hxCard,
    error,
    TableColumn,
    TableComponent,
    Loaded,
  },
  data: () => {
    return {
      title: 'Asset Status',
      truckIcon: TruckIcon,
      error: '',
    };
  },
  computed: {
    tracks() {
      return this.$store.state.trackStore.tracks;
    },
    assets() {
      const radioNumbers = this.$store.state.constants.radioNumbers;
      return this.$store.state.constants.assets.map(asset => {
        const radioNumber = attributeFromList(radioNumbers, 'assetId', asset.id, 'number');
        return {
          id: asset.id,
          name: asset.name,
          type: asset.type,
          radioNumber,
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
    ignition(asset) {
      const track = this.tracks.find(t => t.assetId === asset.id);

      switch ((track || {}).ignition) {
        case true:
          return '<span class="green-text">On</span>';
        case false:
          return '<span class="red-text">Off</span>';
        default:
          return '--';
      }
    },
    lastSeen(asset) {
      const track = this.tracks.find(t => t.assetId === asset.id);
      const lastSeen = getLastSeen(track);
      if (lastSeen) {
        const tz = this.$timely.current.timezone;
        return formatDateRelativeToIn(lastSeen, tz);
      }
      return '--';
    },
  },
};
</script>

<style>
@import '../../../assets/table.css';
@import '../../../assets/hxInput.css';
@import '../../../assets/textColors.css';

.wrapper {
  display: flex;
}

.red-text {
  color: red;
}
</style>
