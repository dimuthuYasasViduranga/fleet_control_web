<template>
  <div :id="id" class="time-span-chart-tooltip">
    <div v-if="highlighted" class="time-span-chart-tooltip-wrapper" @mouseenter="onEnter">
      <slot v-bind="highlighted"> </slot>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SlotWrapper',
  props: {
    id: { type: String, required: true },
    parent: { type: Object, default: () => ({}) },
    onEnterCallback: { type: Function, default: () => null },
  },
  computed: {
    highlighted() {
      return this.parent.highlighted;
    },
  },
  methods: {
    onEnter() {
      this.onEnterCallback();
    },
  },
};
</script>