<template>
  <div
    class="reset-zoom-icon"
    v-tooltip="{
      classes: ['google-tooltip'],
      trigger: 'hover',
      content: 'Reset Zoom',
      placement: tooltip,
    }"
  >
    <svg viewBox="0 0 128 128">
      <circle r="36.46183" cy="48.502689" cx="50.021759" />
      <path d="m 69.497431,79.519503 37.445429,37.445427 8.7393,-8.73929 -36.978713,-36.978705" />
      <path
        d="m 30.044839,48.057712 a 21.158754,21.158754 0 0 1 15.769675,-20.430215 21.158754,21.158754 0 0 1 23.7875,10.011551 21.158754,21.158754 0 0 1 -3.585655,25.558157 21.158754,21.158754 0 0 1 -25.624082,3.079404"
      />
      <path d="m 24.319686,42.332557 5.725153,5.725154 5.755187,-5.755186" />
    </svg>
  </div>
</template>

<script>
export default {
  name: 'ResetZoomIcon',
  props: {
    tooltip: { type: String, default: 'top' },
  },
};
</script>

<style>
.reset-zoom-icon {
  height: 40px;
  width: 40px;
}

.reset-zoom-icon svg {
  padding: 2px;
  cursor: pointer;
  stroke: black;
  fill: transparent;
  stroke-width: 4;
  background-color: white;
  border-radius: 2px;
  height: 100%;
  width: 100%;
}

.reset-zoom-icon svg:hover {
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