<template>
  <span class="icon-wrapper">
    <svg :viewBox="dimensions" class="icon">
      <component v-bind:is="icon" />
    </svg>
  </span>
</template>

<script>
export default {
  name: 'icon',
  props: {
    icon: Object,
    icon_size: Number,
    iconSize: Number,
  },
  computed: {
    size() {
      return this.icon.size || this.iconSize || this.icon_size;
    },
    dimensions() {
      return `0 0 ${this.size} ${this.size}`;
    },
  },
};
</script>

<style>
.icon {
  pointer-events: none;
  display: block;
  width: 100%;
  height: 100%;
}

.icon-wrapper {
  stroke: #b7c3cd;
  fill: none;
  height: 2em;
  width: 4em;
  position: relative;
  display: flex;
}
</style>
