<template>
  <div class="wrapper">
    <div
      class="gmap-alert-icon"
      :class="{ highlight: highlight }"
      v-tooltip="{
        classes: ['google-tooltip'],
        trigger: 'hover',
        content: 'Toggle Alerts',
        placement: tooltip,
      }"
    >
      <svg viewBox="0 -1 30 30">
        <path
          d="M14.27.69a1.5 1.5 0 0 1 2 .58l13 22.94A1.53 1.53 0 0 1 28 26.5H2a1.53 1.53 0 0 1-1.3-2.29l13-22.94a1.5 1.5 0 0 1 .57-.58zM15 17.5h1.56l.78-7.07h-4.68l.78 7.07zm-1.4 5.34h2.81v-3.42H13.6z"
        />
      </svg>
    </div>
  </div>
</template>

<script>
export default {
  name: 'GmapAlertIcon',
  props: {
    highlight: { type: Boolean, default: false },
    tooltip: { type: String, default: 'top' },
  },
};
</script>

<style>
.gmap-alert-icon {
  height: 40px;
  width: 40px;
}

.gmap-alert-icon svg {
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

.gmap-alert-icon.highlight svg {
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