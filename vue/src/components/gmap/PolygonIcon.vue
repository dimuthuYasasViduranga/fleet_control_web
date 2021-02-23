<template>
  <div class="wrapper">
    <div
      class="polygon-icon"
      :class="{ highlight: highlight }"
      v-tooltip="{
        classes: ['google-tooltip'],
        trigger: 'hover',
        content: 'Toggle Geofences',
        placement: tooltip,
      }"
    >
      <svg viewBox="0 0 128 128">
        <path d="m 32.000001,96 -16,-72.000001 L 64.000001,64 112,47.999999 V 112 Z" />
      </svg>
    </div>
  </div>
</template>

<script>
export default {
  name: 'PolygonIcon',
  props: {
    highlight: { type: Boolean, default: false },
    tooltip: { type: String, default: 'top' },
  },
};
</script>

<style>
.polygon-icon {
  height: 40px;
  width: 40px;
}

.polygon-icon svg {
  padding: 4px;
  cursor: pointer;
  stroke: black;
  fill: transparent;
  stroke-width: 5;
  background-color: white;
  border-radius: 2px;
  height: 100%;
  width: 100%;
}

.polygon-icon.highlight svg {
  background-color: rgb(189, 189, 189);
}

.tooltip.google-tooltip {
  display: block;
  z-index: 10000;
  font-family: Roboto, Arial, sans-serif;
}

.tooltip.google-tooltip .tooltip-inner {
  background: white;
  color: black;
  padding: 5px 10px 4px;
}
</style>