<template>
  <div class="device-assignment">
    <hxCard style="width: auto" :title="title" :icon="tabletIcon">
      <error :error="error" />

      <loaded>
        <DeviceAssignmentTable
          :assignments="activeAssignments"
          :assets="assets"
          :allocations="activeTimeAllocations"
          :icons="assetIcons"
          :fullTimeCodes="fullTimeCodes"
          :highlightUUIDs="recentlyAuthorized"
          :readonly="readonly"
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
          v-if="!readonly"
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
import { attributeFromList, formatDeviceUUID } from '@/code/helpers.js';
import { toUtcDate } from '@/code/time';

function getMultipleAssignments(assignments, assets, deviceId) {
  const deviceAssigns = assignments.filter(a => a.deviceId === deviceId);

  if (deviceAssigns.length > 1) {
    const assetNames = deviceAssigns.map(assign =>
      attributeFromList(assets, 'id', assign.assetId, 'name'),
    );
    return [true, assetNames];
  }

  return [false, []];
}

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
      recentlyAuthorized: [],
    };
  },
  computed: {
    ...mapState('constants', {
      readonly: state => !state.permissions.can_edit_devices,
      assets: state => state.assets,
      assetIcons: state => state.icons,
      operators: state => state.operators,
    }),
    ...mapState('deviceStore', {
      devices: state => state.devices,
      assignments: state => state.currentDeviceAssignments,
    }),
    activeTimeAllocations() {
      return this.$store.state.activeTimeAllocations;
    },
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
          const [hasMultipleAssignments, multipleAssignmentAssetNames] = getMultipleAssignments(
            this.assignments,
            this.assets,
            d.id,
          );

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

          const assetFullname = assetType ? `${assetName} (${assetType})` : assetName;

          const operatorName = attributeFromList(this.operators, 'id', operatorId, 'name') || '';

          const details = d.details || {};
          const clientVersion = details.client_version;
          const clientUpdatedAt = toUtcDate(details.client_updated_at);

          return {
            deviceId: d.id,
            deviceUUID: d.uuid,
            formattedDeviceName: this.formatDeviceUUID(d.uuid),
            assetId,
            assetName,
            assetFullname,
            assetTypeId,
            assetType,
            operatorId,
            operatorName,
            hasMultipleAssignments,
            multipleAssignmentAssetNames,
            clientVersion,
            clientUpdatedAt,
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
      const now = Math.trunc(this.$everySecond.timestamp / 1000);

      const remaining = timeRemaining - now;
      if (remaining <= 0) {
        return 0;
      }

      return remaining;
    },
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
