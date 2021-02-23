<template>
  <v-popover
    class="asset-icon"
    :open.sync="showPopover"
    trigger="hover"
    placement="top-left"
    :delay="{ show: 100, hide: 0 }"
  >
    <div class="asset-icon-wrapper" :class="assetIconClass">
      <Icon class="asset-icon" :icon="icons[asset.type]" :scale="iconScale" />
      <div class="asset-name">{{ asset.name }}</div>
      <div class="alert-wrapper" v-if="showAlert">
        <Icon class="alert-icon" :icon="alertIcon" />
      </div>
    </div>

    <div class="__asset-progress-popover" slot="popover" @mouseenter="showPopover = false">
      <table>
        <tr>
          <td class="key">Location</td>
          <td class="value">{{ asset.track.location || '--' }}</td>
        </tr>
        <tr>
          <td class="key">Allocation</td>
          <td class="value" :style="`color: ${activeTimeAllocation.isReady ? 'green' : 'orange'}`">
            {{ activeTimeAllocation.name || '--' }}
          </td>
        </tr>
        <tr v-if="asset.loadName">
          <td class="key">Load: {{ asset.loadName }}</td>
          <td class="value">
            {{ formatDistance(asset.loadDistance) || 'No Route' }} {{ loadPercent }}
          </td>
        </tr>
        <tr v-if="asset.dumpName">
          <td class="key">Dump: {{ asset.dumpName }}</td>
          <td class="value">
            {{ formatDistance(asset.dumpDistance) || 'No Route' }} {{ dumpPercent }}
          </td>
        </tr>
        <tr>
          <td class="key">Last Seen</td>
          <td class="value">{{ formatTimestamp(asset.track.timestamp) }}</td>
        </tr>
      </table>

      <div v-if="showAlert" class="alert-info">
        <Icon class="alert-icon" :icon="alertIcon" />
        Location suggests exception
      </div>
    </div>
  </v-popover>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import AlertIcon from '../../icons/Alert.vue';
import { todayRelativeFormat } from '../../../code/time';
import { isMissingException } from '../../../store/modules/haul_truck';
function safeDiv(x, y) {
  if (y === 0) {
    return 0;
  }
  return x / y;
}
function formatDistance(distance) {
  let suffix = ' m';
  if (distance > 1000) {
    suffix = ' km';
    distance = distance / 1000;
  }
  return `${Math.round(distance)}${suffix}`;
}
export default {
  name: 'AssetIcon',
  components: {
    Icon,
  },
  props: {
    asset: { type: Object, required: true },
    icons: { type: Object, default: () => ({}) },
    locations: { type: Array, default: () => [] },
    direction: { type: String, default: null },
  },
  data: () => {
    return {
      alertIcon: AlertIcon,
      showPopover: false,
    };
  },
  computed: {
    activeTimeAllocation() {
      const alloc = this.asset.activeTimeAllocation || {};
      return {
        name: alloc.name,
        isReady: alloc.isReady,
      };
    },
    totalDistance() {
      const loadDist = this.asset.loadDistance;
      const dumpDist = this.asset.dumpDistance;
      if (loadDist == null || dumpDist == null) {
        return null;
      }
      return loadDist + dumpDist;
    },
    loadPercent() {
      if (this.totalDistance == null) {
        return '';
      }
      const percent = 100 - safeDiv(this.asset.loadDistance, this.totalDistance) * 100;
      return `(${Math.trunc(percent)}%)`;
    },
    dumpPercent() {
      if (this.totalDistance == null) {
        return '';
      }
      const percent = 100 - safeDiv(this.asset.dumpDistance, this.totalDistance) * 100;
      return `(${Math.trunc(percent)}%)`;
    },
    showAlert() {
      return isMissingException(
        this.asset.activeTimeAllocation,
        this.asset.track.locationType,
        this.asset.track.timestamp,
      );
    },
    iconScale() {
      return this.direction === 'left' ? { x: -1 } : 1;
    },
    assetIconClass() {
      const asset = this.asset;
      if (!asset.activeTimeAllocation.isReady) {
        return 'exception-icon';
      }
      if (asset.present) {
        return 'ok-icon';
      }
      return 'offline-icon';
    },
  },
  methods: {
    formatTimestamp(timestamp) {
      return todayRelativeFormat(timestamp);
    },
    formatDistance(distance) {
      if (distance == null) {
        return null;
      }
      return formatDistance(distance);
    },
  },
};
</script>

<style>
@import '../../../assets/iconColors.css';
.asset-icon.v-popover .trigger {
  outline: none;
}
.__asset-progress-popover .key {
  padding-right: 0.5rem;
}
.__asset-progress-popover .value {
  padding-left: 0.5rem;
}
.__asset-progress-popover .alert-info {
  margin-top: 0.75rem;
  display: flex;
}
.__asset-progress-popover .alert-info .alert-icon {
  height: 1.25rem;
  width: 1.25rem;
}
.__asset-progress-popover .alert-info .alert-icon svg {
  stroke: orange;
  stroke-width: 1.5;
}
.asset-icon .asset-icon-wrapper {
  width: 3rem;
  z-index: 5;
}
.asset-icon .asset-icon-wrapper .asset-icon {
  width: 100%;
}
.asset-icon .asset-icon-wrapper .asset-name {
  user-select: none;
  width: 100%;
  text-align: center;
}
.asset-icon .asset-icon-wrapper .alert-wrapper {
  position: absolute;
  top: 0;
  right: 0;
  width: 1.25rem;
  height: 1.25rem;
}
.asset-icon .asset-icon-wrapper .alert-wrapper .hx-icon {
  width: 100%;
  height: 100%;
  stroke: orange;
}
.asset-icon .asset-icon-wrapper .alert-wrapper .hx-icon svg {
  stroke-width: 2;
}
</style>