<template>
  <div class="assignment-event">
    <div class="title">
      <a href="entry.assetName"  @click.prevent="dmAsset(entry.assetId)">{{ entry.assetName }}</a> 
      <span> | {{ action }}</span>
    </div>
  </div>
</template>

<script>
import { formatDeviceUUID } from '../../../../../code/helpers.js';

export default {
  name: 'AssignmentEvent',
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    action() {
      const uuid = formatDeviceUUID(this.entry.deviceUUID);
      if (this.entry.eventType === 'device-assigned') {
        return `Device '${uuid}' assigned`;
      }
      return `Device '${uuid}' removed`;
    },
  },
  methods: {
    dmAsset(assetId) {

      const opts = {
        scroll: 'bottom',
        assetId: assetId 
      };

      this.$eventBus.$emit('chat-open', opts);
    }
  }
};
</script>

<style>
.assignment-event {
  border: 2px dashed #3a3244;
  padding: 0.25rem;
  background-color: #2e2836;
  color: darkgray;
  white-space: pre;
}

.assignment-event a { 
   color: darkgray;
}
</style>