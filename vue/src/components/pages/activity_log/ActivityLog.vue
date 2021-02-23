<template>
  <div>
    <hxCard style="width: auto" :title="title" :icon="icon">
      <error :error="error" />

      <loaded>
        <table-component
          table-wrapper="#content"
          table-class="table"
          filterNoResults="No information to display"
          :data="activityLog"
          :show-caption="false"
          sort-by="server_timestamp"
          sort-order="desc"
        >
          <table-column cell-class="table-cel" label="Activity" show="activity" />

          <table-column cell-class="table-cel" label="Source" show="source" />

          <table-column
            cell-class="table-cel"
            label="Operator"
            show="operatorId"
            :formatter="operatorName"
          />

          <table-column
            cell-class="table-cel"
            label="Asset"
            show="assetId"
            :formatter="assetName"
          />

          <table-column
            cell-class="table-cel"
            label="Sent Time"
            show="timestamp"
            :formatter="relativeFormat"
          />

          <table-column
            cell-class="table-cel"
            label="Received Time"
            show="serverTimestamp"
            :formatter="relativeFormat"
          />
        </table-component>
      </loaded>
    </hxCard>
  </div>
</template>

<script type="text/javascript">
import { TableComponent, TableColumn } from 'vue-table-component';
import { formatTodayRelative } from './../../../code/time';

import Loaded from '../../Loaded.vue';
import hxCard from 'hx-layout/Card.vue';
import error from 'hx-layout/Error.vue';
import Icon from 'hx-layout/Icon.vue';

import ListIcon from '../../icons/List.vue';
import { attributeFromList } from '../../../code/helpers';

export default {
  name: 'ActivityLog',
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
      title: 'Activity Log',
      icon: ListIcon,
      error: '',
    };
  },
  computed: {
    activityLog() {
      return this.$store.state.activityLog;
    },
    operators() {
      return this.$store.state.constants.operators;
    },
    assets() {
      return this.$store.state.constants.assets;
    },
  },
  methods: {
    operatorName(operatorId) {
      return attributeFromList(this.operators, 'id', operatorId, 'fullname');
    },
    assetName(assetId) {
      return attributeFromList(this.assets, 'id', assetId, 'name');
    },
    relativeFormat(date) {
      if (!date) {
        return '';
      }

      return formatTodayRelative(date);
    },
  },
};
</script>

<style>
@import '../../../assets/table.css';
@import '../../../assets/hxInput.css';
</style>
