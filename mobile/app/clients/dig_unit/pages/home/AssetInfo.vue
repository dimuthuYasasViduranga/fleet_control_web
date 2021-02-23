<template>
  <GridLayout class="asset-info" :class="livenessClass" rows="* * * *">
    <CenteredLabel row="0" class="text" :text="dispatch.assetName || 'Unknown Asset'" />

    <CenteredLabel row="1" class="text" :text="dispatch.operatorName || 'No Operator'" />

    <DropDown
      row="2"
      :value="dispatch.dumpId"
      :options="locations"
      filter="simple"
      label="name"
      @input="onDumpChange"
    />

    <CenteredLabel row="3" class="text" :text="lastGPSAt" />
  </GridLayout>
</template>

<script>
import { attributeFromList, formatSeconds } from '../../../code/helper';
import CenteredLabel from '../../../common/CenteredLabel.vue';
import DropDown from '../../../common/DropDown.vue';

const IN_RANGE_DIST = 50;
const LIVE_MAX = 30;
const LIVE_WARN_MAX = 1.5 * 60;

export default {
  name: 'AssetInfo',
  components: {
    CenteredLabel,
    DropDown,
  },
  props: {
    dispatch: { type: Object, default: () => ({}) },
    locations: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      now: Date.now(),
      nowInterval: null,
    };
  },
  computed: {
    lastGPSAt() {
      const lastAt = this.dispatch.lastGPSAt;
      if (!lastAt) {
        return null;
      }

      let seconds = (this.now - lastAt.getTime()) / 1000;
      if (seconds <= 1) {
        return null;
      }
      return formatSeconds(seconds, '%R');
    },
    livenessClass() {
      const lastAt = this.dispatch.lastGPSAt;
      if (!lastAt) {
        return 'no-location';
      }

      const age = (this.now - lastAt.getTime()) / 1000;
      if (age < LIVE_MAX) {
        return 'live';
      }

      if (age < LIVE_WARN_MAX) {
        return 'live-warn';
      }

      return 'old';
    },
    payload() {
      const payload = this.dispatch.payload;
      if (payload) {
        return Math.trunc(payload);
      }
      return null;
    },
  },
  mounted() {
    this.nowInterval = setInterval(() => {
      this.now = Date.now();
    }, 3000);
  },
  beforeDestroy() {
    clearInterval(this.nowInterval);
  },
  methods: {
    onDumpChange(dumpId) {
      const payload = {
        asset_id: this.dispatch.assetId,
        dig_unit_id: this.dispatch.digUnitId,
        dump_location_id: dumpId,
      };

      const onError = msg => {
        console.error(`[AssetInfo] ${msg}`);
        this.$toaster.red('Unable to change dump at this time').show();
      };

      this.$channel
        .push('dig:set haul dispatch', payload)
        .receive('ok', () => {
          this.$toaster.info('Dump location successfully changed').show();
        })
        .receive('error', error => onError(error))
        .receive('timeout', () => onError('timeout'));
    },
  },
};
</script>

<style>
.asset-info {
  border-width: 0.5;
  border-color: gray;
}

.asset-info .text {
  border-width: 0.01 0;
  border-color: rgb(54, 54, 54);
  font-size: 30;
}

.asset-info .dropdown-btn,
.asset-info .dropdown-btn-ellipses {
  font-size: 30;
}

.asset-info.live-warn {
  border-color: orange;
  border-width: 2;
}

.asset-info.old,
.asset-info.no-location {
  border-color: orangered;
  border-width: 2;
}
</style>
