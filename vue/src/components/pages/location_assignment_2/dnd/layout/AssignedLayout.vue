<template>
  <div class="assigned-layout">
    <!-- quick add dig unit dropzone -->

    <!-- vertical template -->
    <PerfectScrollbar v-if="orientation === 'vertical'">
      <div class="vertical-layout">
        <RouteV
          v-for="(route, index) in groupedRoutes"
          :key="index"
          :digUnitId="route.digUnitId"
          :loadId="route.loadId"
          :dumpIds="route.dumpIds"
          :digUnits="digUnits"
          :haulTrucks="haulTrucks"
          :locations="locations"
          :columns="layoutSettings.vertical.columns"
          @drag-start="propagate('drag-start', $event)"
          @drag-end="propagate('drag-end', $event)"
          @set-haul-truck="propagate('set-haul-truck', $event)"
          @remove-route="propagate('remove-route', $event)"
          @clear-route="propagate('clear-route', $event)"
          @request-add-dump="propagate('request-add-dump', $event)"
          @remove-dump="propagate('remove-dump', $event)"
          @clear-dump="propagate('clear-dump', $event)"
          @move-trucks="propagate('move-trucks', $event)"
        />
      </div>
    </PerfectScrollbar>

    <!-- horizontal template -->
    <div v-else class="horizontal-layout">
      <RouteH
        v-for="(route, index) in groupedRoutes"
        :key="index"
        :digUnitId="route.digUnitId"
        :loadId="route.loadId"
        :dumpIds="route.dumpIds"
        :digUnits="digUnits"
        :haulTrucks="haulTrucks"
        :locations="locations"
        @drag-start="propagate('drag-start', $event)"
        @drag-end="propagate('drag-end', $event)"
        @set-haul-truck="propagate('set-haul-truck', $event)"
        @remove-route="propagate('remove-route', $event)"
        @clear-route="propagate('clear-route', $event)"
        @request-add-dump="propagate('request-add-dump', $event)"
        @remove-dump="propagate('remove-dump', $event)"
        @clear-dump="propagate('clear-dump', $event)"
        @move-trucks="propagate('move-trucks', $event)"
      />
    </div>
  </div>
</template>

<script>
import { Container, Draggable } from 'vue-smooth-dnd';
import { PerfectScrollbar } from 'vue2-perfect-scrollbar';

import RouteV from './vertical/RouteV.vue';
import RouteH from './horizontal/RouteH.vue';

import AddRouteModal from '../AddRouteModal.vue';
import ConfirmModal from '@/components/modals/ConfirmModal.vue';
import { attributeFromList, Dictionary } from '@/code/helpers';

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

export default {
  name: 'AssignedLayout',
  components: {
    Container,
    Draggable,
    PerfectScrollbar,
    RouteH,
    RouteV,
  },
  props: {
    orientation: { type: String, default: 'vertical' },
    layoutSettings: { type: Object, default: () => ({ vertical: {}, horizontal: {} }) },
    structure: { type: Object, required: true },
    haulTrucks: { type: Array, default: () => [] },
    digUnits: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    loadLocations: { type: Array, default: () => [] },
    dumpLocations: { type: Array, default: () => [] },
  },
  computed: {
    groupedRoutes() {
      return groupRoutes(this.structure.routes);
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