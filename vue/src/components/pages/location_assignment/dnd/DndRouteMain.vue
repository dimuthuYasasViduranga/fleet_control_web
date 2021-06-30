<template>
  <div class="dnd-route-main">
    <div class="layout">
      <OtherAssets :assets="otherAssets" />
      <UnassignedAssets
        :assets="unassignedAssets"
        @drag-start="onDragStart"
        @drag-end="onDragEnd()"
        @add="onSetUnassigned"
      />
      <!-- quick drop for dig units -->
      <Container
        v-if="draggedAsset && draggedAsset.secondaryType === 'Dig Unit'"
        class="new-dig-unit-container"
        behaviour="drop-zone"
        group-name="draggable"
        @drop="onDropNewDigUnit"
      >
        Drop to Add Route
      </Container>
      <!-- standard click to add -->
      <div v-else class="add-route" :class="{ 'no-hover': !!draggedAsset }" @click="onAddRoute()">
        Click to Add Route
      </div>
      <AssignedLayout
        :orientation="orientation"
        :layoutSettings="layoutSettings"
        :structure="structure"
        :haulTrucks="localHaulTrucks"
        :digUnits="localDigUnits"
        :locations="locations"
        :loadLocations="loadLocations"
        :dumpLocations="dumpLocations"
        @drag-start="onDragStart"
        @drag-end="onDragEnd()"
        @set-dig-unit="onSetDigUnit"
        @set-haul-truck="onSetHaulTruck"
        @remove-route="onRemoveRoute"
        @clear-route="onConfirmClearRoute"
        @request-add-dump="onRequestAddDump"
        @remove-dump="onRemoveDump"
        @clear-dump="onConfirmClearDump"
        @move-trucks="onMoveTrucks"
        @move-dumps="onMoveDumps"
      />
    </div>
  </div>
</template>

<script>
import { Container } from 'vue-smooth-dnd';
import AddRouteModal from './AddRouteModal.vue';
import ConfirmModal from '@/components/modals/ConfirmModal.vue';

import OtherAssets from './other_assets/OtherAssets.vue';
import UnassignedAssets from './unassigned_assets/UnassignedAssets.vue';
import AssignedLayout from './layout/AssignedLayout.vue';

import { attributeFromList } from '@/code/helpers';
import { RouteStructure } from './routeStructure.js';
import { firstBy } from 'thenby';

const STATUS_ORDER = {
  ready: 0,
  process: 1,
  standby: 2,
  down: 4,
  'requires-update': 5,
  null: 6,
};

function toLocalFullAsset(asset) {
  return {
    id: asset.id,
    name: asset.name,
    type: asset.type,
    typeId: asset.typeId,
    secondaryType: asset.secondaryType,
    deviceId: asset.deviceId,
    operator: asset.operator,
    activeTimeAllocation: asset.activeTimeAllocation,
    radioNumber: asset.radioNumber,
    hasDevice: asset.hasDevice,
    present: asset.present,
    synced: true,
    updatedExternally: false,
    status: asset.status,
    statusOrder: STATUS_ORDER[asset.status],
  };
}

function addDigUnitInfo(digUnit, activities) {
  const activity = attributeFromList(activities, 'assetId', digUnit.id) || {};
  digUnit.activity = { ...activity };
  return digUnit;
}

function addHaulTruckInfo(haulTruck, dispatches) {
  const dispatch = attributeFromList(dispatches, 'assetId', haulTruck.id) || {};
  haulTruck.dispatch = {
    digUnitId: dispatch.digUnitId || null,
    loadId: dispatch.loadId || null,
    dumpId: dispatch.dumpId || null,
    acknowledged: dispatch.acknowledged || false,
  };
  return haulTruck;
}

function haulTruckDispatchEqual(a, b) {
  return a.digUnitId === b.digUnitId && a.loadId === b.loadId && a.dumpId === b.dumpId;
}

