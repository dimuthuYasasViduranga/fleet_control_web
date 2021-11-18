<template>
  <div class="gmap-my-position">
    <gmap-marker
      v-if="valid"
      :position="position"
      :options="{
        clickable: false,
      }"
    />

    <gmap-circle
      v-if="valid && accuracy !== 0"
      :center="position"
      :radius="accuracy"
      :options="{
        clickable: false,
        strokeOpacity: 1,
        strokeWeight: 1,
        fillColor: 'lightblue',
      }"
    />
  </div>
</template>

<script>
export default {
  name: 'GMapMyPosition',
  props: {
    value: { type: Object },
  },
  computed: {
    valid() {
      return !!this.value;
    },
    position() {
      return (this.value || {}).position;
    },
    accuracy() {
      const acc = (this.value || {}).accuracy || {};
      return acc.lat || acc.lng || 0;
    },
  },
};
</script>