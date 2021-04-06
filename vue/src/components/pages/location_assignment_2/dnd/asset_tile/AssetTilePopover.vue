<template>
  <div class="asset-tile-popover">
    <table>
      <tr v-if="!hasDevice">
        <td colspan="2" class="missing-device">No Tablet Assigned</td>
      </tr>
      <tr>
        <td class="key">Location</td>
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
      <template v-if="asset.type === 'Haul Truck'">
        <tr>
          <td class="key">Acknowledged</td>
          <td class="value" :style="getColor(dispatchAcknowledged, 'green', 'orange')">
            {{ dispatchAcknowledged ? 'Yes' : 'No' }}
          </td>
        </tr>
      </template>
      <template v-if="asset.secondaryType === 'Dig Unit'">
        <tr>
          <td class="key">Material Type</td>
          <td class="value">{{ materialType || '--' }}</td>
        </tr>
        <tr>
          <td class="key">Load Style</td>
          <td class="value">{{ loadStyle || '--' }}</td>
        </tr>
      </template>

      <tr>
        <td class="key">Allocation</td>
        <td class="value" :style="getColor(activeAllocation.isReady, 'green', 'orange')">
          {{ activeAllocation.name }} {{ activeAllocationDuration }}
        </td>
      </tr>
      <tr>
        <td class="key">Last Seen</td>
        <td class="value">{{ formatDate(track.timestamp) }}</td>
      </tr>
    </table>

    <div v-if="showAlert" class="alert-info">
      <Icon class="alert-icon" :icon="alertIcon" />
      <div class="alert-text">Location suggests exception</div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import { attributeFromList } from '@/code/helpers';
import { formatSeconds, formatDateRelativeToIn, toUtcDate } from '@/code/time';

import AlertIcon from '@/components/icons/Alert.vue';

const NOW_INTERVAL_DURATION = 2000;
const SECONDS_IN_DAY = 24 * 3600;

function getNested(obj, keys) {
  const result = obj[keys[0]];
  if (!result || keys.length === 1) {
    return result;
  }
  return getNested(result, keys.slice(1));
}

export default {
  name: 'AssetTilePopover',
  components: {
    Icon,
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    track: { type: Object, default: () => ({}) },
    showAlert: { type: Boolean, default: false },
  },
  data: () => {
    return {
      alertIcon: AlertIcon,
      now: Date.now(),
      nowInterval: null,
    };
  },
  computed: {
    ...mapState('constants', {
      loadStyles: state => state.loadStyles,
      materialTypes: state => state.materialTypes,
    }),
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
      return !!this.asset.deviceId;
    },
    activeAllocation() {
      return this.asset.activeTimeAllocation || {};
    },
    activeAllocationDuration() {
      const startTime = toUtcDate(this.activeAllocation.startTime);
      if (!startTime) {
        return '';
      }

      const duration = Math.trunc((this.now - startTime.getTime()) / 1000);
      const days = Math.trunc(duration / SECONDS_IN_DAY);
      if (days === 1) {
        return '(> 1 Day)';
      }
      if (days > 1) {
        return `(> ${days} Days)`;
      }
      return formatSeconds(duration, '(%HH:%MM:%SS)');
    },
  },
  mounted() {
    this.nowInterval = setInterval(() => (this.now = new Date()), NOW_INTERVAL_DURATION);
  },
  beforeDestroy() {
    clearInterval(this.nowInterval);
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
  },
};
</script>

<style>
.asset-tile-popover {
  width: 100%;
}

.asset-tile-popover .missing-device {
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
</style>