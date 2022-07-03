<template>
  <div class="time-allocation-event" :class="typeClass">
    <a :href="entry.assetName" class="asset-name" @click.prevent="dmAsset(entry.assetId)">{{ entry.assetName }}</a>
    <span> | </span>
    <span class="time-code">{{ entry.timeCodeGroup }} &mdash; {{ entry.timeCode }}</span>
    <span class="duration">{{ duration }}</span>
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

  methods: {
    dmAsset(assetId) {

      const opts = {
        scroll: 'bottom',
        assetId: assetId 
      };

      this.$eventBus.$emit('chat-open', opts);
    },
  }
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
  white-space: pre;
}

.time-allocation-event .asset-name,
.time-allocation-event .duration {
  white-space: nowrap;
}

.time-allocation-event .time-code {
  width: 100%;
}
.time-allocation-event.ready {
  border-color: darkgreen;
  background-color: rgba(0, 128, 0, 0.158);
}

.time-allocation-event.exception {
  border-color: darkorange;
  background-color: rgba(150, 85, 0, 0.233);
}

.time-allocation-event a {
  color: darkgrey;
}

</style>