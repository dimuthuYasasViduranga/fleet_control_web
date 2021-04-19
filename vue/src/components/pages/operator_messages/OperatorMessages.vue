<template>
  <div class="operator-messages">
    <hxCard style="width: auto" :title="title" :icon="icon">
      <error :error="error" />

      <loaded>
        <table-component
          table-wrapper="#content"
          table-class="table"
          filterNoResults="No information to display"
          :data="operatorMessages"
          :show-caption="false"
        >
          <table-column cell-class="table-cel" label="Operator" show="operatorFullname" />

          <table-column cell-class="table-cel" label="Asset" show="assetName" />

          <table-column cell-class="table-cel" label="Radio Number" show="radioNumber" />

          <table-column cell-class="table-cel" label="Message" show="message" />

          <table-column
            cell-class="table-cel"
            label="Time"
            show="serverTimestamp"
            :formatter="time"
          />

          <table-column cell-class="table-cel" :sortable="false" :filterable="false">
            <template slot-scope="row">
              <span v-if="!row.acknowledged">
                <a :id="row.id" @click="onAcknowledge(row)">Acknowledge</a>
              </span>
              <span v-else class="acknowledged"> Acknowledged </span>
            </template>
          </table-column>
        </table-component>
      </loaded>
    </hxCard>
  </div>
</template>

<script type="text/javascript">
import { TableComponent, TableColumn } from 'vue-table-component';

import hxCard from 'hx-layout/Card.vue';
import error from 'hx-layout/Error.vue';
import Loaded from '../../Loaded.vue';
import Icon from 'hx-layout/Icon.vue';

import BellIcon from '../../icons/Bell.vue';

import { formatDateRelativeToIn } from './../../../code/time';
import { attributeFromList } from '../../../code/helpers';

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

export default {
  name: 'OperatorMessages',
  components: {
    hxCard,
    error,
    TableColumn,
    TableComponent,
    Icon,
    Loaded,
  },
  data: () => {
    return {
      title: 'Operator Messages',
      icon: BellIcon,
      error: '',
    };
  },
  computed: {
    operatorMessages() {
      const messages = this.$store.getters.operatorMessages;
      messages.sort((a, b) => b.serverTimestamp - a.serverTimestamp);
      return messages;
    },
  },
  methods: {
    time(serverTimestamp) {
      const tz = this.$timely.current.timezone;
      return formatDateRelativeToIn(serverTimestamp, tz);
    },
    onAcknowledge(row) {
      const channel = this.$channel;
      channel.push('acknowledge operator message', row.id);
    },
  },
};
</script>

<style>
.operator-messages .acknowledged {
  color: grey;
}
</style>
