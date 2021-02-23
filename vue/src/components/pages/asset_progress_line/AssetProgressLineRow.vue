<template>
  <div class="asset-progress-line-row">
    <div class="left">
      <div class="location">{{ asset.dumpName }}</div>
      <div class="distance">({{ formatDistance(asset.dumpDistance) }})</div>
    </div>
    <div class="line" :style="lineLayout">
      <span class="asset-progress asset-progress-left">
        <div class="asset-progress-line"></div>
      </span>

      <span class="asset-progress asset-progress-center">
        <AssetIcon :asset="asset" :icons="icons" :locations="locations" :direction="direction" />
      </span>

      <span class="asset-progress asset-progress-right">
        <div class="asset-progress-line"></div>
      </span>
    </div>
    <div class="right">
      <div class="location">{{ asset.loadName }}</div>
      <div class="distance">({{ formatDistance(asset.loadDistance) }})</div>
    </div>
  </div>
</template>

<script>
import { attributeFromList } from '../../../code/helpers';
import AssetIcon from './AssetIcon.vue';
const LOCATION_COLORS = {
  fuel_bay: 'yellow',
  parkup: 'orange',
  maintenance: 'orange',
};
function formatDistance(distance) {
  let suffix = ' m';
  if (distance > 1000) {
    suffix = ' km';
    distance = distance / 1000;
  }
  return `${Math.round(distance)}${suffix}`;
}
export default {
  name: 'AssetProcessLineRow',
  components: {
    AssetIcon,
  },
  props: {
    asset: { type: Object, required: true },
    icons: { type: Object, default: () => ({}) },
    locations: { type: Array, default: () => [] },
  },
  computed: {
    lineLayout() {
      const dumpDistance = this.asset.dumpDistance || 1;
      const loadDistance = this.asset.loadDistance || 1;
      return `grid-template-columns: ${dumpDistance}fr 0 ${loadDistance}fr;`;
    },
    direction() {
      if (this.asset.direction === 'dump') {
        return 'left';
      }
      return 'right';
    },
  },
  methods: {
    formatDistance(distance) {
      return formatDistance(distance);
    },
  },
};
</script>

<style>
@import '../../../assets/iconColors.css';
.asset-progress-line-row {
  display: grid;
  grid-template-columns: 10rem auto 10rem;
  height: 3.5rem;
}
.asset-progress-line-row .line {
  display: grid;
  height: 100%;
}
.asset-progress-line-row .left {
  margin: auto 0;
}
.asset-progress-line-row .right {
  text-align: right;
  margin: auto 0;
}
.asset-progress-line-row .asset-progress-left,
.asset-progress-line-row .asset-progress-right {
  border-top: 1px solid white;
  margin-top: 2em;
}
.aplr__asset-info-popover .key {
  padding-right: 1rem;
}
.asset-progress-line-row .asset-progress-center .asset-icon .asset-icon-wrapper {
  transform: translate(-50%);
  background-color: #121f26;
}
</style>