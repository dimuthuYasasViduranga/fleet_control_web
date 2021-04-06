<template>
  <div class="dnd-route-main">
    <button class="hx-btn" @click="onAddRoute()">Add Route</button>
    <div class="layout">
      <OtherAssets :assets="otherAssets" />
      <UnassignedAssets :assets="unassignedAssets" />
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
import UnassignedAssets from './unassigned_assets/UnassignedAssets.vue';
import OtherAssets from './other_assets/OtherAssets.vue';

function toLocalFullAsset(asset) {
  return {
    id: asset.id,
    name: asset.name,
    type: asset.type,
    typeId: asset.typeId,
    secondaryType: asset.secondaryType,
    operator: asset.operator,
    activeTimeAllocation: asset.activeTimeAllocation,
    radioNumber: asset.radioNumber,
    hasDevice: asset.hasDevice,
    present: asset.present,
  };
}

function addDigUnitInfo(digUnit, activities) {
  const activity = attributeFromList(activities, 'assetId', digUnit.id) || {};
  digUnit.locationId = activity.locationId;
  return digUnit;
}

function addHaulTruckInfo(haulTruck, dispatches) {
  const dispatch = attributeFromList(dispatches, 'assetId', haulTruck.id) || {};
  haulTruck.digUnitId = dispatch.digUnitId;
  haulTruck.loadId = dispatch.loadId;
  haulTruck.dumpId = dispatch.dumpId;
  return haulTruck;
}

export default {
  name: 'DndRouteMain',
  components: {
    SimpleLayout,
    UnassignedAssets,
    OtherAssets,
  },
  props: {
    fullAssets: { type: Array, default: () => [] },
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
    assets() {
      return this.fullAssets.map(toLocalFullAsset);
    },
    digUnits() {
      return this.assets
        .filter(a => a.secondaryType === 'Dig Unit')
        .map(a => addDigUnitInfo(a, this.digUnitActivities));
    },
    haulTrucks() {
      return this.assets
        .filter(a => a.type === 'Haul Truck')
        .map(a => addHaulTruckInfo(a, this.haulTruckDispatches));
    },
    otherAssets() {
      return this.assets.filter(a => a.type !== 'Haul Truck' && a.secondaryType !== 'Dig Unit');
    },
    unassignedAssets() {
      // check if the dig unit is in any of the routes
      const routes = this.structure.routes;

      const uDigUnits = this.digUnits.filter(d => routes.every(r => r.digUnitId !== d.id));
      const uHaulTrucks = this.haulTrucks.filter(h => !h.digUnitId && !h.loadId && !h.dumpId);

      return uDigUnits.concat(uHaulTrucks);
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