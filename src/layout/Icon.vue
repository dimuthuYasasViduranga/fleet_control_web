<template>
  <span class="icon-wrapper">
    <svg v-bind:viewBox="'0 0 ' + icon.size + ' ' + icon.size" class="icon">
      <g v-for="(shape, index) in icon.shapes" :key="index">
        <path v-if="shape.type === 'path'"
        v-bind:stroke-linecap="shape.strokeLinecap" 
        v-bind:stroke-linejoin="shape.strokeLinejoin"
        v-bind:d="shape.d"
        v-bind:transform="shape.transform"
        v-bind:strokeMiterlimit="shape.strokeMiterlimit"
        ></path>

        <rect v-else-if="shape.type === 'rect'"
        v-bind:x="shape.x"
        v-bind:y="shape.y"
        v-bind:width="shape.width"
        v-bind:height="shape.height"
        v-bind:rx="shape.rx"
        v-bind:ry="shape.ry"
        v-bind:stroke-linejoin="shape.strokeLinejoin"
        v-bind:strokeMiterlimit="shape.strokeMiterlimit"
        ></rect>

        <text v-else-if="shape.type === 'text'"
          v-bind:fill="shape.fill"
          v-bind:stroke="shape.stroke"
          v-bind:transform="shape.transform"
          v-bind:font-size="shape.fontSize"
          v-bind:font-weight="shape.fontWeight"
          v-bind:letter-spacing="shape.letterSpacing"
          >
          {{shape.text}}
        </text>

        <circle v-else-if="shape.type === 'circle'"
        v-bind:stroke-linecap="shape.strokeLinecap" 
        v-bind:stroke-linejoin="shape.strokeLinejoin"
        v-bind:cx="shape.cx"
        v-bind:cy="shape.cy"
        v-bind:r="shape.r"
        ></circle>

        <div v-else>
          Error, unknown shape type
        </div>
      </g>
    </svg>
  </span>
</template>

<script>
export default {
  name: 'icon',
  props: {
    icon: Object
  },
  methods: {
  }
}
</script>

<style>
.icon {
  pointer-events: none;
  display: block;
  width: 100%;
  height: 100%;
}

.icon-wrapper {
  stroke: #b7c3cd;
  fill: none;
  height: 2em;
  width: 4em;
  position: relative;
  display: flex;
}
</style>
