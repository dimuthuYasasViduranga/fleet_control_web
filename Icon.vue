<template>
  <span class="hx-icon" @click="onClick()">
    <svg class="icon-svg" :viewBox="localViewBox" :preserveAspectRatio="localAspectRatio">
      <component v-if="icon" class="icon-g" v-bind:is="icon" :transform="transform" />
    </svg>
  </span>
</template>

<script>
// https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/preserveAspectRatio
const ASPECT_RATIOS = {
  fill: 'none',
  left: 'xMinYMid meet',
  top: 'xMidYMin meet',
  right: 'xMaxYMid meet',
  bottom: 'xMidYMax meet',
  center: '',
};

function parseViewBox(values) {
  if (!isNaN(values)) {
    return [0, 0, values, values];
  }
  if (values.length === 2) {
    return [0, 0].concat(values);
  }
  return values;
}

function parseScale(scale) {
  if (!scale) {
    return null;
  }
  if (!isNaN(scale)) {
    return { x: scale, y: scale };
  }
  return { x: scale.x || 1, y: scale.y || 1 };
}

export default {
  name: 'HXIcon',
  props: {
    icon: { type: Object, default: null },
    viewBox: { type: Array, default: null },
    aspectRatio: { type: String, default: 'center' },
    rotation: { type: Number, default: 0 },
    scale: { type: [Number, Object], default: null },
  },
  computed: {
    localAspectRatio() {
      // return an expanded shorthand or the given aspect ratio
      const aspectRatio = ASPECT_RATIOS[this.aspectRatio];
      return aspectRatio === undefined ? this.aspectRatio : aspectRatio;
    },
    localViewBox() {
      const icon = this.icon || {};
      const depreciatedSize = icon.size;
      const defaultViewBox = icon.viewBox || 0;
      return parseViewBox(this.viewBox || depreciatedSize || defaultViewBox).join(' ');
    },
    localScale() {
      return parseScale(this.scale || (this.icon || {}).scale);
    },
    localRotation() {
      const iconRotation = (this.icon || {}).rotation;
      return iconRotation === undefined ? this.rotation : iconRotation;
    },
    transform() {
      const rotationStr = `rotate(${this.localRotation})`;
      const scale = this.localScale;
      const scaleStr = scale ? `scale(${scale.x} ${scale.y})` : '';

      return `${rotationStr} ${scaleStr}`;
    },
  },
  methods: {
    onClick() {
      this.$emit('click');
    },
  },
};
</script>

<style>
.hx-icon {
  stroke: #b7c3cd;
  fill: none;
  width: 2rem;
  height: 2rem;
  position: relative;
  display: flex;
}

.hx-icon .icon-svg {
  stroke-width: 0.75;
  pointer-events: none;
  display: block;
  width: 100%;
  height: 100%;
}

.hx-icon .icon-g {
  transform-origin: center;
}
</style>