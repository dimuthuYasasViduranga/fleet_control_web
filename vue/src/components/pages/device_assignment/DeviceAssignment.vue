<template>
  <div class="device-assignment">
    <hxCard style="width: auto" :title="title" :icon="tabletIcon">
      <error :error="error" />

      <loaded>
        <DeviceAssignmentTable
          :assignments="activeAssignments"
          :assets="assets"
          :icons="assetIcons"
          :fullTimeCodes="fullTimeCodes"
          :highlightUUIDs="recentlyAuthorized"
          @change="onChange"
          @logout="onForceLogout"
          @revoke="onRevoke"
        />
        <button class="hx-btn accept-new-devices" @click="onOpenDeviceWindow">
          Accept New Devices
        </button>
        <button class="hx-btn" v-if="timeRemaining > 0" @click="onCloseDeviceWindow">
          Expire Now
        </button>
        <div class="remaining" v-if="timeRemaining > 0">
          Expires in: {{ timeRemaining }} seconds
        </div>
        <div style="height: 1em"></div>
        <PendingDeviceTable
          :timeRemaining="timeRemaining"
          :devices="pendingDevices"
          @authorize="onAuthorize"
          @reject="onReject"
        />
      </loaded>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';

import Loaded from '../../Loaded.vue';
import hxCard from 'hx-layout/Card.vue';
import error from 'hx-layout/Error.vue';

import DeviceAssignmentTable from './DeviceAssignmentTable.vue';
import PendingDeviceTable from './PendingDeviceTable.vue';

import TabletIcon from '../../icons/Tablet.vue';
import { attributeFromList, formatDeviceUUID } from '../../../code/helpers.js';

export default {
  name: 'DeviceAssignment',
  components: {
    hxCard,
    error,
    Loaded,
    DeviceAssignmentTable,
    PendingDeviceTable,
  },
  data: () => {
    return {
      title: 'Device Assignment',
      tabletIcon: TabletIcon,
      error: '',
      now: Date.now(),
      nowInterval: null,
      recentlyAuthorized: [],
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      assetIcons: state => state.icons,
      operators: state => state.operators,
    }),
    ...mapState('deviceStore', {
      devices: state => state.devices,
      assignments: state => state.currentDeviceAssignments,
    }),
    fullTimeCodes() {
      return this.$store.getters['constants/fullTimeCodes'];
    },
    presenceList() {
      return this.$store.state.connection.presence;
    },
    activeAssignments() {
      // map on devices to show devices that do not have an assignment
      const assignments = this.devices
        .filter(d => d.authorized)
        .map(d => {
          const [assetId, operatorId] = attributeFromList(this.assignments, 'deviceId', d.id, [
            'assetId',
            'operatorId',
          ]);
          const [assetName, assetType, assetTypeId] = attributeFromList(
            this.assets,
            'id',
            assetId,
            ['name', 'type', 'typeId'],
          );

          const operatorName = attributeFromList(this.operators, 'id', operatorId, 'name') || '';

          return {
            deviceId: d.id,
            deviceUUID: d.uuid,
            formattedDeviceName: this.formatDeviceUUID(d.uuid),
            assetId,
            assetName,
            assetTypeId,
            assetType,
            operatorId,
            operatorName,
            deviceDetails: d.details || {},
            present: this.presenceList.includes(d.uuid),
          };
        });

      return assignments;
    },
    pendingDevices() {
      return this.$store.state.deviceStore.pendingDevices;
    },
    timeRemaining() {
      const timeRemaining = this.$store.state.deviceStore.acceptUntil || 0;
      const now = Math.trunc(this.now / 1000);

      const remaining = timeRemaining - now;
      if (remaining <= 0) {
        return 0;
      }

      return remaining;
    },
  },
  mounted() {
    this.nowInterval = setInterval(() => (this.now = Date.now()), 1000);
  },
  beforeDestroy() {
    clearInterval(this.nowInterval);
  },
  methods: {
    onChange(deviceInput) {
      const assignment = {
        device_id: deviceInput.deviceId,
        asset_id: deviceInput.assetId,
      };

      this.$channel.push('set assigned asset', assignment);
    },
    onForceLogout({ deviceId, timeCodeId }) {
      const payload = {
        device_id: deviceId,
        time_code_id: timeCodeId || null,
      };
      this.$channel.push('force logout device', payload);
    },
    onAuthorize(uuid) {
      this.recentlyAuthorized.push(uuid);
      this.$channel.push('auth:accept device', uuid);
    },
    onReject(uuid) {
      this.$channel.push('auth:reject device', uuid);
    },
    onCloseDeviceWindow() {
      this.$channel.push('auth:close device window');
    },
    onOpenDeviceWindow() {
      this.$channel.push('auth:open device window');
    },
    onRevoke(deviceId) {
      if (deviceId) {
        this.$channel.push('auth:revoke device', deviceId);
      }
    },
    formatDeviceUUID(uuid) {
      return uuid ? formatDeviceUUID(uuid) : '--';
    },
  },
};
</script>

<style>
@import '../../../assets/table.css';
@import '../../../assets/hxInput.css';

.device-assignment .accept-new-devices {
  margin-right: 0.5rem;
}
</style>
