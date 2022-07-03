<template>
  <div class="login-event">
    <div class="title">
      <a v-if="entry.assetName" :href="entry.assetName" @click.prevent="dmAsset(entry.assetId)">{{ entry.assetName }}</a>
      <span v-else>'Unknown Asset'</span>
      <span> | {{ type }}: {{ entry.operatorFullname }}</span>
    </div>
  </div>
</template>

<script>
import { toFullName } from '../../../../../code/helpers.js';

export default {
  name: 'LoginEvent',
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    operatorFullName() {
      return toFullName(this.entry.operatorName, this.entry.operatorNickname);
    },
    type() {
      return this.entry.eventType === 'login' ? 'Login' : 'Logout';
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
.login-event {
  border: 2px dashed #583b09;
  padding: 0.25rem;
  background-color: #312511;
  color: darkgray;
  white-space: pre;
}
</style>