<template>
  <span class="icon-wrapper">
    <svg v-bind:viewBox="'0 0 ' + size + ' ' + size" class="icon">
        <g v-if="name === 'generic-user'">
          <path stroke-linejoin="round" d="M16.17 12l4.33 3v6.5h-19V15l4.33-3"></path>
          <rect x="6.5" y=".5" width="9" height="11" rx="4.5" ry="4.5" stroke-linejoin="round"></rect>
        </g>
        <g v-else>
        </g>
    </svg>
  </span>
</template>

<script>
export default {
  name: 'icon',
  props: {
    name: String,
    size: Number
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
