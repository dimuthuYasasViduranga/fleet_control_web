<template>
  <div class="assignments">
    <hxCard style="width: auto" :title="title" :icon="icon">
      <error :error="error" />
      <loaded>
        <table-component
          table-wrapper="#content"
          table-class="table"
          filterNoResults="No information to display"
          :data="assignments"
          :show-caption="false"
          sort-by="deviceUUID"
        >
          <table-column
            cell-class="table-cel"
            label="Device"
            show="deviceUUID"
            :formatter="formatDeviceUUID"
          />

          <table-column cell-class="table-cel" label="Asset" show="assetName" :formatter="dash" />

          <table-column
            cell-class="table-cel"
            label="Active Operator"
            show="operatorName"
            :formatter="dash"
          />

          <table-column
            cell-class="table-cel"
            label="Assigned Operator"
            show="assignedOperator"
            :formatter="dash"
          />

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

<script type="text/javascript">
import { TableComponent, TableColumn } from 'vue-table-component';

import hxCard from 'hx-layout/Card.vue';
import error from 'hx-layout/Error.vue';
import Icon from 'hx-layout/Icon.vue';
import Loaded from '../../Loaded.vue';

import BellIcon from '../../icons/Bell.vue';

import { formatDateRelativeToIn, toUtcDate } from '../../../code/time';
import { attributeFromList, formatDeviceUUID } from '../../../code/helpers';

export default {
  name: 'Assignments',
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
      title: 'Assignments',
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
    devices() {
      return this.$store.state.deviceStore.devices;
    },
    assignments() {
      const assignments = this.$store.state.deviceStore.historicDeviceAssignments
        .map(a => {
          const assetName = attributeFromList(this.assets, 'id', a.asset_id, 'name');
          const activeOperatorName = attributeFromList(this.operators, 'id', a.operator_id, 'name');
          return {
            deviceUUID: a.device_uuid,
            assetName,
            activeOperatorName,
            timestamp: toUtcDate(a.timestamp),
            serverTimestamp: toUtcDate(a.server_timestamp),
          };
        })
        .filter(a => a.deviceUUID);
      return assignments;
    },
  },
  methods: {
    dash(value) {
      return value || '--';
    },
    formatRelative(date) {
      if (!date) {
        return '--';
      }
      const tz = this.$timely.current.timezone;
      return formatDateRelativeToIn(date, tz);
    },
    formatDeviceUUID(uuid) {
      return formatDeviceUUID(uuid);
    },
  },
};
</script>

<style>
.dispatcher-messages .acknowledged {
  color: grey;
}
</style>
