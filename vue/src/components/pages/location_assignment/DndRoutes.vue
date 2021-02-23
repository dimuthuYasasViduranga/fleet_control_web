<template>
  <div class="dnd-routes">
    <OtherAssets :assets="otherAssets" />

    <UnassignedAssets
      :assets="unassignedAssets"
      @drag-start="onDragStart"
      @drag-end="onDragEnd()"
      @add="onSetUnassigned"
    />

    <Container
      v-if="showAddNewDigUnit"
      behaviour="drop-zone"
      class="new-dig-unit-container"
      group-name="draggable"
      :drop-placeholder="dropPlaceholderOptions"
      @drop="onDropNewDigUnit"
    >
      Drop To Add Dig Unit
    </Container>
    <PerfectScrollbar v-if="orientation === 'vertical'">
      <div class="dig-unit-routes vertical">
        <DigUnitRouteV
          v-for="(route, index) in orderedRoutes"
          :key="index"
          :digUnitId="route.assetId"
          :dumpIds="route.dumpIds"
          :digUnits="localDigUnits"
          :haulTrucks="localHaulTrucks"
          :locations="locations"
          :columns="settings.vertical.columns"
          @drag-start="onDragStart"
          @drag-end="onDragEnd()"
          @set-haul-truck="onSetHaulTruck"
          @remove-dig-unit="onRemoveDigUnit(route.assetId)"
          @clear-dig-unit="onConfirmClearDigUnit(route.assetId)"
          @select-dump="onSelectRoute(route.assetId)"
          @remove-dump="onRemoveDump(route.assetId, $event)"
          @clear-dump="onConfirmClearDump(route.assetId, $event)"
          @move-dump="onMoveDump(route.assetId, $event)"
        />
      </div>
    </PerfectScrollbar>
    <div v-else class="dig-unit-routes horizontal">
      <DigUnitRouteH
        v-for="(route, index) in orderedRoutes"
        :key="index"
        :digUnitId="route.assetId"
        :dumpIds="route.dumpIds"
        :digUnits="localDigUnits"
        :haulTrucks="localHaulTrucks"
        :locations="locations"
        @drag-start="onDragStart"
        @drag-end="onDragEnd()"
        @set-haul-truck="onSetHaulTruck"
        @remove-dig-unit="onRemoveDigUnit(route.assetId)"
        @clear-dig-unit="onConfirmClearDigUnit(route.assetId)"
        @select-dump="onSelectRoute(route.assetId)"
        @remove-dump="onRemoveDump(route.assetId, $event)"
        @clear-dump="onConfirmClearDump(route.assetId, $event)"
        @move-dump="onMoveDump(route.assetId, $event)"
      />
    </div>
  </div>
</template>

<script>
import {
  addDigUnit,
  removeDigUnit,
  addDump,
  removeDump,
  listifyStructure,
  mergeStructure,
  structureFromHaulTrucks,
} from './routes';

import { Container, Draggable } from 'vue-smooth-dnd';

import OtherAssets from './OtherAssets.vue';
import UnassignedAssets from './UnassignedAssets.vue';
import { PerfectScrollbar } from 'vue2-perfect-scrollbar';
import DigUnitRouteV from './vertical/DigUnitRouteV.vue';
import DigUnitRouteH from './horizontal/DigUnitRouteH.vue';

import AddRouteModal from './AddRouteModal.vue';
import ConfirmModal from '@/components/modals/ConfirmModal.vue';

import { attributeFromList } from '@/code/helpers';

function orderRoutesByAssetName(source, digUnits) {
  const routes = source.slice();
  routes.sort((a, b) => {
    const digUnitA = attributeFromList(digUnits, 'id', a.assetId, 'name') || '';
    const digUnitB = attributeFromList(digUnits, 'id', b.assetId, 'name') || '';

    return digUnitA.localeCompare(digUnitB);
  });
  return routes;
}

function orderRoutesByAssetLocation(source, digUnits, locations) {
  const routes = source.slice();
  routes.sort((a, b) => {
    const locationA = getDigUnitLocation(a.assetId, digUnits, locations);
    const locationB = getDigUnitLocation(b.assetId, digUnits, locations);

    return locationA.localeCompare(locationB);
  });
  return routes;
}

function getDigUnitLocation(id, digUnits, locations) {
  const activity = attributeFromList(digUnits, 'id', id, 'activity') || {};
  return attributeFromList(locations, 'id', activity.locationId, 'name') || '';
}

function toLocalAsset(asset) {
  return {
    deviceId: asset.deviceId,
    id: asset.id,
    name: asset.name,
    typeId: asset.typeId,
    type: asset.type,
    secondaryType: asset.secondaryType,
    radioNumber: asset.radioNumber,
    operator: asset.operator,
    activeTimeAllocation: asset.activeTimeAllocation,
    present: asset.present,
    synced: true,
    updatedExtenally: false,
  };
}

