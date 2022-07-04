<template>
  <div class="haul-truck-dispatch-event">
    <div class="title">
      <a v-if="entry.assetName" :href="entry.assetName" @click.prevent="openAssetMessages(entry.assetId)">
        {{ entry.assetName }}
      </a>
      <span v-else class="italics">Unknown</span>
      <span> | </span>

      <span v-if="entry.digUnitName">
         <a :href="entry.digUnitName" @click.prevent="openAssetMessages(entry.digUnitId)">{{entry.digUnitName}}</a>
      </span>
      <span v-else-if="entry.loadLocation">{{ entry.loadLocation }}</span>
      <span v-else-if="entry.dumpName" class="italics">No Source</span>
      <span v-else class="italics">Unassigned</span>

      &DoubleLongRightArrow;

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
  data: () => {return {}},
  computed: {
    sourceName() {
      return this.entry.digUnitName || this.entry.loadLocation;
    },
    dumpName() {
      return this.entry.dumpLocation;
    },
  },
  methods: {
    openAssetMessages(assetId) {
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