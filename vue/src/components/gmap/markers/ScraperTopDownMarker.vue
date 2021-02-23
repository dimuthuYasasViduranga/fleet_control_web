<template>
  <div ref="container" class="scraper-top-down-marker" @click="onClick">
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
          id="wheel-1"
          ry="0.58207756"
          rx="0.44097206"
          y="25.929167"
          x="19.050001"
          height="5.8208337"
          width="2.6458323"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.23837338;
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
          ry="0.5820775"
          rx="0.44097206"
          y="25.929167"
          x="12.170835"
          height="5.8208337"
          width="2.6458323"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.23837338;
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
          ry="0.58207744"
          rx="0.44097206"
          y="7.4083328"
          x="11.64167"
          height="5.8208337"
          width="2.6458323"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.23837338;
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
          ry="0.58207744"
          rx="0.44097206"
          y="7.4083333"
          x="19.57917"
          height="5.8208337"
          width="2.6458323"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.23837338;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('wheels')"
        />
        <!-- bucket -->
        <path
          id="bucket"
          d="m 10.583333,14.2875 v 6.879166 l 0.907142,5.291667 h 3.628572 v 5.820833 h 3.62857 v -5.820833 h 3.628573 l 0.907143,-5.291667 V 14.2875 Z"
          style="
            fill: #e8ba00;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.34642091px;
            stroke-linecap: butt;
            stroke-linejoin: miter;
            stroke-opacity: 1;
          "
          :style="getStyle('bucket')"
        />
        <path
          id="bucket-inner"
          d="M 11.641667,15.345833 H 22.225 v 5.820833 L 21.166665,25.4 12.7,25.399999 11.641667,21.166666 Z"
          style="
            fill: #b28e00;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.37417731px;
            stroke-linecap: butt;
            stroke-linejoin: miter;
            stroke-opacity: 1;
          "
          :style="getStyle('bucketInner')"
        />
        <!-- tractor -->
        <path
          id="tractor-body"
          d="M 15.240001,1.5874997 V 2.6458331 L 12.7,3.7041664 v 4.7624999 h 0.846666 v 4.7624997 h 1.693335 v -2.645833 h 3.386664 v 2.645833 h 1.693334 V 8.4666663 h 0.846667 V 3.7041664 L 18.626665,2.6458331 V 1.5874997 Z"
          style="
            fill: #e8ba00;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.33467433px;
            stroke-linecap: butt;
            stroke-linejoin: miter;
            stroke-opacity: 1;
          "
          :style="getStyle('body')"
        />
        <rect
          id="bucket-arm"
          ry="0"
          rx="0"
          y="9.5250006"
          x="15.874998"
          height="5.291666"
          width="2.1166673"
          style="
            opacity: 1;
            fill: #e8ba00;
            fill-opacity: 1;
            stroke: #000000;
            stroke-width: 0.42084101;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
          :style="getStyle('bucketArm')"
        />
        <rect
          id="bumper"
          ry="0"
          rx="0"
          y="1.058333"
          x="13.758333"
          height="0.5291667"
          width="6.3499994"
          style="
            opacity: 1;
            fill: #000000;
            fill-opacity: 1;
            stroke: none;
            stroke-width: 0.11134405;
            stroke-linecap: butt;
            stroke-linejoin: round;
            stroke-miterlimit: 4;
            stroke-dasharray: none;
            stroke-opacity: 1;
            paint-order: normal;
          "
        />
        <path
          id="cabin"
          d="M 14.2875,8.4666663 V 4.2994788 L 15.875,3.7041663 h 2.116666 l 1.587501,0.5953125 v 4.1671875 z"
          style="
            fill: #666666;
            stroke: #000000;
            stroke-width: 0.280633px;
            stroke-linecap: butt;
            stroke-linejoin: miter;
            stroke-opacity: 1;
          "
          :style="getStyle('cabin')"
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
  body: { fillColor: COLORS.yellow, strokeColor: 'black' },
  bucket: { fillColor: COLORS.yellow, strokeColor: 'black' },
  bucketArm: { fillColor: COLORS.yellow, strokeColor: 'black' },
  bucketInner: { fillColor: COLORS.darkYellow },
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
  name: 'ScraperTopDown',
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
.scraper-top-down-marker {
  cursor: pointer;
}
</style>
