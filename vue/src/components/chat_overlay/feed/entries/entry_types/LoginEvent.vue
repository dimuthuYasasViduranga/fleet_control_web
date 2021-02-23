<template>
  <div class="login-event">
    <div class="title">
      {{ entry.assetName || 'Unknown Asset' }} | {{ type }}: {{ entry.operatorFullname }}
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
};
</script>

<style>
.login-event {
  border: 2px dashed #583b09;
  padding: 0.25rem;
  background-color: #312511;
  color: darkgray;
}
</style>