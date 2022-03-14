<template>
  <div class="asset-tile-popover">
    <table>
      <tr v-if="!hasDevice">
        <td colspan="2" class="danger">No Tablet Assigned</td>
      </tr>
      <tr v-if="!hasType">
        <td colspan="2" class="danger">No Asset Type</td>
      </tr>
      <tr>
        <td class="key">GPS Location</td>
        <td class="value">{{ trackLocation || '--' }}</td>
      </tr>
      <tr>
        <td class="key">Operator</td>
        <td class="value">{{ operatorName || '--' }}</td>
      </tr>
      <tr>
        <td class="key">Connection</td>
        <td class="value" :style="getColor(asset.present, 'green', 'grey')">
          {{ asset.present ? 'Online' : 'Offline' }}
        </td>
      </tr>
      <tr>
        <td class="key">Radio</td>
        <td class="value">{{ asset.radioNumber }}</td>
      </tr>
      <!-- haul truck only -->
      <template v-if="asset.type === 'Haul Truck'">
        <tr>
          <td class="key">Acknowledged</td>
          <td class="value" :style="getColor(dispatchAcknowledged, 'green', 'orange')">
            {{ dispatchAcknowledged ? 'Yes' : 'No' }}
          </td>
        </tr>
        <tr v-if="queueStatus === 'queued'">
          <td class="key">Queue At Load</td>
          <td class="value">{{ timeInQueue }}</td>
        </tr>
      </template>
      <!-- dig unit only -->
      <template v-if="asset.secondaryType === 'Dig Unit'">
        <tr>
          <td class="key">Material Type</td>
          <td class="value">{{ materialType || '--' }}</td>
        </tr>
      </template>

      <tr>
        <td class="key">Allocation</td>
        <td class="value" :style="getColor(activeAllocation.isReady, 'green', 'orange')">
          {{ activeAllocation.name }} {{ activeAllocationDuration }}
        </td>
      </tr>
      <tr>
        <td class="key">Last Seen ({{ trackSource }})</td>
        <td v-if="ago.duration != null" class="value" :class="ago.class">
          {{ formatAgo(ago.duration) }}
        </td>
        <td v-else class="value red-text">{{ formatDate(track.timestamp) || '--' }}</td>
      </tr>
      <tr v-if="uuid" class="uuid-row">
        <td class="key">Device UUID</td>
        <td class="value">{{ uuid }}</td>
      </tr>
    </table>

    <div v-if="asset.status === 'requires-update'" class="alert-info">
      <Icon class="alert-icon" :icon="alertIcon" />
      <div class="alert-text">In Ready code without operator</div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import { attributeFromList, formatDeviceUUID } from '@/code/helpers';
import {
  formatSeconds,
  formatDateRelativeToIn,
  toUtcDate,
  formatSecondsRelative,
} from '@/code/time';

import AlertIcon from '@/components/icons/Alert.vue';

const SECONDS_IN_DAY = 24 * 3600;
const AGO_SWITCH = 60 * 60 * 1000; // 1 hour
const AGO_MAX = 2 * 60 * 1000; // 2 minutes
const AGO_WARN = 30 * 1000; // 30 seconds

function getNested(obj, keys) {
  const result = obj[keys[0]];
  if (!result || keys.length === 1) {
    return result;
  }
  return getNested(result, keys.slice(1));
}

function getAgoClass(duration) {
  if (duration < AGO_WARN) {
    return 'green-text';
  }

  if (duration < AGO_MAX) {
    return 'orange-text';
  }

  return 'red-text';
}

export default {
  name: 'AssetTilePopover',
  components: {
    Icon,
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    track: { type: Object, default: () => ({}) },
  },
  data: () => {
    return {
      alertIcon: AlertIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      loadStyles: state => state.loadStyles,
      materialTypes: state => state.materialTypes,
    }),
    trackSource() {
      return this.track?.source;
    },
    trackLocation() {
      return getNested(this.track, ['location', 'name']);
    },
    operatorName() {
      return getNested(this.asset, ['operator', 'fullname']);
    },
    dispatchAcknowledged() {
      return getNested(this.asset, ['dispatch', 'acknowledged']);
    },
    loadStyle() {
      const loadStyleId = getNested(this.asset, ['activity', 'loadStyleId']);
      return attributeFromList(this.loadStyles, 'id', loadStyleId, 'style');
    },
    materialType() {
      const materialTypeId = getNested(this.asset, ['activity', 'materialTypeId']);
      return attributeFromList(this.materialTypes, 'id', materialTypeId, 'commonName');
    },
    hasDevice() {
      if (this.asset.hasDevice !== undefined) {
        return this.asset.hasDevice;
      }

      return !!this.asset.deviceId;
    },
    hasType() {
      return !!this.asset.type;
    },
    activeAllocation() {
      return this.asset.activeTimeAllocation || {};
    },
    activeAllocationDuration() {
      const startTime = toUtcDate(this.activeAllocation.startTime);
      if (!startTime) {
        return '';
      }

      const duration = Math.trunc((this.$everySecond.timestamp - startTime.getTime()) / 1000);
      const days = Math.trunc(duration / SECONDS_IN_DAY);
      if (days === 1) {
        return '(> 1 Day)';
      }
      if (days > 1) {
        return `(> ${days} Days)`;
      }
      return formatSeconds(duration, '(%HH:%MM:%SS)');
    },
    ago() {
      if (!this.track.timestamp) {
        return { duration: null, class: null };
      }
      let ago = this.$everySecond.timestamp - this.track.timestamp.getTime();
      ago = ago < 0 ? 0 : ago;

      if (ago > AGO_SWITCH) {
        return { duration: null, class: null };
      }

      const styleClass = getAgoClass(ago);
      return { duration: ago, class: styleClass };
    },
    uuid() {
      return formatDeviceUUID(this.asset.deviceUUID);
    },
    queueStatus() {
      return this.asset?.liveQueueInfo?.status;
    },
    timeInQueue() {
      if (this.asset.type !== 'Haul Truck') {
        return;
      }
      const startedAt = this.asset?.liveQueueInfo?.startedAt;
      if (!startedAt) {
        return;
      }

      const duration = this.$everySecond.timestamp - startedAt.getTime();
      return formatSeconds(Math.trunc(duration / 1000));
    },
  },
  methods: {
    getColor(bool, colorOnTrue, colorOnFalse) {
      const color = bool ? colorOnTrue : colorOnFalse;
      return color ? `color: ${color}` : '';
    },
    formatDate(date) {
      const tz = this.$timely.current.timezone;
      return formatDateRelativeToIn(date, tz);
    },
    formatAgo(ago) {
      return formatSecondsRelative(Math.trunc(ago / 1000));
    },
  },
};
</script>

<style>
.asset-tile-popover {
  width: 100%;
}

.asset-tile-popover .danger {
  background-color: darkred;
  text-align: center;
}

.asset-tile-popover .key {
  padding-right: 0.5rem;
}

.asset-tile-popover .value {
  padding-left: 0.5rem;
  text-align: center;
}

.asset-tile-popover .alert-info {
  margin-top: 0.75rem;
  display: flex;
  justify-content: center;
}

.asset-tile-popover .alert-info .alert-icon {
  height: 1.25rem;
  width: 1.25rem;
}

.asset-tile-popover .alert-info .alert-icon svg {
  stroke: orange;
  stroke-width: 1.5;
}

.asset-tile-popover .uuid-row {
  opacity: 0.3;
}
</style>