function validMove(move, original) {
  if (!move) {
    return false;
  }

  return (
    (move.digUnitId !== original.digUnitId || move.dumpId !== original.dumpId) && move.digUnitId
  );
}

function dispatchEqual(a, b) {
  return a.digUnitId === b.digUnitId && a.dumpId === b.dumpId;
}

export default {
  name: 'DndRoutes',
  components: {
    Container,
    Draggable,
    PerfectScrollbar,
    OtherAssets,
    UnassignedAssets,
    DigUnitRouteV,
    DigUnitRouteH,
  },
  props: {
    orientation: { type: String, default: 'horizontal' },
    settings: { type: Object, default: () => ({ vertical: {}, horizontal: {} }) },
    digUnits: { type: Array, default: () => [] },
    haulTrucks: { type: Array, default: () => [] },
    otherAssets: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    dumpLocations: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      draggedAsset: null,
      routeStructure: {},
      dropPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
      localHaulTrucks: [],
      localDigUnits: [],
      pendingUpdate: false,
    };
  },
  computed: {
    routes() {
      return listifyStructure(this.routeStructure);
    },
    orderedRoutes() {
      const orderBy = this.settings[this.settings.orientation].orderBy;
      if (orderBy === 'dig-unit') {
        return orderRoutesByAssetName(this.routes, this.digUnits);
      }
      return orderRoutesByAssetLocation(this.routes, this.digUnits, this.locations);
    },
    unassignedDigUnits() {
      const unitsWithRoutes = this.routes.map(r => r.assetId);
      return this.localDigUnits.filter(d => !unitsWithRoutes.includes(d.id));
    },
    unassignedHaulTrucks() {
      return this.localHaulTrucks.filter(h => !h.dispatch.digUnitId && !h.dispatch.loadId);
    },
    unassignedAssets() {
      return [].concat(this.unassignedDigUnits).concat(this.unassignedHaulTrucks);
    },
    showAddNewDigUnit() {
      const draggedAsset = this.draggedAsset;
      return draggedAsset && draggedAsset.secondaryType === 'Dig Unit';
    },
  },
  watch: {
    haulTrucks: {
      immediate: true,
      handler() {
        this.updateLocalHaulTrucks();
        this.updateStructure();
      },
    },
    digUnits: {
      immediate: true,
      handler() {
        this.updateLocalDigUnits();
        this.updateStructure();
      },
    },
  },
  mounted() {
    this.updateLocalHaulTrucks();
    this.updateLocalDigUnits();
    this.updateStructure();
  },
  methods: {
    updateLocalHaulTrucks(assets) {
      // if dragging, all updates are suspended to prevent freezing issues
      if (this.draggedAsset) {
        this.pendingUpdate = true;
        return;
      }

      this.pendingUpdate = false;
      const hasLocalHaulTrucks = this.localHaulTrucks.length !== 0;
      const newAssets = this.haulTrucks.map(ht => {
        const oldAssetDispatch =
          attributeFromList(this.localHaulTrucks, 'id', ht.id, 'dispatch') || {};
        const asset = toLocalAsset(ht);
        asset.dispatch = { ...ht.dispatch };
        if (hasLocalHaulTrucks && !dispatchEqual(asset.dispatch, oldAssetDispatch)) {
          asset.updatedExtenally = true;
        }
        return asset;
      });

      this.localHaulTrucks = newAssets;
    },
    updateLocalDigUnits() {
      this.localDigUnits = this.digUnits.map(d => {
        const asset = toLocalAsset(d);
        asset.activity = { ...d.activity };
        return asset;
      });
    },
    updateStructure() {
      const assetStructure = structureFromHaulTrucks(this.localHaulTrucks);
      this.routeStructure = mergeStructure(this.routeStructure, assetStructure);
    },
    onDragStart(asset) {
      this.draggedAsset = asset;
    },
    onDragEnd() {
      this.draggedAsset = null;
      if (this.pendingUpdate) {
        this.updateLocalHaulTrucks();
      }
    },
    setHaulTruck(asset, digUnitId, dumpId) {
      asset.dispatch.digUnitId = digUnitId;
      asset.dispatch.dumpId = dumpId;

      asset.synced = false;

      this.localHaulTrucks = this.localHaulTrucks.slice();
      this.$emit('set-haul-truck', { assetId: asset.id, digUnitId, dumpId });
    },
    massSetHaulTruck(assets, digUnitId, dumpId) {
      assets.forEach(a => {
        a.dispatch.digUnitId = digUnitId;
        a.dispatch.dumpId = dumpId;
        a.synced = false;
      });

      const assetIds = assets.map(a => a.id);

      this.localHaulTrucks = this.localHaulTrucks.slice();
      this.$emit('mass-set-haul-truck', { assetIds, digUnitId, dumpId });
    },
    onSetUnassigned({ asset }) {
      if (asset.type === 'Haul Truck') {
        this.setHaulTruck(asset, null, null);
      }

      if (asset.secondaryType === 'Dig Unit') {
        this.onRemoveDigUnit(asset.id);
      }
    },
    onSetHaulTruck({ asset, digUnitId, dumpId }) {
      this.setHaulTruck(asset, digUnitId, dumpId);
    },
    onRemoveDigUnit(digUnitId) {
      this.routeStructure = removeDigUnit(this.routeStructure, digUnitId);
      this.updateStructure();
    },
    onConfirmClearDigUnit(digUnitId) {
      const ok = 'yes';
      const opts = {
        title: 'Clear Dig Unit',
        body:
          'All assets assigned to this asset will be removed.\n\nAre you sure you want to continue?',
        ok,
      };

      this.$modal.create(ConfirmModal, opts).onClose(answer => {
        if (answer === ok) {
          this.clearDigUnit(digUnitId);
        }
      });
    },
    clearDigUnit(digUnitId) {
      // confirm modal here
      const digUnit = this.localDigUnits.find(a => a.id === digUnitId);
      const haulTrucks = this.localHaulTrucks.filter(h => h.dispatch.digUnitId === digUnitId);

      this.massSetHaulTruck(haulTrucks, null, null);
      this.onRemoveDigUnit(digUnitId);
    },
    onSelectRoute(digUnitId) {
      const opts = {
        digUnitId,
        digUnits: this.localDigUnits,
        locations: this.locations,
        dumpLocations: this.dumpLocations,
      };

      this.$modal.create(AddRouteModal, opts).onClose(answer => {
        if (answer) {
          this.routeStructure = addDump(this.routeStructure, answer.digUnitId, answer.dumpId);
          this.updateStructure();
        }
      });
    },
    onRemoveDump(digUnitId, dumpId) {
      this.routeStructure = removeDump(this.routeStructure, digUnitId, dumpId);
      this.updateStructure();
    },
    onConfirmClearDump(digUnitId, dumpId) {
      const ok = 'yes';
      const opts = {
        title: 'Clear Dump',
        body: 'Are you sure you want to remove all assets from this dump?',
        ok,
      };

      this.$modal.create(ConfirmModal, opts).onClose(answer => {
        if (answer === ok) {
          this.clearDump(digUnitId, dumpId);
        }
      });
    },
    clearDump(digUnitId, dumpId) {
      const haulTrucks = this.localHaulTrucks.filter(h => {
        return h.dispatch.digUnitId === digUnitId && h.dispatch.dumpId === dumpId;
      });

      this.massSetHaulTruck(haulTrucks, null, null);
      this.onRemoveDump(digUnitId, dumpId);
    },
    onMoveDump(digUnitId, dumpId) {
      const opts = {
        submitName: 'Submit',
        digUnitId,
        dumpId,
        digUnits: this.localDigUnits,
        locations: this.locations,
        dumpLocations: this.dumpLocations,
      };

      this.$modal.create(AddRouteModal, opts).onClose(resp => {
        if (validMove(resp, opts)) {
          this.moveDump({ digUnitId, dumpId }, resp);
        }
      });
    },
    moveDump(from, to) {
      const haulTrucks = this.localHaulTrucks.filter(h => {
        return h.dispatch.digUnitId === from.digUnitId && h.dispatch.dumpId === from.dumpId;
      });

      this.massSetHaulTruck(haulTrucks, to.digUnitId, to.dumpId);
      this.onRemoveDump(from.digUnitId, from.dumpId);
    },
    onDropNewDigUnit({ addedIndex, removedIndex, payload }) {
      // is added
      if (addedIndex !== null && removedIndex === null) {
        this.routeStructure = addDigUnit(this.routeStructure, payload.id);
      }
    },
  },
};
</script>


<style >
/* scrolling */
.dnd-routes .ps .ps__rail-y,
.dnd-routes .ps .ps__rail-x {
  background-color: #121f26;
}

.dnd-routes .ps .ps__rail-x {
  top: 0;
}
</style>

<style scoped>
/* --- new dig unit container */
.new-dig-unit-container {
  width: 100%;
  height: 7rem;
  background-color: #748b993d;
  border: 1px dashed rgba(128, 128, 128, 0.24);
  line-height: 7rem;
  text-align: center;
  opacity: 0.5;
}

.new-dig-unit-container:hover {
  opacity: 1;
}

.dig-unit-routes {
  margin-top: 0.25rem;
  margin-bottom: 2rem;
}

.dig-unit-routes.vertical {
  padding-top: 1rem;
  width: 100%;
  display: flex;
}

.dig-unit-routes.vertical .dig-unit-route-v {
  margin-right: 1rem;
}

.dig-unit-routes.horizontal .dig-unit-route-h {
  margin-bottom: 0.5rem;
}
</style>