<template>
  <GridLayout class="allocation-banner" columns="5* 25* 6* 5*" :class="outlineClass">
    <CenteredLabel class="asset" :text="`${(asset || {}).name} |`" />
    <CenteredLabel class="name" :text="activeText" textTransform="uppercase" col="1" />
    <CenteredLabel class="duration" :text="formattedDuration" col="2" />
    <Button col="3" class="change-allocation" text="Change" @tap="onChangeAllocation()" />
  </GridLayout>
</template>

<script>
import { attributeFromList, toPlural, pad } from '../../code/helper';
import CenteredLabel from '../CenteredLabel.vue';
import AllocationSelectModal from '../modals/AllocationSelectModal.vue';

const SECONDS_IN_DAY = 86400;
const SECONDS_IN_HOUR = 3600;

function secondsToComponents(totalSeconds) {
  let delta = Math.abs(totalSeconds);
  const days = Math.floor(delta / SECONDS_IN_DAY);
  delta -= days * SECONDS_IN_DAY;

  const hours = Math.floor(delta / SECONDS_IN_HOUR) % 24;
  delta -= hours * SECONDS_IN_HOUR;

  const minutes = Math.floor(delta / 60) % 60;
  delta -= minutes * 60;

  const seconds = Math.floor(delta % 60);

  return {
    totalSeconds,
    days,
    hours,
    minutes,
    seconds,
  };
}

function formatTimeComponents({ days, hours, minutes, seconds }) {
  if (days > 0) {
    return `> ${toPlural(days, ' day', 's')}`;
  }
  const hourStr = pad(hours);
  const minuteStr = pad(minutes);
  const secondStr = pad(seconds);

  return `${hourStr}:${minuteStr}:${secondStr}`;
}

export default {
  name: 'AllocationBanner',
  components: {
    CenteredLabel,
  },
  props: {
    asset: { type: Object, default: null },
    operator: { type: Object, default: null },
    allocation: { type: Object, default: () => ({}) },
    fullTimeCodes: { type: Array, default: () => [] },
    initialExceptionGroup: String,
  },
  data: () => {
    return {
      duration: null,
      durationInterval: null,
    };
  },
  computed: {
    timeCodeInfo() {
      return attributeFromList(this.fullTimeCodes, 'id', this.allocation.timeCodeId) || {};
    },
    formattedDuration() {
      if (!this.duration) {
        return '';
      }

      const components = secondsToComponents(this.duration);
      return formatTimeComponents(components);
    },
    outlineClass() {
      const info = this.timeCodeInfo;
      if (!info.id || info.name === 'No Task') {
        return 'no-task';
      }

      return info.isReady ? 'ready' : 'exception';
    },
    activeText() {
      return this.timeCodeInfo.name || 'No Task';
    },
  },
  mounted() {
    this.setDuration();
    this.durationInterval = setInterval(() => {
      this.setDuration();
    }, 1000);
  },
  beforeDestroy() {
    clearInterval(this.durationInterval);
  },
  methods: {
    setDuration() {
      const startTime = this.allocation.startTime;
      if (!startTime) {
        this.duration = null;
        return;
      }

      this.duration = (Date.now() - startTime.getTime()) / 1000;
    },
    onChangeAllocation() {
      if (this.timeCodeInfo.isReady === true) {
        this.changeAllocation();
      } else {
        this.changeAllocation();
      }
    },

    changeAllocation() {
      const opts = {
        asset: this.asset,
        operator: this.operator,
        group: this.initialExceptionGroup,
      };
      this.$modalBus.open(AllocationSelectModal, opts).onClose(response => {
        if (response) {
          this.submit(response.timeCodeId);
        }
      });
    },
    submit(timeCodeId) {
      const allocation = {
        assetId: this.asset.id,
        timeCodeId,
        startTime: Date.now(),
        endTime: null,
      };

      this.$store.dispatch('submitAllocation', { allocation, channel: this.$channel });

      this.$emit('change', allocation);
    },
  },
};
</script>

<style>
.allocation-banner {
  border-width: 2;
}

.allocation-banner .asset,
.allocation-banner .name,
.allocation-banner .duration {
  font-size: 22;
  text-align: center;
}

.allocation-banner .change-allocation {
  font-size: 18;
  color: #0c1419;
  background-color: #d6d7d7;
}

/* outline colors */
.allocation-banner.no-task {
  background-color: rgb(146, 95, 0);
  border-color: orange;
}

.allocation-banner.ready {
  background-color: rgb(0, 56, 0);
  border-color: darkgreen;
}

.allocation-banner.exception {
  background-color: #7b1115;
  border-color: red;
}
</style>

