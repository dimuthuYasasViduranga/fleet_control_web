<template>
  <div class="haul-truck-dispatch-event">
    <div class="title">
      <a v-if="entry.assetName" :href="entry.assetName" @click.prevent="dmAsset(entry.assetId)">{{ entry.assetName }}</a>
      <span v-else>'Unknown'</span>
      <span> | </span>
      <span v-if="isUnassigned" class="italics">Unassigned</span>
      <span v-if="entry.digUnitName" :class="{ italics: !sourceName }">
         <a :href="entry.digUnitName" @click.prevent="dmAsset(entry.digUnitId)">{{entry.digUnitName}}</a>
      </span>
      <span v-else>'No Source'</span>

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
      return this.entry.dumpLocation;
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

.haul-truck-dispatch-event a { 
  color: darkgray;
}
</style>