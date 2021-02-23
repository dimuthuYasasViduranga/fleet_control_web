<template>
  <div ref="container" class="loader-top-down-marker" @click="onClick">
    <svg
      id="scraper-top-down"
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
          id="wheel-front-right"
          ry="0.52916712"
          y="10.054166"
          x="20.108334"
          height="6.3500013"
          width="2.1166663"
          style="
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.10654604;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-front-left"
          ry="0.52916807"
          y="10.054165"
          x="11.641666"
          height="6.3500013"
          width="2.1166663"
          style="
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.10654604;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-back-right"
          ry="0.52916247"
          y="21.695837"
          x="20.637501"
          height="6.3500013"
          width="2.1166663"
          style="
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.10654604;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
          :style="getStyle('wheels')"
        />
        <rect
          id="wheel-back-left"
          ry="0.52916247"
          y="21.695837"
          x="11.112501"
          height="6.3500013"
          width="2.1166663"
          style="
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.10654604;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
          :style="getStyle('wheels')"
        />
        <!-- bucket -->
        <rect
          id="bucket"
          y="3.1484132"
          x="11.641666"
          height="4.2599196"
          width="10.583332"
          style="
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.1951354;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
          :style="getStyle('bucket')"
        />
        <!-- body -->
        <path
          id="body"
          d="M 14.816666,6.8791664 V 12.170833 L 13.758333,12.7 v 2.645833 l 1.5875,2.116667 v 0.529167 L 13.758333,19.05 v 2.116667 h -1.5875 v 6.35 l 1.058334,0.529166 h 1.587499 V 29.897916 31.75 H 19.05 v -3.704167 h 1.5875 l 1.058333,-0.529166 v -6.35 h -1.5875 V 19.05 l -1.5875,-1.058333 V 17.4625 l 1.5875,-2.116667 V 12.7 L 19.05,12.170833 V 6.8791664 h -4.233334"
          style="
            fill: #e8ba00;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.26458332px;
            stroke-linecap: butt;
            stroke-linejoin: miter;
            stroke-opacity: 1;
          "
          :style="getStyle('body')"
        />
        <rect
          y="21.695835"
          x="14.287496"
          height="5.2916675"
          width="5.2916698"
          id="cabin"
          style="
            fill: #4d4d4d;
            fill-opacity: 1;
            stroke: #1a1a1a;
            stroke-width: 0.15378599;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
          :style="getStyle('cabin')"
        />
        <rect
          id="bumper"
          y="30.691666"
          x="12.699997"
          height="1.0583346"
          width="8.4666691"
          style="
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.08699453;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
        />
        <!-- piston -->
        <rect
          id="piston-body"
          y="10.556746"
          x="16.404167"
          height="4.2599192"
          width="1.0583324"
          style="
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.06170721;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
        />
        <rect
          id="piston-arm"
          y="6.3058743"
          x="16.658548"
          height="4.2599192"
          width="0.52916592"
          style="
            fill: #999999;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.04363358;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
          "
          :style="getStyle('piston')"
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
  wheels: { fillColor: 'black' },
  bucket: { fillColor: 'black' },
  body: { fillColor: COLORS.yellow, strokeColor: 'black' },
  cabin: { fillColor: 'grey', strokeColor: 'black' },
  piston: { fillColor: 'grey' },
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
  name: 'LoaderTopDownMarker',
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
.loader-top-down-marker {
  cursor: pointer;
}
</style>
