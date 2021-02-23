<template>
  <div ref="container" class="excavator-top-down-marker" @click="onClick">
    <svg
      id="excavator-top-down"
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
          id="trackLeft"
          y="11.514582"
          x="7.9375"
          height="21.431261"
          width="2.6458337"
          style="
            stroke-width: 0.80274582;
            stroke-linejoin: bevel;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
          "
          :style="getStyle('tracks')"
        />
        <rect
          id="trackRight"
          y="11.514582"
          x="23.283331"
          height="21.431261"
          width="2.6458337"
          style="
            stroke-width: 0.80274582;
            stroke-linejoin: bevel;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
          "
          :style="getStyle('tracks')"
        />
        <path
          id="body"
          d="m 10.054164,17.60001 h 3.439585 1.719792 1.719792 3.439583 3.439584 v 12.316807 l -2.392754,1.97069 -8.972825,2e-6 -2.392754,-1.970689 V 17.600011"
          style="stroke-width: 0.27143639px; stroke-linecap: butt; stroke-linejoin: miter"
          :style="getStyle('body')"
        />
        <path
          id="bucket"
          d="m 14.287499,4.370843 h 5.291667 L 18.520833,0.6666764 h -3.175001 z"
          style="stroke-width: 0.22136636px; stroke-linecap: butt; stroke-linejoin: miter"
          :style="getStyle('bucket')"
        />
        <rect
          id="cabin"
          y="14.42501"
          x="8.655652"
          height="7.4083285"
          width="5.6318479"
          style="stroke-width: 0.18771964; stroke-miterlimit: 4; stroke-dasharray: none"
          :style="getStyle('cabin')"
        />
        <rect
          id="boom"
          y="4.0401945"
          x="15.345833"
          height="15.676481"
          width="3.1749973"
          style="stroke-width: 0.20503131; stroke-miterlimit: 4; stroke-dasharray: none"
          :style="getStyle('boom')"
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
  tracks: { color: 'black' },
  body: { fillColor: COLORS.yellow, strokeColor: COLORS.darkYellow },
  cabin: { fillColor: COLORS.yellow, strokeColor: COLORS.darkYellow },
  boom: { fillColor: COLORS.yellow, strokeColor: COLORS.darkYellow },
  bucket: { color: 'black' },
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
  name: 'ExcavatorTopDownMarker',
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
.excavator-top-down-marker {
  cursor: pointer;
}
</style>
