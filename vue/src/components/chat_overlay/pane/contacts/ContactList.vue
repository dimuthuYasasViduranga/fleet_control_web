<template>
  <div class="contact-list">
    <Scrollable>
      <Contact
        v-for="(asset, i) in assets"
        :key="i"
        :asset="asset"
        :highlight="shouldHighlight(asset)"
        @select="$emit('select', $event)"
      />
    </Scrollable>
  </div>
</template>

<script>
import Contact from './Contact.vue';
import Scrollable from './../../../Scrollable.vue';

export default {
  name: 'ContactList',
  components: {
    Contact,
    Scrollable,
  },
  props: {
    assets: { type: Array, default: () => [] },
    selectedAsset: { type: Object, default: null },
  },
  methods: {
    shouldHighlight(asset) {
      if (this.selectedAsset && this.selectedAsset.id === asset.id) {
        return true;
      }
      return false;
    },
  },
};
</script>

<style>
.contact-list {
  height: 100%;
}
</style>