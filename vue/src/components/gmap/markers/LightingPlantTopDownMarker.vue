<template>
  <div ref="container" class="lighting-plant-top-down-marker" @click="onClick">
    <svg
      id="lighting-plant-top-down"
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
        <!-- lights -->
        <rect
          y="4.2730818"
          x="9.7406902"
          height="2.2061298"
          width="2.9132228"
          id="light-left"
          style="stroke-width: 0.26458332"
          :style="getStyle('lights')"
        />
        <rect
          y="4.2922397"
          x="15.612008"
          height="2.2061298"
          width="2.9132228"
          id="light-middle"
          style="stroke-width: 0.26458332"
          :style="getStyle('lights')"
        />
        <rect
          y="4.2896185"
          x="21.216972"
          height="2.2061298"
          width="2.9132228"
          id="light-right"
          style="stroke-width: 0.26458332"
          :style="getStyle('lights')"
        />
        <!-- frame -->
        <rect
          y="7.1902795"
          x="9.7076178"
          height="1.9599262"
          width="14.488721"
          id="light-top"
          style="stroke-width: 0.26458332"
          :style="getStyle('body')"
        />
        <!-- mast -->
        <rect
          y="9.1333389"
          x="14.669283"
          height="2.3758318"
          width="4.9213662"
          id="light-mast"
          style="stroke-width: 0.26458332"
          :style="getStyle('mast')"
        />
        <!-- body -->
        <rect
          y="11.61884"
          x="11.077126"
          height="15.519694"
          width="12.15976"
          id="body"
          style="stroke-width: 0.26458332"
          :style="getStyle('body')"
        />
        <!-- generator -->
        <rect
          y="15.433565"
          x="12.437099"
          height="10.344995"
          width="9.4398136"
          id="generator"
          style="stroke-width: 0.26458332"
          :style="getStyle('generator')"
        />
        <!-- wheels -->
        <rect
          y="13.298806"
          x="23.476881"
          height="7.0398612"
          width="1.2799751"
          id="wheel-right"
          style="stroke-width: 0.26458332"
          :style="getStyle('wheels')"
        />
        <rect
          y="13.298806"
          x="9.4771585"
          height="7.0398612"
          width="1.2799751"
          id="wheel-left"
          style="stroke-width: 0.26458332"
          :style="getStyle('wheels')"
        />
        <!-- hitch -->
        <rect
          y="27.252924"
          x="16.158064"
          height="4.5156541"
          width="2.1886466"
          id="hitch"
          style="stroke-width: 0.26458332"
          :style="getStyle('hitch')"
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
  body: { fillColor: COLORS.yellow, strokeColor: 'black' },
  generator: { fillColor: COLORS.darkYellow, strokeColor: 'black' },
  lights: { fillColor: 'white', strokeColor: 'black' },
  hitch: { fillColor: COLORS.yellow, strokeColor: 'black' },
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
  name: 'LightingPlantTopDownMarker',
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
.lighting-plant-top-down-marker {
  cursor: pointer;
}
</style>
