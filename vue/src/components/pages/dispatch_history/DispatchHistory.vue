<template>
  <div class="dispatch-history">
    <hxCard style="width: auto" :title="title" :icon="icon">
      <error :error="error" />
      <loaded>
        <table-component
          table-wrapper="#content"
          table-class="table"
          filterNoResults="No information to display"
          :data="dispatchHistory"
          :show-caption="false"
          sort-by="insertedAt"
        >
          <table-column cell-class="table-cel" label="Asset" show="assetName" :formatter="dash" />

          <table-column cell-class="table-cel" label="Load" show="loadLocation" :formatter="dash" />

          <table-column cell-class="table-cel" label="Dump" show="dumpLocation" :formatter="dash" />

          <table-column
            cell-class="table-cel"
            label="Timestamp"
            show="timestamp"
            :formatter="formatRelative"
          />
        </table-component>
      </loaded>
    </hxCard>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';

import hxCard from 'hx-layout/Card.vue';
import error from 'hx-layout/Error.vue';
import Loaded from '../../Loaded.vue';

import BellIcon from '../../icons/Bell.vue';

import { formatDateRelativeToIn } from '@/code/time';
import { attributeFromList } from '@/code/helpers';

export default {
  name: 'DispatchHistory',
  components: {
    hxCard,
    error,
    TableColumn,
    TableComponent,
    Loaded,
  },
  data: () => {
    return {
      title: 'Dispatch History',
      icon: BellIcon,
      error: '',
    };
  },
  computed: {
    assets() {
      return this.$store.state.constants.assets;
    },
    operators() {
      return this.$store.state.constants.operators;
    },
    locations() {
      return this.$store.state.constants.locations;
    },
    dispatchHistory() {
      const dispatches = this.$store.state.haulTruck.historicDispatches.map(d => {
        const assetName = attributeFromList(this.assets, 'id', d.assetId, 'name');

        const loadLocation = this.getLocationName(this.locations, d.loadId);
        const dumpLocation = this.getLocationName(this.locations, d.dumpId);

        return {
          id: d.id,
          assetId: d.asset_id,
          assetName,
          loadLocation,
          dumpLocation,
          timestamp: d.timestamp,
          serverTimestamp: d.serverTimestamp,
        };
      });

      dispatches.sort((a, b) => b.timestamp - a.timestamp);

      return dispatches;
    },
  },
  methods: {
    dash(value) {
      return value || '--';
    },
    getLocationName(locations, id) {
      return attributeFromList(locations, 'id', id, 'name');
    },
    getOperatorName(operators, id) {
      return attributeFromList(operators, 'id', id, 'name');
    },
    formatRelative(date) {
      if (!date) {
        return '--';
      }
      const tz = this.$timely.current.timezone;
      return formatDateRelativeToIn(date, tz);
    },
  },
};
</script>

<style>
.dispatcher-messages .acknowledged {
  color: grey;
}
</style>
