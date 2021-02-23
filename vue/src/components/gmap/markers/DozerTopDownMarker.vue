<template>
  <div ref="container" class="dozer-top-down-marker" @click="onClick">
    <svg
      id="dozer-top-down"
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
        <!-- tracks -->
        <rect
          id="track-left"
          ry="0.96826255"
          rx="0"
          y="6.8791666"
          x="9.5249996"
          height="22.754166"
          width="3.7041671"
          :style="getStyle('tracks')"
        />
        <rect
          id="track-right"
          ry="0.96826255"
          rx="0"
          y="6.8791666"
          x="20.637499"
          height="22.754166"
          width="3.7041671"
          :style="getStyle('tracks')"
        />
        <!-- body -->
        <path
          id="body"
          d="m 11.1125,28.575001 v -9.525 l 2.116667,-1.5875 V 7.4083332 H 20.6375 V 17.462501 l 2.116667,1.5875 v 9.525 z"
          :style="getStyle('body')"
        />
        <rect
          id="cabin"
          y="20.10833"
          x="12.7"
          height="6.8791666"
          width="8.4666672"
          :style="getStyle('cabin')"
        />
        <!-- ripper -->
        <rect
          id="ripper"
          y="28.575005"
          x="15.345833"
          height="3.175"
          width="3.2407885"
          :style="getStyle('ripper')"
        />
        <!-- blade -->
        <rect
          id="arm-left"
          y="5.2916708"
          x="7.9374976"
          height="11.112501"
          width="1.587499"
          :style="getStyle('arms')"
        />
        <rect
          id="arm-right"
          y="5.2916698"
          x="24.34166"
          height="11.112501"
          width="1.5874989"
          :style="getStyle('arms')"
        />
        <path
          id="blade"
          d="M 7.9374999,5.2916527 5.2916666,1.5874878 H 28.575 l -2.645833,3.7041649 z"
          :style="getStyle('blade')"
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
  ripper: { fillColor: COLORS.yellow, strokeColor: 'black' },
  body: { fillColor: COLORS.yellow, strokeColor: 'black' },
  blade: { fillColor: 'black' },
  arms: { fillColor: COLORS.yellow, strokeColor: 'black' },
  cabin: { fillColor: 'grey', strokeColor: 'black' },
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
  name: 'DozerTopDownMarker',
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
.dozer-top-down-marker {
  cursor: pointer;
}
</style>
