<template>
  <div ref="container" class="drill-top-down-marker" @click="onClick">
    <svg
      id="drill-top-down"
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
          y="7.9374995"
          x="10.583336"
          height="22.754166"
          width="5.2916675"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.66651618;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('tracks')"
        />
        <rect
          id="track-right"
          ry="0.96826255"
          rx="0"
          y="7.9374995"
          x="17.4625"
          height="22.754166"
          width="5.2916675"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.66651618;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('tracks')"
        />
        <rect
          id="chassis"
          ry="0.96826255"
          rx="0"
          y="7.9374995"
          x="12.7"
          height="22.754166"
          width="8.4666643"
          style="
            opacity: 1;
            fill: #666666;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.84308356;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('chassis')"
        />
        <!-- body -->
        <path
          id="body"
          d="M 11.641667,6.8791664 H 21.695833 V 32.279165 H 11.641667 v -8.792308 l 4.762499,-1.953846 c 0,-3.41923 0,1.018274 0,-9.76923 L 11.641667,10.298397 V 6.8791664"
          style="
            fill: #e8ba00;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.25420344px;
            stroke-linecap: butt;
            stroke-linejoin: miter;
            stroke-opacity: 1;
          "
          :style="getStyle('body')"
        />
        <rect
          id="cabin"
          y="24.870831"
          x="12.170834"
          height="4.7624998"
          width="4.7624984"
          style="
            opacity: 1;
            fill: #666666;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.30492824;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('cabin')"
        />
        <!-- drill -->
        <rect
          id="drill"
          y="4.2333331"
          x="17.396713"
          height="27.003681"
          width="3.2407885"
          style="
            opacity: 1;
            fill: #b28e00;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.23069903;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('drill')"
        />
        <rect
          id="drill-tip"
          y="2.645833"
          x="17.991667"
          height="1.5875"
          width="2.1166666"
          style="
            opacity: 1;
            fill: #666666;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.24897291;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('drillTip')"
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
  tracks: { fillColor: 'black' },
  chassis: { fillColor: 'grey' },
  body: { fillColor: COLORS.yellow, strokeColor: 'black' },
  drill: { fillColor: COLORS.darkYellow, strokeColor: 'black' },
  drillTip: { fillColor: 'grey', strokeColor: 'black' },
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
  name: 'DrillTopDown',
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
.drill-top-down-marker {
  cursor: pointer;
}
</style>
