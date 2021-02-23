<template>
  <div class="pending-device-table">
    <table-component
      v-if="timeRemaining > 0"
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No devices require attention"
      :data="devices"
      :show-caption="false"
      :show-filter="false"
    >
      <table-column
        cell-class="table-cel"
        label="Pending Device"
        show="uuid"
        :formatter="formatDeviceUUID"
      />

      <table-column cell-class="table-cel">
        <template slot-scope="row">
          <a :id="row.deviceId" @click="onAuthorize(row)">Authorize</a>
        </template>
      </table-column>

      <table-column cell-class="table-cel">
        <template slot-scope="row">
          <a :id="row.deviceId" @click="onReject(row)">Reject</a>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';
import { formatDeviceUUID } from '@/code/helpers';

export default {
  name: 'PendingDeviceTable',
  components: {
    TableColumn,
    TableComponent,
  },
  props: {
    timeRemaining: { type: Number, default: 0 },
    devices: { type: Array, default: () => [] },
  },
  methods: {
    formatDeviceUUID(uuid) {
      if (uuid) {
        return formatDeviceUUID(uuid);
      }
      return '--';
    },
    onAuthorize(row) {
      this.$emit('authorize', row.uuid);
    },
    onReject(row) {
      this.$emit('reject', row.uuid);
    },
  },
};
</script>