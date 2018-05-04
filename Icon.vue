<template>
  <span class="icon-wrapper">
    <svg v-bind:viewBox="'0 0 ' + icon_size + ' ' + icon_size" class="icon">
      <component
        v-bind:is="icon"
        ></component>
    </svg>
  </span>
</template>

<script>
export default {
  name: 'icon',
  props: {
    icon: Object,
    icon_size: Number
  },
  methods: {
  }
}
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
