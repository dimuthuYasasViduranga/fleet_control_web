<template>
  <div class="dnd-route-main">
    <button class="hx-btn" @click="onAddRoute()">Add Route</button>
    <div class="layout">
      <!-- <OtherAssets :assets="otherAssets" /> -->
      <!-- <UnassignedAssets :assets="unassignedAssets" /> -->
      <!-- <SimpleLayout :structure="structure" @remove="onRemoveRoute" /> -->
      <AssignedLayout
        :structure="structure"
        :haulTrucks="haulTrucks"
        :digUnits="digUnits"
        :locations="locations"
        :loadLocations="loadLocations"
        :dumpLocations="dumpLocations"
        @drag-start="onDragStart"
        @drag-end="onDragEnd()"
        @set-haul-truck="onSetHaulTruck"
        @remove-route="onRemoveRoute"
        @clear-route="onConfirmClearRoute"
        @request-add-dump="onRequestAddDump"
        @remove-dump="onRemoveDump"
        @clear-dump="onClearDump"
        @move-dump="onMoveDump"
      />
    </div>

    <pre>{{ structure }}</pre>
  </div>
</template>

<script>
import { attributeFromList } from '@/code/helpers';
import AddRouteModal from './AddRouteModal.vue';

import { RouteStructure } from './routeStructure.js';
import SimpleLayout from './SimpleLayout.vue';
import OtherAssets from './other_assets/OtherAssets.vue';
import UnassignedAssets from './unassigned_assets/UnassignedAssets.vue';
import AssignedLayout from './layout/AssignedLayout.vue';

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
    synced: true,
    updatedExternally: false,
  };
}

function addDigUnitInfo(digUnit, activities) {
  const activity = attributeFromList(activities, 'assetId', digUnit.id) || {};
  digUnit.locationId = activity.locationId;
  return digUnit;
}

function addHaulTruckInfo(haulTruck, dispatches) {
  const dispatch = attributeFromList(dispatches, 'assetId', haulTruck.id) || {};
  haulTruck.digUnitId = dispatch.digUnitId || null;
  haulTruck.loadId = dispatch.loadId || null;
  haulTruck.dumpId = dispatch.dumpId || null;
  return haulTruck;
}

function haulTruckDispatchEqual(a, b) {
  return a.digUnitId === b.digUnitId && a.loadId === b.loadId && a.dumpId === b.dumpId;
}

export default {
  name: 'DndRouteMain',
  components: {
    SimpleLayout,
    UnassignedAssets,
    OtherAssets,
    AssignedLayout,
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
      draggedAsset: null,
      localHaulTrucks: [],
      localDigUnits: [],
      pendingUpdate: false,
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
  watch: {
    haulTrucks: {
      immediate: true,
      handler(assets) {
        this.updateLocalHaulTrucks(assets);
        this.updateStructure();
      },
    },
    digUnits: {
      immediate: true,
      handler(assets) {
        this.updateLocalDigUnits(assets);
      },
    },
  },
  methods: {
    updateLocalHaulTrucks(assets) {
      // if dragging, all updates are suspended to prevent freezing issues
      if (this.draggedAsset) {
        this.pendingUpdate = true;
        return;
      }

      this.pendingUpdate = false;
      const currentlyHasAssets = this.localHaulTrucks.length !== 0;
      const newHTs = this.haulTrucks.map(ht => {
        const oldAsset = attributeFromList(this.localHaulTrucks, 'id', ht.id) || {};

        if (currentlyHasAssets && !haulTruckDispatchEqual(ht, oldAsset)) {
          ht.updatedExternally = true;
        }

        return ht;
      });

      this.localHaulTrucks = newHTs;
    },
    updateLocalDigUnits(assets) {
      this.localDigUnits = assets.slice();
    },
    updateStructure() {
      this.localHaulTrucks.forEach(ht => {
        this.structure.add(ht.digUnitId, ht.loadId, ht.dumpId);
      });
    },
    setHaulTruck(asset, digUnitId, loadId, dumpId) {
      asset.digUnitId = digUnitId;
      asset.loadId = loadId;
      asset.dumpId = dumpId;

      asset.synced = false;

      this.localHaulTrucks = this.localHaulTrucks.slice();
      this.$emit('set-haul-truck', { assetId: asset.id, digUnitId, loadId, dumpId });
    },
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
    onDragStart(asset) {
      this.draggedAsset = asset;
    },
    onDragEnd() {
      this.draggedAsset = null;
    },
    onSetHaulTruck({ asset, digUnitId, loadId, dumpId }) {
      console.dir('---- on set haul truck');
      this.setHaulTruck(asset, digUnitId, loadId, dumpId);
    },
    onRemoveRoute(route) {
      console.dir('--- on remove route');
      this.structure.removeAllDumpsFor(route.digUnitId, route.loadId);
    },
    onConfirmClearRoute(event) {
      console.dir('--- confirm clear route');
      console.dir(event);
      // prompt to say that everything will be cleared
    },
    onRequestAddDump(event) {
      console.dir('--- request add dump');
      console.dir(event);
      // open the add modal here with some details (just add route with start values)
    },
    onRemoveDump(event) {
      console.dir('---- remove dump');
      console.dir(event);
    },
    onClearDump(event) {
      console.dir('---- clear dump');
      console.dir(event);
    },
    onMoveDump(event) {
      console.dir('---- move dump');
      console.dir(event);
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