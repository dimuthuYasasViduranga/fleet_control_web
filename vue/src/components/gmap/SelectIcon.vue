<template>
  <div
    class="select-icon"
    :class="{ highlight: highlight }"
    v-tooltip="{
      classes: ['google-tooltip'],
      trigger: 'hover',
      content: label,
      placement: tooltip,
    }"
  >
    <svg viewBox="0 0 128 128">
      <rect y="13.700002" x="12.7" height="100" width="100" style="stroke-dasharray: 8, 8" />
      <path d="M 42,64 H 89" />
      <path d="M 65,43 V 86" />
    </svg>
  </div>
</template>

<script>
export default {
  name: 'SelectIcon',
  props: {
    highlight: { type: Boolean, default: false },
    label: { type: String, default: 'Select' },
    tooltip: { type: String, default: 'top' },
  },
};
</script>

<style>
.select-icon {
  height: 40px;
  width: 40px;
}

.select-icon svg {
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

.select-icon.highlight svg {
  background-color: rgb(189, 189, 189);
}

.select-icon svg:hover {
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