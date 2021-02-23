<template>
  <g id="nested-list">
    <path stroke-linejoin="round" d="M.5 1.5h4v4h-4z" />
    <rect x="3.5" y="8.5" width="4" height="4" rx="1" ry="1" stroke-linejoin="round" />
    <rect x="3.5" y="15.5" width="4" height="4" rx="1" ry="1" stroke-linejoin="round" />
    <path stroke-linejoin="round" d="M6 3.5h13m-10 7h13m-13 7h13" />
  </g>
</template>

<script>
export default {
  name: 'ListIcon',
  size: 22,
  pxIconSet: 'px-nav:tree',
};
</script>
