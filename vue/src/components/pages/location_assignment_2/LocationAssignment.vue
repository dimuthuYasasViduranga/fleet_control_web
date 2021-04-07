<template>
  <hxCard class="location-assignment-2" :hideTitle="true">
    <loaded>
      <div class="settings"></div>
      <DndRouteMain
        :fullAssets="fullAssets"
        :locations="locations"
        :loadLocations="loadLocations"
        :dumpLocations="dumpLocations"
        :digUnitActivities="digUnitActivities"
        :haulTruckDispatches="haulTruckDispatches"
        @set-haul-truck="onUpdateHaulTruck"
        @mass-set-haul-trucks="onMassUpdateHaulTrucks"
      />
    </loaded>
  </hxCard>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import Loaded from '@/components/Loaded.vue';

import DndRouteMain from './dnd/DndRouteMain.vue';

export default {
  name: 'LocationAssignment',
  components: {
    hxCard,
    Loaded,
    DndRouteMain,
  },
  computed: {
    ...mapState('constants', {
      locations: state => state.locations,
      loadLocations: state => state.loadLocations,
      dumpLocations: state => state.dumpLocations,
    }),
    ...mapState({
      haulTruckDispatches: state => state.haulTruck.currentDispatches,
      digUnitActivities: state => state.digUnit.currentActivities,
    }),
    fullAssets() {
      return this.$store.getters.fullAssets;
    },
  },
  methods: {
    onUpdateHaulTruck({ assetId, digUnitId, loadId, dumpId }) {
      const payload = {
        asset_id: assetId,
        dig_unit_id: digUnitId,
        load_location_id: loadId,
        dump_location_id: dumpId,
        timestamp: Date.now(),
      };

      this.$channel
        .push('haul:set dispatch', payload)
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to update dispatch'));
    },
    onMassUpdateHaulTrucks({ assetIds, digUnitId, loadId, dumpId }) {
      const payload = {
        asset_ids: assetIds,
        dispatch: {
          dig_unit_id: digUnitId,
          load_location_id: loadId,
          dump_location_id: dumpId,
        },
      };

      this.$channel
        .push('haul:set mass dispatch', payload)
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to update mass dispatch'));
    },
  },
};
</script>