<template>
  <div class="dnd-route-main">
    <button class="hx-btn" @click="onAddRoute()">Add Route</button>
    <div class="layout">
      <SimpleLayout :structure="structure" @remove="onRemoveRoute" />
    </div>

    <pre>{{ structure }}</pre>
  </div>
</template>

<script>
import AddRouteModal from './AddRouteModal.vue';

import { RouteStructure } from './routeStructure.js';
import SimpleLayout from './SimpleLayout.vue';

export default {
  name: 'DndRouteMain',
  components: {
    SimpleLayout,
  },
  props: {
    assets: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    loadLocations: { type: Array, default: () => [] },
    dumpLocations: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      structure: new RouteStructure(),
    };
  },
  computed: {
    digUnits() {
      return this.assets.filter(a => a.secondaryType === 'Dig Unit');
    },
  },
  methods: {
    onAddRoute() {
      const opts = {
        digUnits: this.digUnits,
        locations: this.locations,
        loadLocations: this.loadLocations,
        dumpLocations: this.dumpLocations,
      };
      this.$modal.create(AddRouteModal, opts).onClose(answer => {
        if (answer) {
          this.structure.add(answer.digUnitId, answer.loadId, answer.dumpId);
        }
      });
    },
    onRemoveRoute(route) {
      console.dir('--- on remove route');
      this.structure.remove(route.digUnitId, route.loadId, route.dumpId);
    },
  },
};
</script>

<style>
.dnd-route-main .layout {
  margin: 1rem;
  border: 1px solid orange;
}
</style>