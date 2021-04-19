<template>
  <div class="haul-truck-dispatch-event">
    <div v-if="isUnassigned" class="title">
      {{ entry.assetName || 'Unknown' }} | <span class="italics">Unassigned</span>
    </div>
    <div v-else class="title">
      {{ entry.assetName || 'Unknown' }} |
      <span :class="{ italics: !sourceName }">
        {{ sourceName || 'No Source' }}
      </span>
      {{ arrow }}
      <span :class="{ italics: !dumpName }">
        {{ dumpName || 'No Dump' }}
      </span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HaulTruckDispatchEvent',
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
.haul-truck-dispatch-event {
  border: 2px dashed grey;
  padding: 0.25rem;
  padding-top: 0.4rem;
  background-color: #262b2f;
  color: darkgray;
  display: flex;
  flex-direction: row;
}

.haul-truck-dispatch-event .italics {
  font-style: italic;
  opacity: 0.85;
}
</style>