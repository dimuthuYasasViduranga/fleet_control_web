<template>
  <div ref="container" class="service-vehicle-top-down-marker" @click="onClick">
    <svg
      id="service-vehicle-top-down"
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
        <!-- body -->
        <path
          id="body"
          d="m 15.22793,1.0680201 v 1.0583333 l -2.540001,1.0583333 v 4.7624998 h 0.846666 v 4.7624995 l 6.773333,0.01654 V 7.9471865 h 0.846667 V 3.1846867 L 18.614594,2.1263534 V 1.0680201 Z"
          style="stroke-width: 0.26458333"
          :style="getStyle('body')"
        />
        <path
          id="cabin"
          d="M 14.275429,7.9471865 V 3.7799991 l 1.5875,-0.5953124 h 2.116666 l 1.587501,0.5953124 v 4.1671874 z"
          style="stroke-width: 0.26458333"
          :style="getStyle('cabin')"
        />
        <rect
          ry="0.12988396"
          y="12.766146"
          x="10.517187"
          height="19.976042"
          width="12.832292"
          id="carriage"
          style="stroke-width: 0.26458332"
          :style="getStyle('carriage')"
        />

        <!-- wheels -->

        <rect
          y="3.485368"
          x="11.534739"
          height="4.1641622"
          width="1.0539725"
          id="wheel-front-left"
          style="stroke-width: 0.26458332"
          :style="getStyle('wheels')"
        />
        <rect
          y="3.485368"
          x="21.195936"
          height="4.1641622"
          width="1.0539725"
          id="wheel-font-right"
          style="stroke-width: 0.26458332"
          :style="getStyle('wheels')"
        />
        <rect
          y="16.293175"
          x="9.2036753"
          height="5.8208332"
          width="1.0583335"
          id="wheel-middle-left"
          style="stroke-width: 0.26458332"
          :style="getStyle('wheels')"
        />
        <rect
          y="16.293175"
          x="23.441568"
          height="5.8208332"
          width="1.0583335"
          id="wheel-middle-right"
          style="stroke-width: 0.26458332"
          :style="getStyle('wheels')"
        />

        <rect
          y="25.331099"
          x="9.2216682"
          height="5.8208332"
          width="1.0583335"
          id="wheel-back-left"
          style="stroke-width: 0.26458332"
          :style="getStyle('wheels')"
        />
        <rect
          y="25.3311"
          x="23.443024"
          height="5.8208332"
          width="1.0583335"
          id="wheel-back-right"
          style="stroke-width: 0.26458332"
          :style="getStyle('wheels')"
        />

        <!-- toolboxes -->
        <rect
          ry="0.12988396"
          y="13.567546"
          x="11.365637"
          height="3.7417734"
          width="10.991459"
          id="toolbox-back"
          style="stroke-width: 0.26458332"
          :style="getStyle('toolbox')"
        />

        <rect
          ry="0.11430009"
          y="8.7089729"
          x="14.310678"
          height="3.292824"
          width="5.3586221"
          id="toolbox-font"
          style="stroke-width: 0.26458332"
          :style="getStyle('toolbox')"
        />

        <!-- tank -->

        <rect
          ry="0.12988396"
          y="18.25625"
          x="11.443229"
          height="13.49375"
          width="10.914062"
          id="tank"
          style="stroke-width: 0.26458332"
          :style="getStyle('tank')"
        />

        <rect
          y="20.255966"
          x="14.803391"
          height="2.0579753"
          width="4.2562671"
          id="hatch-1"
          style="stroke-width: 0.26458332"
          :style="getStyle('hatch')"
        />
        <rect
          y="23.857424"
          x="14.803391"
          height="2.0579753"
          width="4.2562671"
          id="hatch-2"
          style="stroke-width: 0.26458332"
          :style="getStyle('hatch')"
        />
        <rect
          y="3.8389351"
          x="14.826777"
          height="5.9868374"
          width="4.0691786"
          id="rect2371"
          style="stroke-width: 0.26458333"
          :style="getStyle('hatch')"
        />
        <rect
          y="27.552423"
          x="14.826777"
          height="2.0579753"
          width="4.2562671"
          id="hatch-3"
          style="stroke-width: 0.26458332"
          :style="getStyle('hatch')"
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
  cabin: { fillColor: COLORS.yellow, strokeColor: 'black' },
  carriage: { fillColor: COLORS.yellow, strokeColor: 'black' },
  toolbox: { fillColor: 'grey', strokeColor: 'black' },
  tank: { fillColor: COLORS.darkYellow, strokeColor: 'black' },
  hatch: { fillColor: 'grey', strokeColor: 'black' },
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
  name: 'ServiceVehicleTopDownMarker',
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
.service-vehicle-top-down-marker {
  cursor: pointer;
}
</style>
