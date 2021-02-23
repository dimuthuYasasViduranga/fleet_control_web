<template>
  <div ref="container" class="haul-truck-top-down-marker" @click="onClick">
    <svg
      id="haul-truck-top-down"
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
        <rect
          id="wheelBackRight"
          y="24.21459"
          x="24.870832"
          height="5.8208332"
          width="1.0583335"
          style="
            stroke-width: 0.26458332;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheelFrontRight"
          y="11.514582"
          x="24.870832"
          height="5.8208332"
          width="1.0583335"
          style="
            stroke-width: 0.26458332;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheelFrontLeft"
          y="11.514582"
          x="7.9375"
          height="5.8208332"
          width="1.0583335"
          style="
            stroke-width: 0.26458332;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheelBackLeft"
          y="24.21459"
          x="7.9375"
          height="5.8208332"
          width="1.0583335"
          style="
            stroke-width: 0.26458332;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="head"
          y="4.1062851"
          x="7.9375"
          height="6.8791609"
          width="17.991667"
          style="stroke-width: 0.32331631; stroke-miterlimit: 4; stroke-dasharray: none"
          :style="getStyle('head')"
        />
        <rect
          id="tray"
          y="10.985437"
          x="8.9958296"
          height="20.108355"
          width="15.875"
          style="stroke-width: 0.22300006; stroke-miterlimit: 4; stroke-dasharray: none"
          :style="getStyle('tray')"
        />
        <path
          id="trayInlay"
          d="m 11.641669,11.514596 -1.5875,18.520827 h 13.758335 l -1.5875,-18.520827 H 11.641669"
          style="stroke-width: 0.26088268px; stroke-linecap: butt; stroke-linejoin: miter"
          :style="getStyle('trayInlay')"
        />
        <rect
          id="blackBar"
          ry="1.2603507e-05"
          y="3.5770798"
          x="7.9375"
          height="0.52916664"
          width="17.991669"
          style="
            fill: #000000;
            stroke: none;
            stroke-width: 0.68994892;
            stroke-linecap: square;
            stroke-linejoin: miter;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
        />
        <rect
          id="frontBar"
          y="3.0479355"
          x="9.5249968"
          height="0.52915406"
          width="14.816667"
          style="stroke-width: 0.08137491; stroke-miterlimit: 4; stroke-dasharray: none"
          :style="getStyle('frontBar')"
        />
        <rect
          id="radiator"
          y="1.9895897"
          x="13.758328"
          height="1.0583316"
          width="6.349999"
          style="stroke-width: 0.07533934; stroke-miterlimit: 4; stroke-dasharray: none"
          :style="getStyle('radiator')"
        />
        <rect
          id="radiatorGrill"
          y="1.9895897"
          x="14.816663"
          height="0.52916664"
          width="4.2333331"
          style="
            fill: #000000;
            stroke: none;
            stroke-width: 0.33467436;
            stroke-linecap: square;
            stroke-linejoin: miter;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
        />
        <rect
          id="lightLeft"
          y="1.9895897"
          x="8.4666672"
          height="0.52917808"
          width="1.5875"
          style="stroke-width: 0.02663679; stroke-miterlimit: 4; stroke-dasharray: none"
          :style="getStyle('lights')"
        />
        <rect
          id="lightRight"
          y="1.9895897"
          x="23.812506"
          height="0.52917808"
          width="1.5875"
          style="stroke-width: 0.02663679; stroke-miterlimit: 4; stroke-dasharray: none"
          :style="getStyle('lights')"
        />
        <path
          id="lightPoleLeft"
          d="m 8.9958346,4.1062572 v -1.05833 h -0.529166 v -0.52917 h 1.5875004 v 0.52917 H 9.5250016 v 1.05833 z"
          style="stroke-width: 0.26458332px; stroke-linecap: butt; stroke-linejoin: miter"
          :style="getStyle('lightPoles')"
        />
        <path
          id="lightPoleRight"
          d="m 24.341671,4.1062572 v -1.05833 h -0.529167 v -0.52917 h 1.5875 v 0.52917 h -0.529167 v 1.05833 z"
          style="stroke-width: 0.26458332px; stroke-linecap: butt; stroke-linejoin: miter"
          :style="getStyle('lightPoles')"
        />
      </g>
    </svg>
  </div>
</template>

<script>
const COLORS = {
  yellow: '#ffcc00',
  darkYellow: '#aa8800',
};

const DEFAULT_COLORS = {
  wheels: { color: 'black' },
  frontBar: { fillColor: COLORS.yellow },
  radiator: { fillColor: COLORS.yellow },
  head: { fillColor: COLORS.yellow, strokeColor: COLORS.darkYellow },
  tray: { fillColor: COLORS.yellow, strokeColor: COLORS.darkYellow },
  trayInlay: { fillColor: COLORS.darkYellow },
  lightPoles: { fillColor: COLORS.yellow },
  lights: { fillColor: 'grey' },
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
  name: 'HaulTruckTopDownMarker',
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
.haul-truck-top-down-marker {
  cursor: pointer;
}
</style>
