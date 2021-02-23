<template>
  <gmap-polyline :path="path" :options="options" />
</template>

<script>
export default {
  name: 'GMapRoute',
  props: {
    clusterIds: { type: Array, default: () => [] },
    clusters: { type: Array, default: () => [] },
    options: { type: Object, default: null },
  },
  computed: {
    path() {
      return this.clusterIds
        .map(id => {
          const cluster = this.clusters.find(c => c.id === id);
          if (!cluster) {
            return null;
          }

          return { lat: cluster.lat, lng: cluster.lon };
        })
        .filter(coord => coord);
    },
  },
};
</script>