<template>
  <div class="wrapper" @click="onToggle()">
    <div
      class="gmap-my-position-icon"
      :class="{ highlight: !usingMyLocation }"
      v-tooltip="{
        classes: ['google-tooltip'],
        trigger: 'hover',
        content: label,
        placement: tooltip,
      }"
    >
      <svg viewBox="0 0 128 128">
        <path d="M 30.189073,64.4088 64.162853,123.25311 98.925849,64.4088" />
        <path
          d="m 30.468389,64.889974 a 39.248539,39.34531 0 0 1 8.778467,-49.557951 39.248539,39.34531 0 0 1 50.208183,-0.352905 39.248539,39.34531 0 0 1 9.470815,49.42968"
        />
        <ellipse ry="23" rx="23" cy="45" cx="64" />
      </svg>
    </div>
  </div>
</template>

<script>
export default {
  name: 'GmapMyPositionIcon',
  props: {
    tooltip: { type: String, default: 'top' },
  },
  computed: {
    usingMyLocation() {
      return this.$geolocation.watching;
    },
    label() {
      if (this.usingMyLocation) {
        return 'Stop My Location';
      }

      return 'Use My Location';
    },
  },
  methods: {
    onToggle() {
      if (this.usingMyLocation) {
        this.$geolocation.unwatch();
      } else {
        this.$geolocation.watch().catch(() => {
          alert(
            'Location access is denied, please enable it for this website if you want to show your position',
          );
        });
      }
    },
  },
};
</script>

<style>
.gmap-my-position-icon {
  height: 40px;
  width: 40px;
}

.gmap-my-position-icon svg {
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

.gmap-my-position-icon.highlight svg {
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