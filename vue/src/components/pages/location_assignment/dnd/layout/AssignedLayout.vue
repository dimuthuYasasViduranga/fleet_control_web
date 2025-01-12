<template>
  <div class="assigned-layout">
    <!-- vertical template -->
    <PerfectScrollbar v-if="orientation === 'vertical'">
      <div class="vertical-layout">
        <RouteV
          v-for="(route, index) in groupedRoutes"
          :key="index"
          :readonly="readonly"
          :digUnitId="route.digUnitId"
          :loadId="route.loadId"
          :dumpIds="route.dumpIds"
          :digUnits="digUnits"
          :haulTrucks="haulTrucks"
          :dimLocations="dimLocations"
          :locations="locations"
          :columns="layoutSettings.vertical.columns"
          @drag-start="propagate('drag-start', $event)"
          @drag-end="propagate('drag-end', $event)"
          @set-dig-unit="propagate('set-dig-unit', $event)"
          @set-haul-truck="propagate('set-haul-truck', $event)"
          @remove-route="propagate('remove-route', $event)"
          @clear-route="propagate('clear-route', $event)"
          @request-add-dump="propagate('request-add-dump', $event)"
          @remove-dump="propagate('remove-dump', $event)"
          @clear-dump="propagate('clear-dump', $event)"
          @move-trucks="propagate('move-trucks', $event)"
          @move-dumps="propagate('move-dumps', $event)"
        />
      </div>
    </PerfectScrollbar>

    <!-- horizontal template -->
    <div v-else class="horizontal-layout">
      <RouteH
        v-for="(route, index) in groupedRoutes"
        :key="index"
        :readonly="readonly"
        :digUnitId="route.digUnitId"
        :loadId="route.loadId"
        :dumpIds="route.dumpIds"
        :digUnits="digUnits"
        :haulTrucks="haulTrucks"
        :dimLocations="dimLocations"
        :locations="locations"
        @drag-start="propagate('drag-start', $event)"
        @drag-end="propagate('drag-end', $event)"
        @set-dig-unit="propagate('set-dig-unit', $event)"
        @set-haul-truck="propagate('set-haul-truck', $event)"
        @remove-route="propagate('remove-route', $event)"
        @clear-route="propagate('clear-route', $event)"
        @request-add-dump="propagate('request-add-dump', $event)"
        @remove-dump="propagate('remove-dump', $event)"
        @clear-dump="propagate('clear-dump', $event)"
        @move-trucks="propagate('move-trucks', $event)"
        @move-dumps="propagate('move-dumps', $event)"
      />
    </div>
  </div>
</template>

<script>
import { PerfectScrollbar } from 'vue2-perfect-scrollbar';

import RouteV from './vertical/RouteV.vue';
import RouteH from './horizontal/RouteH.vue';

import { attributeFromList, Dictionary } from '@/code/helpers';
import { firstBy } from 'thenby';

function groupRoutes(routes, digUnits, locations) {
  const dict = new Dictionary();

  routes.forEach(r => {
    dict.append([r.digUnitId, r.loadId], r.dumpId);
  });

  return dict.map(([digUnitId, loadId], dumpIds) => {
    const digUnit = attributeFromList(digUnits, 'id', digUnitId) || {};
    const locationId = (digUnit.activity || {}).locationId || loadId;
    const loadName = attributeFromList(locations, 'id', locationId, 'name') || '';
    return {
      digUnitId,
      digUnitName: digUnit.name,
      loadId,
      loadName,
      dumpIds,
    };
  });
}

export default {
  name: 'AssignedLayout',
  components: {
    PerfectScrollbar,
    RouteH,
    RouteV,
  },
  props: {
    readonly: Boolean,
    orientation: { type: String, default: 'vertical' },
    layoutSettings: { type: Object, default: () => ({ vertical: {}, horizontal: {} }) },
    structure: { type: Object, required: true },
    haulTrucks: { type: Array, default: () => [] },
    digUnits: { type: Array, default: () => [] },
    dimLocations: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    loadLocations: { type: Array, default: () => [] },
    dumpLocations: { type: Array, default: () => [] },
  },
  computed: {
    groupedRoutes() {
      const routes = groupRoutes(this.structure.routes, this.digUnits, this.dimLocations);

      const orderBy = this.layoutSettings[this.orientation].orderBy;
      // The first sorts are to move initial nulls to the end
      if (orderBy === 'dig-unit') {
        return routes.sort(
          firstBy(r => !r.digUnitName)
            .thenBy('digUnitName')
            .thenBy('loadName'),
        );
      } else {
        return routes.sort(
          firstBy(r => !r.loadName)
            .thenBy('loadName')
            .thenBy('digUnitName'),
        );
      }
    },
  },
  methods: {
    propagate(topic, event) {
      this.$emit(topic, event);
    },
  },
};
</script>

<style>
.vertical-layout {
  padding-top: 1rem;
  width: 100%;
  display: flex;
}

.vertical-layout .route-v {
  margin-right: 1rem;
}

.horizontal-layout .route-h {
  margin-bottom: 0.5rem;
}
</style>