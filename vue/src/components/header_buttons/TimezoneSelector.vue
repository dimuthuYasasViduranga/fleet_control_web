<template>
  <span class="timezone-selector" @tap="onOpenSelector">Timezone Selector</span>
</template>

<script>
export default {
  name: 'TimezoneSelector',
  computed: {

  },
  methods: {
    onOpenSelector() {
      console.dir('---- open selecotr');
    },
  },
};
</script>

<style>
.timezone-selector {
  cursor: pointer;
  line-height: 2rem;
  margin: 0 0.5rem;
}
</style>