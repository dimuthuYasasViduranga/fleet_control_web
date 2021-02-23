<template>
  <GridLayout width="100%" height="100%" rows="* 5*">
    <GridLayout row="0" class="header" columns="6* 2* *">
      <CenteredLabel class="name" col="0" text="Routes" />
      <CenteredLabel class="count" col="1" text="Count" />
    </GridLayout>
    <ListView
      v-if="routes.length"
      class="routes"
      row="1"
      orientation="vertical"
      for="route in routes"
    >
      <v-template>
        <GridLayout class="route" columns="6* 2* *">
          <CenteredLabel class="name" col="0" :text="route.name" />
          <CenteredLabel class="count" col="1" :text="route.assets.length" />
          <Button class="more" col="2" text="List" @tap="onListAssets(route)" />
        </GridLayout>
      </v-template>
    </ListView>
    <CenteredLabel v-else class="no-routes" row="1" text="No Active Routes" />
  </GridLayout>
</template>

<script>
import { firstBy } from 'thenby';
import { attributeFromList } from '../../code/helper';
import CenteredLabel from '../../common/CenteredLabel.vue';
import WaterCartRouteModal from '../modals/WaterCartRouteModal.vue';

function toRoutes(dispatches, assets, activities, locations) {
  return groupByDigUnitDump(dispatches).map(route => {
    const digUnitName = attributeFromList(assets, 'id', route.digUnitId, 'name');

    const digUnitLocation = getDigUnitLocation(route.digUnitId, activities, locations);
    const dumpName = attributeFromList(locations, 'id', route.dumpId, 'name');

    const assignedAssets = assets.filter(a => route.assetIds.includes(a.id));

    const name = toRouteName(digUnitName, digUnitLocation, dumpName);

    return {
      name,
      digUnitId: route.digUnitId,
      digUnitName,
      digUnitLocation,
      dumpId: route.dumpId,
      dumpName,
      assets: assignedAssets,
    };
  });
}

function groupByDigUnitDump(dispatches) {
  const groupMap = dispatches
    .filter(d => d.digUnitId && d.dumpId)
    .reduce((acc, dispatch) => {
      const id = `${dispatch.digUnitId}|${dispatch.dumpId}`;
      (acc[id] = acc[id] || []).push(dispatch);
      return acc;
    }, {});

  return Object.entries(groupMap).map(([key, dispatches]) => {
    const [digUnitIdStr, dumpIdStr] = key.split('|');
    const digUnitId = parseInt(digUnitIdStr, 10);
    const dumpId = parseInt(dumpIdStr, 10);
    const assetIds = dispatches.map(d => d.assetId);
    return {
      digUnitId,
      dumpId,
      assetIds,
    };
  });
}

function getDigUnitLocation(assetId, activities, locations) {
  const locationId = attributeFromList(activities, 'assetId', assetId, 'locationId');
  return attributeFromList(locations, 'id', locationId, 'name');
}

function toRouteName(digUnitName, digUnitLocation, dumpName) {
  if (digUnitLocation) {
    return `${digUnitName} (${digUnitLocation}) \u27f9 ${dumpName}`;
  }
  return `${digUnitName} \u27f9 ${dumpName}`;
}

export default {
  name: 'WaterCartHome',
  components: {
    CenteredLabel,
  },
  props: {
    assets: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    haulTruckDispatches: { type: Array, default: () => [] },
    digUnitActivities: { type: Array, default: () => [] },
  },
  computed: {
    routes() {
      const routes = toRoutes(
        this.haulTruckDispatches,
        this.assets,
        this.digUnitActivities,
        this.locations,
      );

      routes.sort(firstBy('digUnitName').thenBy('dumpName'));
      return routes;
    },
  },
  watch: {
    routes(newRoutes, oldRoutes) {
      const newRouteIds = newRoutes.map(r => `${r.digUnitId}|${r.dumpId}`);
      const oldRouteIds = oldRoutes.map(r => `${r.digUnitId}|${r.dumpId}`);

      const hasNewAdded = newRouteIds.some(nr => !oldRouteIds.includes(nr));
      const hasOldRemoved = oldRouteIds.some(or => !newRouteIds.includes(or));

      if (hasNewAdded || hasOldRemoved) {
        this.$avPlayer.playNotification();
      }
    },
  },
  methods: {
    onListAssets(route) {
      this.$modalBus.open(WaterCartRouteModal, { ...route });
    },
  },
};
</script>

<style scoped>
.header {
  height: 70;
  border-bottom-width: 1;
  border-bottom-color: #d6d7d7;
  background-color: #1c323d;
}

.route {
  height: 80;
}

.name,
.count {
  font-size: 33;
}

.more {
  font-size: 20;
  margin: 10 5;
}

.no-routes {
  font-size: 50;
}
</style>