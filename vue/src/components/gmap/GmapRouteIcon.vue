<template>
  <div class="wrapper">
    <div
      class="gmap-route-icon"
      :class="{ highlight: highlight }"
      v-tooltip="{
        classes: ['google-tooltip'],
        trigger: 'hover',
        content: 'Toggle Routing',
        placement: tooltip,
      }"
    >
      <svg viewBox="0 0 22 22">
        <circle cx="2" cy="6" r="2" />
        <circle cx="20" cy="6" r="2" />
        <line x1="3" y1="6" x2="19" y2="6" />

        <circle cx="2" cy="16" r="2" />
        <circle cx="20" cy="16" r="2" />
        <line x1="3" y1="16" x2="19" y2="16" />
      </svg>
    </div>
  </div>
</template>

<script>
export default {
  name: 'GmapRouteIcon',
  props: {
    highlight: { type: Boolean, default: false },
    tooltip: { type: String, default: 'top' },
  },
};
</script>

<style>
.gmap-route-icon {
  height: 40px;
  width: 40px;
}

.gmap-route-icon svg {
  padding: 4px;
  cursor: pointer;
  stroke: black;
  fill: transparent;
  stroke-width: 0.75;
  background-color: white;
  border-radius: 2px;
  height: 100%;
  width: 100%;
}

.gmap-route-icon.highlight svg {
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