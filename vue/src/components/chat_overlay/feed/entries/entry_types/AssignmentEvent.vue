<template>
  <div class="assignment-event">
    <div class="title">{{ entry.assetName }} | {{ action }}</div>
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
};
</script>

<style>
.assignment-event {
  border: 2px dashed #3a3244;
  padding: 0.25rem;
  background-color: #2e2836;
  color: darkgray;
}
</style>