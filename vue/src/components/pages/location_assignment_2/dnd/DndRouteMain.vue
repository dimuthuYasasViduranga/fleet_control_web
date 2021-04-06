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
import { attributeFromList } from '@/code/helpers';
import AddRouteModal from './AddRouteModal.vue';

import { RouteStructure } from './routeStructure.js';
import SimpleLayout from './SimpleLayout.vue';

function toDigUnit(digUnit, activities) {
  const activity = attributeFromList(activities, 'assetId', digUnit.id) || {};

  return {
    id: digUnit.id,
    name: digUnit.name,
    typeId: digUnit.typeId,
    type: digUnit.type,
    secondaryType: digUnit.secondaryType,
    locationId: activity.locationId,
  };
}

function toHaulTruck(haulTruck, dispatches) {
  const dispatch = attributeFromList(dispatches, 'assetId', haulTruck.id) || {};

  return {
    id: haulTruck.id,
    name: haulTruck.name,
    typeId: haulTruck.typeId,
    type: haulTruck.type,
    secondaryType: haulTruck.secondaryType,
    digUnitId: dispatch.digUnitId,
    loadId: dispatch.loadId,
    dumpId: dispatch.dumpId,
  };
}

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
    digUnitActivities: { type: Array, default: () => [] },
    haulTruckDispatches: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      structure: new RouteStructure(),
    };
  },
  computed: {
    digUnits() {
      return this.assets
        .filter(a => a.secondaryType === 'Dig Unit')
        .map(a => toDigUnit(a, this.digUnitActivities));
    },
    haulTrucks() {
      return this.assets
        .filter(a => a.type === 'Haul Truck')
        .map(a => toHaulTruck(a, this.haulTruckDispatches));
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