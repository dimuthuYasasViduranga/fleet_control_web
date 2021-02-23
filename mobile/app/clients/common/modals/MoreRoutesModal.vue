<template>
  <ScrollView class="more-routes-modal" orientation="vertical">
    <StackLayout class="more-routes-content">
      <Button
        class="button"
        v-for="(view, index) in views"
        :key="index"
        :class="highlightClass(view.id)"
        :text="view.text"
        :isEnabled="isEnabled(view.id)"
        textTransform="capitalize"
        @tap="close(view.id)"
      />
    </StackLayout>
  </ScrollView>
</template>

<script>
import axios from 'axios';
const AuthChannel = require('./../../code/auth_channel.js');
const platformModule = require('tns-core-modules/platform');
import { AndroidInterface } from './androidInterface';

export default {
  name: 'InfoModal',
  props: {
    views: { type: Array, default: [] },
    disabled: { type: Array, default: () => [] },
    selectedView: { type: String, default: null },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    highlightClass(view) {
      if (view === this.selectedView) {
        return 'highlight';
      }
      return;
    },
    isEnabled(view) {
      if (this.disabled.includes(view)) {
        return false;
      }
      return true;
    },
  },
};
</script>

<style>
.more-routes-modal {
  background-color: white;
  width: 500;
}

.more-routes-content {
  padding: 25 50;
}

.more-routes-modal .button {
  height: 80;
  font-size: 30;
}

.more-routes-modal .button[isEnabled='false'] {
  background-color: lightgray;
  opacity: 0.3;
}

.more-routes-modal .highlight {
  background-color: lightslategray;
  color: white;
}
</style>
