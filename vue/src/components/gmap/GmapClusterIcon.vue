<template>
  <div class="wrapper">
    <div
      class="gmap-cluster-icon"
      :class="{ highlight: highlight }"
      v-tooltip="{
        classes: ['google-tooltip'],
        trigger: 'hover',
        content: 'Toggle Icon Clustering',
        placement: tooltip,
      }"
    >
      <svg viewBox="0 0 22 22">
        <circle cx="11" cy="11" r="6.5" stroke-linejoin="round" />
        <path
          stroke-linejoin="round"
          d="M4 .5H.5V4M.5.5l4 4M18 .5h3.5V4m0-3.5l-4 4M4 21.5H.5V18m0 3.5l4-4m13.5 4h3.5V18m0 3.5l-4-4"
        />
      </svg>
    </div>
  </div>
</template>

<script>
export default {
  name: 'GmapClusterIcon',
  props: {
    highlight: { type: Boolean, default: false },
    tooltip: { type: String, default: 'top' },
  },
};
</script>

<style>
.gmap-cluster-icon {
  height: 40px;
  width: 40px;
}

.gmap-cluster-icon svg {
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

.gmap-cluster-icon.highlight svg {
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