<template>
  <g id="circle_expand">
    <circle cx="11" cy="11" r="6.5" stroke-linejoin="round" />
    <path
      stroke-linejoin="round"
      d="M4 .5H.5V4M.5.5l4 4M18 .5h3.5V4m0-3.5l-4 4M4 21.5H.5V18m0 3.5l4-4m13.5 4h3.5V18m0 3.5l-4-4"
    />
  </g>
</template>

<script>
export default {
  name: 'CircleExpandIcon',
  size: 22,
  pxIconSet: 'px-vis:expand-radius',
};
</script>
