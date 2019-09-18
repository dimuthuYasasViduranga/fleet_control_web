<template>
  <span class="icon-wrapper" @click="onClick()">
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
      if (this.icon) {
        return this.icon.size;
      }
      return this.iconSize || this.icon_size || 0;
    },
    dimensions() {
      return `0 0 ${this.size} ${this.size}`;
    },
  },
  methods: {
    onClick() {
      this.$emit('click');
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
