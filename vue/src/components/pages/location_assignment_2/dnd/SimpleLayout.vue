<template>
  <div class="simple-layout">
    Simple Layout
    <div class="route" v-for="(route, index) in groupedRoutes" :key="index">
      <div class="title">Dig Unit: {{ route.digUnitId || '--' }}</div>
      <div class="title">Load: {{ route.loadId || '--' }}</div>
      <div class="title" @click="onRemoveDump(route)">Dumps: {{ route.dumpIds || '--' }}</div>
    </div>
  </div>
</template>

<script>
import { Dictionary } from '@/code/helpers';

function groupRoutes(routes) {
  const dict = new Dictionary();

  routes.forEach(r => {
    dict.append([r.digUnitId, r.loadId], r.dumpId);
  });

  return dict.map(([digUnitId, loadId], dumpIds) => {
    return {
      digUnitId,
      loadId,
      dumpIds,
    };
  });
}

function parseStringOrInt(value) {
  return parseInt(value, 10) || value;
}

export default {
  name: 'SimpleLayout',
  props: {
    structure: { type: Object, required: true },
  },
  computed: {
    routes() {
      return this.structure.routes;
    },
    groupedRoutes() {
      return groupRoutes(this.routes);
    },
  },
  methods: {
    onRemoveDump(route) {
      this.onRemoveRoute({
        digUnitId: route.digUnitId,
        loadId: route.loadId,
        dumpId: route.dumpIds[0],
      });
    },
    onRemoveRoute(route) {
      this.$emit('remove', {
        digUnitId: route.digUnitId,
        loadId: route.loadId,
        dumpId: route.dumpId,
      });
    },
  },
};
</script>

<style>
.simple-layout .route {
  border: 1px solid blue;
}

.simple-layout .title {
  font-size: 2rem;
}
</style>