function orderAssets(assets, assetOrdering) {
  if (assetOrdering === 'status') {
    assets.sort(firstBy('statusOrder').thenBy('name'));
  }
}

export default {
  name: 'DndRouteMain',
  components: {
    Container,
    UnassignedAssets,
    OtherAssets,
    AssignedLayout,
  },
  props: {
    orientation: { type: String, default: 'horizontal' },
    assetOrdering: { type: String, default: 'normal' },
    layoutSettings: { type: Object, default: () => ({ vertical: {}, horizontal: {} }) },
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
      attemptedWhilePendingUpdate: false,
    };
  },
  computed: {
    digUnitOptions() {
      const activities = this.digUnitActivities;
      const locations = this.locations;
      return this.fullAssets
        .filter(a => a.secondaryType === 'Dig Unit')
        .map(a => {
          const locationId = attributeFromList(activities, 'assetId', a.id, 'locationId');

          const locationName = attributeFromList(locations, 'id', locationId, 'name');

          const fullname = locationName ? `${a.name} (${locationName})` : a.name;

          return {
            id: a.id,
            name: a.name,
            locationId,
            fullname,
          };
        });
    },
    otherAssets() {
      const assets = this.fullAssets
        .filter(a => a.type !== 'Haul Truck' && a.secondaryType !== 'Dig Unit')
        .map(toLocalFullAsset);

      orderAssets(assets, this.assetOrdering);

      return assets;
    },
    unassignedAssets() {
      const routes = this.structure.routes;

      const uDigUnits = this.localDigUnits.filter(d => routes.every(r => r.digUnitId !== d.id));
      const uHaulTrucks = this.localHaulTrucks.filter(h => {
        const d = h.dispatch || {};
        return !d.digUnitId && !d.loadId && !d.dumpId;
      });

      return uDigUnits.concat(uHaulTrucks);
    },
  },
  watch: {
    fullAssets: {
      immediate: true,
      handler(fullAssets) {
        this.updateLocalHaulTrucks(fullAssets);
        this.updateLocalDigUnits(fullAssets);
        this.updateStructure();
      },
    },
    haulTruckDispatches: {
      immediate: true,
      handler() {
        this.updateLocalHaulTrucks(this.fullAssets);
        this.updateStructure();
      },
    },
    digUnitActivities: {
      immediate: true,
      handler() {
        this.updateLocalDigUnits(this.fullAssets);
        this.updateStructure();
      },
    },
    assetOrdering(newV, oldV) {
      if (newV !== oldV) {
        this.updateLocalHaulTrucks(this.fullAssets);
        this.updateLocalDigUnits(this.fullAssets);
        this.updateStructure();
      }
    },
  },
  methods: {
    updateLocalHaulTrucks(fullAssets) {
      // if dragging, all updates are suspended to prevent freezing issues
      if (this.draggedAsset || this.pendingUpdate) {
        this.pendingUpdate = true;
        this.attemptedWhilePendingUpdate = true;
        return;
      }

      this.pendingUpdate = false;
      this.attemptedWhilePendingUpdate = false;
      const currentlyHasAssets = this.localHaulTrucks.length !== 0;
      const newHTs = fullAssets
        .filter(a => a.type === 'Haul Truck' && a.hasDevice)
        .map(fa => {
          const ht = addHaulTruckInfo(toLocalFullAsset(fa), this.haulTruckDispatches);

          const oldAsset = attributeFromList(this.localHaulTrucks, 'id', ht.id) || {};

          if (currentlyHasAssets && !haulTruckDispatchEqual(ht.dispatch, oldAsset.dispatch)) {
            ht.updatedExternally = true;
          }

          ht.synced = true;

          return ht;
        });

      orderAssets(newHTs, this.assetOrdering);

      this.localHaulTrucks = newHTs;
    },
    updateLocalDigUnits(assets) {
      const digUnits = assets
        .filter(a => a.secondaryType === 'Dig Unit')
        .map(a => {
          return addDigUnitInfo(toLocalFullAsset(a), this.digUnitActivities);
        });

      orderAssets(digUnits, this.assetOrdering);

      this.localDigUnits = digUnits;
    },
    updateStructure() {
      this.localHaulTrucks.forEach(ht => {
        const d = ht.dispatch;
        this.structure.add(d.digUnitId, d.loadId, d.dumpId);
      });
    },
    setHaulTruck(asset, digUnitId = null, loadId = null, dumpId = null) {
      asset.dispatch = {
        digUnitId,
        loadId,
        dumpId,
      };

      asset.synced = false;

      this.localHaulTrucks = this.localHaulTrucks.slice();
      this.$emit('set-haul-truck', { assetId: asset.id, digUnitId, loadId, dumpId });
    },
    massSetHaulTrucks(assets, digUnitId = null, loadId = null, dumpId = null) {
      assets.forEach(asset => {
        if (asset && asset.type === 'Haul Truck') {
          asset.dispatch.digUnitId = digUnitId;
          asset.dispatch.loadId = loadId;
          asset.dispatch.dumpId = dumpId;

          asset.synced = false;
        }
      });

      const assetIds = assets.map(a => a.id);
      this.$emit('mass-set-haul-trucks', { assetIds, digUnitId, loadId, dumpId });
    },
    onSetUnassigned({ asset }) {
      if (asset.type === 'Haul Truck') {
        this.setHaulTruck(asset, null, null, null);
        return;
      }

      if (asset.secondaryType === 'Dig Unit') {
        this.removeDigUnitFromSource(asset);
      }
    },
    onAddRoute(initials = {}) {
      const opts = {
        title: 'Add Route',
        ...initials,
        digUnits: this.digUnitOptions,
        locations: this.locations,
        loadLocations: this.loadLocations,
        dumpLocations: this.dumpLocations,
      };
      this.$modal.create(AddRouteModal, opts).onClose(resp => {
        if (!resp) {
          return;
        }

        if (resp.digUnitId) {
          this.setDigUnitLocation(resp.digUnitId, resp.digUnitLocationId);
        }

        this.structure.add(resp.digUnitId, resp.loadId, resp.dumpId);
      });
    },
    onDragStart(asset) {
      this.draggedAsset = asset;
    },
    onDragEnd() {
      this.draggedAsset = null;
      if (this.pendingUpdate) {
        this.pendingUpdate = false;
        this.updateLocalHaulTrucks(this.fullAssets);
      }
    },
    onSetDigUnit({ digUnitId, loadId, dumpIds }) {
      // ensure that if moving between sources, do not bring other assets hts with them
      this.removeDigUnitFromSource(attributeFromList(this.localDigUnits, 'id', digUnitId));

      this.setDigUnitLocation(digUnitId, loadId);

      const affectedRoutes = this.structure.routes.filter(r => {
        return !r.digUnitId && r.loadId === loadId;
      });

      const affectedHaulTrucks = this.localHaulTrucks.filter(h => {
        const d = h.dispatch;
        return !d.digUnitId && d.loadId === loadId;
      });

      if (affectedHaulTrucks.length === 0) {
        return;
      }

      this.pendingUpdate = true;

      affectedRoutes.forEach(r => {
        const movedAssets = affectedHaulTrucks.filter(a => a.dispatch.dumpId === r.dumpId);
        if (movedAssets.length) {
          this.massSetHaulTrucks(movedAssets, digUnitId, null, r.dumpId);
          this.structure.add(digUnitId, null, r.dumpId);
        }
        this.structure.remove(null, loadId, r.dumpId);
      });

      setTimeout(() => this.onDragEnd(), 200);
    },
    removeDigUnitFromSource(digUnit) {
      if (!digUnit) {
        return;
      }

      // remove dig unit from dumps, keep current location
      const digUnitLocation = (digUnit.activity || {}).locationId;
      this.moveDumps({ digUnitId: digUnit.id }, { loadId: digUnitLocation });
    },
    onSetHaulTruck({ asset, digUnitId, loadId, dumpId }) {
      this.setHaulTruck(asset, digUnitId, loadId, dumpId);
    },
    onRemoveRoute(route) {
      this.structure.removeAllDumpsFor(route.digUnitId, route.loadId);
    },
    onConfirmClearRoute({ digUnitId, loadId }) {
      const ok = 'yes';
      const opts = {
        title: 'Clear Dig Unit',
        body:
          'All assets assigned to this route will be removed.\n\nAre you sure you want to continue?',
        ok,
      };

      this.$modal.create(ConfirmModal, opts).onClose(resp => {
        if (resp === ok) {
          this.clearRoute(digUnitId, loadId);
        }
      });
    },
    clearRoute(digUnitId, loadId) {
      if (!digUnitId && !loadId) {
        return;
      }

      const haulTrucks = this.localHaulTrucks.filter(h => {
        const d = h.dispatch || {};
        return d.digUnitId === digUnitId && d.loadId === loadId;
      });

      if (haulTrucks.length === 0) {
        console.error('[dnd] Cannot clear route as there are no haul trucks to move');
        return;
      }

      this.structure.removeAllDumpsFor(digUnitId, loadId);

      if (haulTrucks.length) {
        this.massSetHaulTrucks(haulTrucks, null, null, null);
      }
    },
    onRequestAddDump({ digUnitId, loadId }) {
      const opts = {
        title: 'Add Dump',
        digUnitId,
        loadId,
        digUnits: this.digUnitOptions,
        locations: this.locations,
        loadLocations: this.loadLocations,
        dumpLocations: this.dumpLocations,
      };

      this.$modal.create(AddRouteModal, opts).onClose(resp => {
        if (resp) {
          this.structure.add(resp.digUnitId, resp.loadId, resp.dumpId);
        }
      });
    },
    onRemoveDump(route) {
      this.structure.remove(route.digUnitId, route.loadId, route.dumpId);
    },
    onConfirmClearDump({ digUnitId, loadId, dumpId }) {
      const ok = 'yes';
      const opts = {
        title: 'Clear Dump',
        body: 'Are you sure you want to remove all assets from this dump?',
        ok,
      };

      this.$modal.create(ConfirmModal, opts).onClose(resp => {
        if (resp === ok) {
          this.clearDump(digUnitId, loadId, dumpId);
        }
      });
    },
    clearDump(digUnitId, loadId, dumpId) {
      const haulTrucks = this.localHaulTrucks.filter(h => {
        const d = h.dispatch;
        return d.digUnitId === digUnitId && d.loadId === loadId && d.dumpId === dumpId;
      });

      if (haulTrucks.length === 0) {
        console.error('[Dnd] Cannot clear dump that has zero assets');
        return;
      }

      this.structure.remove(digUnitId, loadId, dumpId);

      if (haulTrucks.length) {
        this.massSetHaulTrucks(haulTrucks, null, null, null);
      }
    },
    onMoveTrucks({ assetIds, digUnitId, loadId, dumpId }) {
      const opts = {
        title: 'Move Trucks To',
        submitName: 'Submit',
        digUnitId,
        loadId,
        dumpId,
        digUnits: this.digUnitOptions,
        locations: this.locations,
        loadLocations: this.loadLocations,
        dumpLocations: this.dumpLocations,
      };

      this.$modal.create(AddRouteModal, opts).onClose(resp => {
        if (!resp) {
          return;
        }

        if (resp.digUnitId) {
          this.setDigUnitLocation(resp.digUnitId, resp.digUnitLocationId);
        }

        // if there is a change
        if (resp.digUnitId === digUnitId && resp.loadId === loadId && resp.dumpId === dumpId) {
          console.info('[Dnd] No change in route, no assets moved');
          return;
        }

        const assets = this.localHaulTrucks.filter(a => assetIds.includes(a.id));

        this.massSetHaulTrucks(assets, resp.digUnitId, resp.loadId, resp.dumpId);
        this.structure.add(resp.digUnitId, resp.loadId, resp.dumpId);
        this.structure.remove(digUnitId, loadId, dumpId);
      });
    },
    onMoveDumps({ digUnitId, loadId, dumpIds }) {
      if (dumpIds.length === 0) {
        console.error('[Dnd] Cannot move 0 dumps');
        return;
      }

      const opts = {
        title: 'Move Dumps To',
        submitName: 'Move',
        digUnitId,
        loadId,
        digUnits: this.digUnitOptions,
        locations: this.locations,
        loadLocations: this.loadLocations,
        hideDump: true,
      };

      this.$modal.create(AddRouteModal, opts).onClose(resp => {
        if (resp) {
          this.moveDumps({ digUnitId, loadId }, resp);
        }
      });
    },
    moveDumps(from, to) {
      if (to.digUnitId && to.digUnitLocationId !== undefined) {
        this.setDigUnitLocation(to.digUnitId, to.digUnitLocationId);
      }

      // if there is a change
      /* eslint-disable-next-line eqeqeq */
      if (to.digUnitId == from.digUnitId && to.loadId == from.loadId) {
        console.info('[Dnd] No change in route, no dumps moved');
        return;
      }

      const affectedRoutes = this.structure.routes.filter(r => {
        /* eslint-disable-next-line eqeqeq */
        return r.digUnitId == from.digUnitId && r.loadId == from.loadId;
      });

      const affectedHaulTrucks = this.localHaulTrucks.filter(h => {
        const d = h.dispatch;
        /* eslint-disable-next-line eqeqeq */
        return d.digUnitId == from.digUnitId && d.loadId == from.loadId;
      });

      this.pendingUpdate = true;

      affectedRoutes.forEach(r => {
        const movedAssets = affectedHaulTrucks.filter(a => a.dispatch.dumpId === r.dumpId);

        if (movedAssets.length) {
          this.massSetHaulTrucks(movedAssets, to.digUnitId, to.loadId, r.dumpId);
          this.structure.add(to.digUnitId, to.loadId, r.dumpId);
        }

        this.structure.remove(r.digUnitId, r.loadId, r.dumpId);
      });

      setTimeout(() => {
        this.pendingUpdate = false;
        if (this.attemptedWhilePendingUpdate) {
          this.updateLocalHaulTrucks(this.fullAssets);
        }
      }, 500);
    },
    setDigUnitLocation(digUnitId, locationId = null) {
      const digUnit = attributeFromList(this.localDigUnits, 'id', digUnitId);
      const activity = attributeFromList(this.digUnitActivities, 'assetId', digUnitId) || {};

      if (!digUnit || activity.locationId === locationId) {
        return;
      }

      digUnit.activity.locationId = locationId;
      digUnit.synced = false;

      this.localDigUnits = this.localDigUnits.slice();
      this.$emit('set-dig-unit', { assetId: digUnitId, activity: digUnit.activity });
    },
    onDropNewDigUnit({ addedIndex, removedIndex, payload }) {
      // is added
      if (addedIndex !== null && removedIndex === null) {
        this.onAddRoute({ digUnitId: payload.id });
      }
    },
  },
};
</script>

<style>
.dnd-route-main .add-route,
.dnd-route-main .new-dig-unit-container {
  user-select: none;
  height: 3rem;
  line-height: 3rem;
  width: 100%;
  color: #fff;
  opacity: 0.5;
  text-align: center;
  cursor: pointer;
  border: 1px dashed #364c59;
  background-color: #20323b;
  margin: 0.75rem 0;
}

.dnd-route-main .add-route:not(.no-hover):hover,
.dnd-route-main .new-dig-unit-container:hover {
  background-color: #20323b;
  opacity: 1;
}
</style>