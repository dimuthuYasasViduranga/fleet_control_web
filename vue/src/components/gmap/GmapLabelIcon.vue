<template>
  <div class="wrapper">
    <div
      class="gmap-label-icon"
      :class="{ highlight: highlight }"
      v-tooltip="{
        classes: ['google-tooltip'],
        trigger: 'hover',
        content: 'Toggle Labels',
        placement: tooltip,
      }"
    >
      <svg viewBox="0 -2 30 30">
        <path
          d="M12.78 27.69L.5 15.41 15.38.5h12.31v12.31zM21.99 4a2.19 2.19 0 0 0-2.19 2.19 2.19 2.19 0 0 0 2.19 2.19 2.19 2.19 0 0 0 2.19-2.19A2.19 2.19 0 0 0 21.99 4z"
          stroke-linejoin="round"
        />
      </svg>
    </div>
  </div>
</template>

<script>
export default {
  name: 'GmapLabelIcon',
  props: {
    highlight: { type: Boolean, default: false },
    tooltip: { type: String, default: 'top' },
  },
};
</script>

<style>
.gmap-label-icon {
  height: 40px;
  width: 40px;
}

.gmap-label-icon svg {
  padding: 4px;
  cursor: pointer;
  stroke: black;
  fill: transparent;
  stroke-width: 1;
  background-color: white;
  border-radius: 2px;
  height: 100%;
  width: 100%;
}

.gmap-label-icon.highlight svg {
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