<template>
  <div class="haul-truck-mass-dispatch-event">
    <div class="title">
      <div class="star">{{ '\u2b50' }}</div>
      <div class="text">Mass Change | {{ assets }}</div>
    </div>
    <div v-if="isUnassigned" class="message">
      <span class="new italics">Unassigned</span>
    </div>
    <div v-else class="message">
      <span class="new">
        <span :class="{ italics: !sourceName }">
          {{ sourceName || 'No Source' }}
        </span>
        {{ arrow }}
        <span :class="{ italics: !dumpName }">
          {{ dumpName || 'No Dump' }}
        </span>
      </span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HaulTruckMassDispatchEvent',
  props: {
    entry: { type: Object, required: true },
  },
  data: () => {
    return {
      arrow: '\u27f9',
    };
  },
  computed: {
    isUnassigned() {
      const entry = this.entry;
      return !entry.digUnitName && !entry.loadLocation && !entry.dumpLocation;
    },
    assets() {
      return this.entry.assetNames;
    },
    sourceName() {
      return this.entry.digUnitName || this.entry.loadLocation;
    },
    dumpName() {
      return this.entry.dumpName;
    },
  },
};
</script>

<style>
.haul-truck-mass-dispatch-event {
  border: 2px dashed grey;
  padding: 0.25rem;
  background-color: #38393a;
  color: darkgray;
}

.haul-truck-mass-dispatch-event .title {
  display: inline-flex;
  line-height: 1.25rem;
}

.haul-truck-mass-dispatch-event .title .text {
  padding-bottom: 0.25rem;
}

.haul-truck-mass-dispatch-event .message {
  display: flex;
  flex-wrap: wrap;
  padding-left: 1.5rem;
}

.haul-truck-mass-dispatch-event .italics {
  font-style: italic;
  opacity: 0.85;
}
</style>