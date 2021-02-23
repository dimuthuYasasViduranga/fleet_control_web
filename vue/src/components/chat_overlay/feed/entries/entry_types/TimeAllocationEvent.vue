<template>
  <div class="time-allocation-event" :class="typeClass">
    <div class="asset-name">{{ entry.assetName }} |</div>
    <div class="time-code">{{ entry.timeCodeGroup }} &mdash; {{ entry.timeCode }}</div>
    <div class="duration">{{ duration }}</div>
  </div>
</template>

<script>
import { formatSeconds, divMod } from '../../../../../code/time';

const SECONDS_IN_DAY = 3600 * 24;

export default {
  name: 'TimeAllocationEvent',
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    typeClass() {
      return this.entry.isReady ? 'ready' : 'exception';
    },
    duration() {
      const seconds = this.entry.duration;
      if (seconds === null) {
        return 'Active';
      }

      const [days, remainder] = divMod(seconds, SECONDS_IN_DAY);

      let daysStr = '';
      if (days > 0) {
        daysStr = days === 1 ? '1 day ' : `${days} days `;
      }
      return `${daysStr}${formatSeconds(remainder)}`;
    },
  },
};
</script>

<style>
.time-allocation-event {
  border: 1px solid grey;
  padding: 0.25rem;
  padding-top: 0.4rem;
  background-color: #383e42;
  color: darkgray;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
}

.time-allocation-event .asset-name,
.time-allocation-event .duration {
  white-space: nowrap;
}

.time-allocation-event .time-code {
  width: 100%;
  padding-left: 0.25rem;
}

.time-allocation-event.ready {
  border-color: darkgreen;
  background-color: rgba(0, 128, 0, 0.158);
}

.time-allocation-event.exception {
  border-color: darkorange;
  background-color: rgba(150, 85, 0, 0.233);
}
</style>