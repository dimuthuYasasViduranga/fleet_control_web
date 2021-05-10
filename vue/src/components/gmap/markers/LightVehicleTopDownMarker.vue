<template>
  <div ref="container" class="light-vehicle-top-down-marker" @click="onClick">
    <svg
      id="light-vehicle-top-down"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:cc="http://creativecommons.org/ns#"
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:svg="http://www.w3.org/2000/svg"
      xmlns="http://www.w3.org/2000/svg"
      version="1.1"
      viewBox="0 0 33.866666 33.866666"
      :height="scaledHeight"
      :width="scaledWidth"
    >
      <g>
        <path
          id="body"
          d="M 12.088151,16.445508 12.154297,9.3761715 11.641666,8.5658851 V 4.266406 c 0.713785,-1.0755576 1.3328,-2.1777174 5.506641,-2.2820313 3.475338,0.073665 5.475906,0.7793682 5.655469,2.2654948 v 4.365625 l -0.40712,0.7051526 0.0248,7.1331279 z"
          style="stroke-width: 0.26458332px"
          :style="getStyle('body')"
        />
        <!-- windows -->

        <path
          id="windscreen"
          d="M 13.728319,11.886585 12.72673,8.6838668 c 2.896022,-0.9523186 5.912792,-0.8869063 9.027028,0 l -0.866349,3.2332602 z"
          style="stroke-width: 0.26458332px"
          :style="getStyle('windows')"
        />
        <path
          id="window-left"
          d="m 12.582836,11.259413 h 0.529167 l 0.479557,1.752865 -0.01654,2.645833 -0.992188,-0.380338 z"
          style="stroke-width: 0.26458332px"
          :style="getStyle('windows')"
        />
        <path
          id="window-right"
          d="m 22.056164,11.317473 h -0.529167 l -0.479557,1.752865 0.01654,2.645833 0.992188,-0.380338 z"
          style="stroke-width: 0.26458332px"
          :style="getStyle('windows')"
        />
        <!-- mirrors -->
        <path
          id="mirror-left"
          d="m 12.13776,10.202994 -1.220828,0.32712 v 0.722945 l 1.198182,-0.321051 z"
          style="stroke-width: 0.26458332px"
          :style="getStyle('mirrors')"
        />
        <path
          id="mirror-right"
          d="m 22.400845,10.080815 1.204292,0.343656 v 0.722945 l -1.198182,-0.321051 z"
          style="stroke-width: 0.26458332px"
          :style="getStyle('mirrors')"
        />
        <!-- tray -->
        <path
          id="tray"
          d="m 12.055078,16.834114 v 4.803841 l -0.289102,1.078943 c 0,0 0.05174,3.620611 0,3.650484 -0.05174,0.02987 0.301485,1.125157 0.301485,1.125157 v 3.37276 l 0.715221,1.265039 h 8.995833 l 0.677995,-1.322917 v -3.389974 l 0.333618,-1.245078 v -3.773737 l -0.336946,-1.2575 V 16.90026 Z"
          style="stroke-width: 0.26458332px"
          :style="getStyle('tray')"
        />
        <rect
          y="17.734282"
          x="12.983976"
          height="13.259909"
          width="8.6060791"
          id="tray-inlay"
          style="stroke-width: 0.26458332"
          :style="getStyle('tray-inlay')"
        />
      </g>
    </svg>
  </div>
</template>

<script>
const COLORS = {
  white: 'white',
  gray: '#131313',
};

const DEFAULT_COLORS = {
  body: { fillColor: COLORS.white },
  windows: { fillColor: COLORS.gray, 'stroke-opacity': 0 },
  mirrors: { fillColor: COLORS.white },
  tray: { fillColor: COLORS.white },
  'tray-inlay': { fillColor: COLORS.gray },
};

const DEFAULT_ORIGIN = {
  x: 0.5,
  y: 0.5,
};

function getOpts(map) {
  return {
    stroke: map.strokeColor || map.color,
    fill: map.fillColor || map.color,
    'stroke-opacity': map.strokeOpacity || map.opacity || 1,
    'fill-opacity': map.fillOpacity || map.opacity || 1,
  };
}

function mergeColors(defaultColors, colors = {}) {
  const cols = {};
  Object.keys(defaultColors).forEach(attrib => {
    cols[attrib] = { ...defaultColors[attrib], ...(colors[attrib] || {}) };
  });
  return cols;
}

export default {
  name: 'LightVehicleTopDownMarker',
  props: {
    scale: { type: Number, default: 1 },
    colors: { type: Object, default: () => ({}) },
    origin: { type: Object, default: () => DEFAULT_ORIGIN },
    rotationOrigin: { type: Object, default: null },
    rotation: { type: Number, default: 0 },
  },
  data: () => {
    return {
      width: 128,
      height: 128,
      baseScale: 0.5,
    };
  },
  computed: {
    scaledWidth() {
      return this.width * this.scale * this.baseScale;
    },
    scaledHeight() {
      return this.height * this.scale * this.baseScale;
    },
  },
  watch: {
    origin() {
      this.setTranslation();
    },
    rotationOrigin() {
      this.setTranslation();
    },
    scale() {
      this.setTranslation();
    },
    rotation() {
      this.setTranslation();
    },
  },
  mounted() {
    this.setTranslation();
  },
  methods: {
    onClick() {
      this.$emit('click');
    },
    getStyle(id) {
      const colors = mergeColors(DEFAULT_COLORS, this.colors);
      const opts = getOpts(colors[id] || {});
      return Object.entries(opts)
        .map(([key, value]) => `${key}:${value}`)
        .join(';');
    },
    setTranslation() {
      const container = this.$refs.container;

      // calculate the rotation origin
      const rotationOrigin = this.rotationOrigin || this.origin;
      const xO = rotationOrigin.x;
      const yO = rotationOrigin.y;
      const transformOrigin = `${xO * 100}% ${yO * 100}%`;

      const transform = `rotate(${this.rotation}deg)`;

      container.style.transform = transform;
      container.style.transformOrigin = transformOrigin;
    },
  },
};
</script>

<style>
.light-vehicle-top-down-marker {
  cursor: pointer;
}
</style>
