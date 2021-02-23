<template>
  <div ref="container" class="water-cart-top-down-marker" @click="onClick">
    <svg
      id="water-cart-top-down"
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
        <!-- wheels -->
        <rect
          id="wheel-back-right"
          y="21.034372"
          x="25.4"
          height="5.8208332"
          width="1.0583335"
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-front-right"
          y="12.567699"
          x="25.4"
          height="5.8208332"
          width="1.0583335"
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-front-left"
          y="12.567699"
          x="7.4083362"
          height="5.8208332"
          width="1.0583335"
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-back-left"
          y="21.034372"
          x="7.4083362"
          height="5.8208332"
          width="1.0583335"
          :style="getStyle('wheels')"
        />
        <!-- body -->
        <rect
          id="platform"
          y="5.6885705"
          x="8.9958334"
          height="7.0114298"
          width="15.875001"
          :style="getStyle('platform')"
        />
        <rect
          id="radiator"
          y="3.7041683"
          x="13.758333"
          height="1.0583316"
          width="6.349999"
          :style="getStyle('radiator')"
        />
        <rect
          id="radiator-grill"
          ry="1.2603507e-05"
          y="3.7041664"
          x="14.816667"
          height="0.52916664"
          width="4.2333331"
        />
        <rect
          id="front-bar"
          y="4.7625117"
          x="9.5249996"
          height="1.0583212"
          width="14.816667"
          :style="getStyle('frontBar')"
        />
        <rect y="6.8791661" x="11.046353" height="4.2333331" width="3.7703128" id="cabin" />
        <!-- lights -->
        <rect
          id="light-left"
          y="3.7041664"
          x="8.9958334"
          height="0.52917808"
          width="1.5875"
          :style="getStyle('lights')"
        />
        <rect
          id="light-right"
          y="3.7041664"
          x="23.283333"
          height="0.52917808"
          width="1.5875"
          :style="getStyle('lights')"
        />
        <path
          id="light-pole-left"
          d="M 9.5249995,5.8208297 V 4.7624998 h -0.529166 v -0.52917 h 1.5875005 v 0.52917 h -0.529167 v 1.0583299 z"
          :style="getStyle('lightPoles')"
        />
        <path
          id="light-pole-right"
          d="M 23.8125,5.8208331 V 4.7625032 h -0.529167 v -0.52917 h 1.5875 v 0.52917 h -0.529167 v 1.0583299 z"
          :style="getStyle('lightPoles')"
        />
        <!-- railing -->

        <rect
          ry="1.2603507e-05"
          y="5.2916665"
          x="8.9958334"
          height="0.52916664"
          width="15.875001"
          id="rail-front"
          :style="getStyle('railing')"
        />
        <rect
          id="railing-left"
          ry="0.00016699672"
          y="5.6885314"
          x="8.9958353"
          height="7.0114684"
          width="0.52916384"
          :style="getStyle('railing')"
        />
        <rect
          id="railing-right"
          ry="0.00017644912"
          y="5.2916665"
          x="24.341669"
          height="7.4083333"
          width="0.52916384"
          :style="getStyle('railing')"
        />
        <!-- tank -->
        <rect
          id="tank"
          y="10.054165"
          x="8.4666662"
          height="17.991665"
          width="16.933332"
          :style="getStyle('tank')"
        />
        <rect
          id="hatch-top-left"
          y="12.7"
          x="10.583333"
          height="4.2333322"
          width="4.2333336"
          :style="getStyle('hatch')"
        />
        <rect
          id="hatch-top-right"
          y="12.7"
          x="19.049999"
          height="4.2333322"
          width="4.233335"
          :style="getStyle('hatch')"
        />
        <rect
          id="hatch-bottom-right"
          y="21.166666"
          x="19.049999"
          height="4.2333326"
          width="4.2333331"
          :style="getStyle('hatch')"
        />
        <rect
          id="hatch-bottom-left"
          y="21.166666"
          x="10.583332"
          height="4.2333331"
          width="4.2333345"
          :style="getStyle('hatch')"
        />

        <!-- water pipes -->
        <rect
          id="water-pipes"
          ry="1.4178945e-05"
          y="28.575003"
          x="8.9958324"
          height="0.59531248"
          width="15.875"
          :style="getStyle('pipes')"
        />
        <rect
          id="pipe-join"
          ry="1.2603507e-05"
          y="28.045834"
          x="14.816667"
          height="0.52916664"
          width="4.2333331"
          :style="getStyle('pipes')"
        />
        <rect
          id="pipe-out-1"
          ry="2.520698e-05"
          y="29.104168"
          x="10.054167"
          height="1.058332"
          width="1.0583335"
          :style="getStyle('pipes')"
        />
        <rect
          id="pipe-out-2"
          ry="2.520698e-05"
          y="29.104168"
          x="13.229166"
          height="1.058332"
          width="1.0583335"
          :style="getStyle('pipes')"
        />
        <rect
          id="pipe-out-3"
          ry="2.520698e-05"
          y="29.104168"
          x="16.404165"
          height="1.058332"
          width="1.0583335"
          :style="getStyle('pipes')"
        />
        <rect
          id="pipe-out-4"
          ry="2.520698e-05"
          y="29.104168"
          x="19.579165"
          height="1.058332"
          width="1.0583335"
          :style="getStyle('pipes')"
        />
        <rect
          id="pipe-out-5"
          ry="2.520698e-05"
          y="29.104168"
          x="22.754166"
          height="1.058332"
          width="1.0583335"
          :style="getStyle('pipes')"
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
  platform: { fillColor: COLORS.yellow },
  tank: { fillColor: COLORS.yellow, strokeColor: 'black' },
  hatch: { fillColor: COLORS.darkYellow },
  lightPoles: { fillColor: COLORS.yellow },
  lights: { fillColor: 'grey' },
  pipes: { fillColor: 'black' },
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
  name: 'WaterCartTopDownMarker',
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
.water-cart-top-down-marker {
  cursor: pointer;
}
</style>
