<template>
  <g id="pdf_icon">
    <path stroke-linejoin="round" d="M3.5 14v1.5h12v-12l-3-3h-9V7" />
    <path stroke-linejoin="round" d="M11.5.5v4h4" />
    <text
      fill="currentcolor"
      stroke="none"
      transform="translate(-.32 13.23)"
      font-size="7"
      font-weight="700"
      letter-spacing=".06em"
    >
      PD<tspan x="9.83" y="0" letter-spacing=".04em">F</tspan>
    </text>
  </g>
</template>

<script>
export default {
  name: 'PdfIcon',
  size: 16,
  pxIconSet: 'px-doc:document-pdf',
};
</script>
