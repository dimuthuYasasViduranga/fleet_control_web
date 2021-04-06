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
};
</script>