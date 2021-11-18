<template>
  <div
    class="recenter-icon"
    v-tooltip="{
      classes: ['google-tooltip'],
      trigger: 'hover',
      content: label,
      placement: tooltip,
    }"
  >
    <svg viewBox="0 0 128 128">
      <circle r="53.36528" cy="63.999996" cx="63.881943" />
      <path d="M 25.76389,64 H 56.258334" />
      <path d="M 48.634724,56.376387 56.258334,64" />
      <path d="M 48.634724,71.623612 56.258334,64" />
      <path d="M 63.881947,25.881942 V 56.376387" />
      <path d="M 102,64 H 71.505559" />
      <path d="M 63.881947,102.11805 V 71.623612" />
      <path d="m 56.258334,79.247221 7.623613,-7.623609 7.623612,7.623609" />
      <path d="M 79.129172,71.623612 71.505559,64 79.129168,56.376387" />
      <path d="m 71.505559,48.752777 -7.623612,7.62361 -7.623613,-7.62361" />
    </svg>
  </div>
</template>

<script>
export default {
  name: 'RecenterIcon',
  props: {
    label: {type: String, default: 'Re-Center'},
    tooltip: { type: String, default: 'top' },
  },
};
</script>

<style>
.recenter-icon {
  height: 40px;
  width: 40px;
}

.recenter-icon svg {
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

.recenter-icon svg:hover {
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