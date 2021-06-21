<template>
  <div class="dispatcher-messages">
    <hxCard style="width: auto" :title="title" :icon="icon">
      <error :error="error" />
      <Loaded>
        <table-component
          table-wrapper="#content"
          table-class="table"
          filterNoResults="No Messagse to display"
          :data="dispatcherMessages"
          :show-caption="false"
          sort-by="insertedAt"
        >
          <table-column cell-class="table-cel" label="Asset" show="assetName" />

          <table-column cell-class="table-cel" label="Radio Number" show="radioNumber" />

          <table-column cell-class="table-cel" label="Message" show="message" />

          <table-column cell-class="table-cel" label="Sent" show="insertedAt" :formatter="time" />

          <table-column
            cell-class="table-cel"
            label="Acknowledged At"
            show="acknowledgedAt"
            :formatter="time"
          />
        </table-component>
      </Loaded>
    </hxCard>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';

import hxCard from 'hx-layout/Card.vue';
import error from 'hx-layout/Error.vue';
import Loaded from '../../Loaded.vue';

import BellIcon from '../../icons/Bell.vue';

import { todayRelativeFormat } from './../../../code/time';

function getItemBtId(id, list) {
  const [item] = list.filter(i => i.id === id);
  return item;
}

function getNameById(id, list) {
  const item = getItemBtId(id, list);
  if (item === undefined) {
    return '';
  }
  return item.name;
}

function toDate(validDate) {
  if (!validDate) {
    return null;
  }
  return new Date(validDate);
}

export default {
  name: 'DispatcherMessages',
  components: {
    hxCard,
    error,
    TableColumn,
    TableComponent,
    Loaded,
  },
  data: () => {
    return {
      title: 'Dispatcher Messages',
      icon: BellIcon,
      error: '',
    };
  },
  computed: {
    assets() {
      const assets = this.$store.state.assets;
      return assets;
    },
    dispatcherMessages() {
      const messages = this.$store.state.dispatcherMessages;
      const assets = this.assets;

      const pairedMessages = messages.map(m => {
        const asset = assets.find(a => a.id === m.asset_id) || 'unknown';

        const insertedAtString = m.inserted_at ? `${m.inserted_at}Z` : null;

        return {
          id: m.id,
          acknowledged: m.acknowledged,
          assetId: m.asset_id,
          assetName: asset.name,
          radioNumber: asset.radio_number,
          message: m.message,
          insertedAt: toDate(insertedAtString),
          updatedAt: m.updated_at,
          acknowledgedAt: toDate(m.acknowledged_device_timestamp),
          acknowledgedAtServer: toDate(m.acknowledged_server_timestamp),
        };
      });

      pairedMessages.sort((a, b) => b.insertedAt - a.insertedAt);
      return pairedMessages;
    },
  },
  methods: {
    time(date) {
      if (!date) {
        return '--';
      }
      return todayRelativeFormat(date);
    },
  },
};
</script>

<style>
.dispatcher-messages .acknowledged {
  color: grey;
}
</style>
