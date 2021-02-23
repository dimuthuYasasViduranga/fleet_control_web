<template>
  <div ref="container" class="grader-top-down-marker" @click="onClick">
    <svg
      id="grader-top-down"
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
          id="wheel-1"
          ry="0.18014188"
          rx="0"
          y="1.5874994"
          x="10.054167"
          height="4.2333336"
          width="2.645833"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.20328555;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-2"
          ry="0.18014188"
          rx="0"
          y="21.695831"
          x="10.054167"
          height="4.2333336"
          width="2.645833"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.20328553;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-3"
          ry="0.18014188"
          rx="0"
          y="26.987499"
          x="10.054167"
          height="4.2333336"
          width="2.645833"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.20328552;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-4"
          ry="0.18014188"
          rx="0"
          y="26.987497"
          x="21.166666"
          height="4.2333336"
          width="2.645833"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.20328552;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-5"
          ry="0.18014188"
          rx="0"
          y="21.695824"
          x="21.166664"
          height="4.2333336"
          width="2.645833"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.20328552;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-6"
          ry="0.18014188"
          rx="0"
          y="1.5874996"
          x="21.166666"
          height="4.2333336"
          width="2.645833"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.20328552;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('wheels')"
        />
        <!-- body -->
        <rect
          id="blade"
          transform="rotate(-28.386175)"
          ry="0.13510641"
          y="18.196781"
          x="2.1062131"
          height="1.5875005"
          width="13.758333"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.27538708;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('blade')"
        />
        <!-- body -->
        <path
          id="body"
          d="M 12.7,4.7624997 15.875,5.820833 V 17.991666 H 12.7 v 4.233333 l -1.058333,1.5875 v 8.466667 H 22.225 v -8.466667 l -1.058333,-1.5875 V 17.991666 H 17.991666 V 5.820833 l 3.175,-1.0583333 1e-6,-2.1166667 H 12.7 Z"
          style="
            fill: #e8ba00;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.26458332px;
            stroke-linecap: butt;
            stroke-linejoin: miter;
            stroke-opacity: 1;
          "
          :style="getStyle('body')"
        />
        <rect
          id="cabin"
          y="19.049999"
          x="13.758335"
          height="5.8208332"
          width="6.349998"
          style="
            opacity: 1;
            fill: #666666;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.21077432;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('cabin')"
        />
        <rect
          id="engine"
          y="25.4"
          x="14.287499"
          height="5.8208313"
          width="5.291667"
          style="
            opacity: 1;
            fill: #d4aa00;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.19240975;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('engine')"
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
  blade: { fillColor: 'black' },
  engine: { fillColor: COLORS.darkYellow, strokeColor: 'black' },
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
  name: 'GraderTopDownMarker',
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
.grader-top-down-marker {
  cursor: pointer;
}
</style>
