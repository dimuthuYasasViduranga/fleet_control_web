<template>
  <StackLayout
    v-if="component"
    class="modal-overlay"
    width="100%"
    height="100%"
    verticalAlignment="center"
    @tap="onOuterRegionTap"
  >
    <component
      :class="extraClasses"
      v-bind="props"
      :is="component"
      @tap.native="onChildTap"
      @close="onClose"
    />
  </StackLayout>
</template>

<script>
export default {
  name: 'ModalOverlay',
  props: {
    component: { type: Object, required: true },
    disableOuterClose: { type: Boolean, default: false },
    extraClasses: { type: Array, default: () => [] },
    props: { type: Object, default: () => ({}) },
  },
  data: () => {
    return {
      childTapped: false,
    };
  },
  methods: {
    onOuterRegionTap() {
      if (!this.disableOuterClose && !this.childTapped) {
        this.onClose();
      }

      this.childTapped = false;
    },
    onChildTap() {
      this.childTapped = true;
    },
    onClose(resp) {
      this.$emit('close', resp);
    },
  },
};
</script>

<style>
.modal-overlay {
  background-color: rgba(0, 0, 0, 0.308);
}
</style>