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
        <button class="hx-btn download-details" @click="onDownloadDeviceInfo()">
          Download Device Info
        </button>
        <template v-if="!readonly">
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
        </template>
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
import { downloadCSV } from '@/code/io';

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

function formatAssignment(d, assets, operators, assignments, presenceList, deviceOnlineStatus) {
  const [hasMultipleAssignments, multipleAssignmentAssetNames] = getMultipleAssignments(
    assignments,
    assets,
    d.id,
  );

  const [assetId, operatorId] = attributeFromList(assignments, 'deviceId', d.id, [
    'assetId',
    'operatorId',
  ]);
  const [assetName, assetType, assetTypeId] = attributeFromList(assets, 'id', assetId, [
    'name',
    'type',
    'typeId',
  ]);

  const assetFullname = assetType ? `${assetName} (${assetType})` : assetName;

  const operatorName = attributeFromList(operators, 'id', operatorId, 'name') || '';

  const details = d.details || {};
  const clientVersion = details.client_version;
  const clientUpdatedAt = toUtcDate(details.client_updated_at);
  const deviceStatus = deviceOnlineStatus[d.uuid] || {};

  return {
    deviceId: d.id,
    deviceUUID: d.uuid,
    formattedDeviceName: formatDeviceUUID(d.uuid) || '--',
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
    present: presenceList.includes(d.uuid),
    onlineStatus: deviceStatus.status,
    onlineStatusUpdated: deviceStatus.timestamp,
  };
}

function maybeDateToString(string) {
  if (!string) {
    return;
  }

  const date = toUtcDate(string);

  if (isNaN(Date.parse(date))) {
    return;
  }
  
  return date.toISOString();
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
      readonly: state => !state.permissions.fleet_control_edit_devices,
      assets: state => state.assets,
      assetIcons: state => state.icons,
      operators: state => state.operators,
    }),
    ...mapState('deviceStore', {
      devices: state => state.devices,
      assignments: state => state.currentDeviceAssignments,
    }),
    ...mapState('connection', {
      presenceList: state => state.presence,
      deviceOnlineStatus: state => state.deviceOnlineStatus,
    }),
    ...mapState('deviceStore', {
      pendingDevices: state => state.pendingDevices,
      acceptUntil: state => state.acceptUntil || 0,
    }),
    ...mapState({
      activeTimeAllocations: state => state.activeTimeAllocations,
    }),
    fullTimeCodes() {
      return this.$store.getters['constants/fullTimeCodes'];
    },
    pendingDevices() {
      return this.$store.state.deviceStore.pendingDevices;
    },
    timeRemaining() {
      const timeRemaining = this.acceptUntil;
      const now = Math.trunc(this.$everySecond.timestamp / 1000);

      const remaining = timeRemaining - now;
      if (remaining <= 0) {
        return 0;
      }

      return remaining;
    },
    activeAssignments() {
      // map on devices to show devices that do not have an assignment
      return this.devices
        .filter(d => d.authorized)
        .map(d =>
          formatAssignment(
            d,
            this.assets,
            this.operators,
            this.assignments,
            this.presenceList,
            this.deviceOnlineStatus,
          ),
        );
    },
  },
  methods: {
    onChange(deviceInput) {
      const assignment = {
        device_id: deviceInput.deviceId,
        asset_id: deviceInput.assetId,
      };

      this.$channel.push('device:set-assigned-asset', assignment);
    },
    onForceLogout({ deviceId, timeCodeId }) {
      const payload = {
        device_id: deviceId,
        time_code_id: timeCodeId || null,
      };
      this.$channel.push('device:force-logout', payload);
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
    onDownloadDeviceInfo() {
      const extraKeys = Object.keys(
        this.devices.reduce((acc, device) => Object.assign(acc, device.details), {}),
      );

      const keys = ['id', 'uuid', 'asset_id', 'asset_name', 'asset_type'];

      const assetMap = this.assignments.reduce((acc, assign) => {
        const [name, type] = attributeFromList(this.assets, 'id', assign.assetId, ['name', 'type']);
        acc[assign.deviceId] = { id: assign.assetId, name, type };
        return acc;
      }, {});

      const data = this.devices.map(d => {
        const asset = assetMap[d.id];

        return {
          ...d.details,
          id: d.id,
          uuid: d.uuid,
          asset_id: asset?.id,
          asset_name: asset?.name,
          asset_type: asset?.type,
          authorized_at: maybeDateToString(d.details?.authorized_at),
          client_updated_at: maybeDateToString(d.details?.client_updated_at),
        };
      });

      downloadCSV(`device-info-${Date.now()}.csv`, keys.concat(extraKeys), data);
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

.device-assignment .download-details {
  float: right;
}
</style>
