<template>
  <hxCard class="location-assignment-2" :hideTitle="true">
    <loaded>
      <div class="settings"></div>
      <DndRouteMain
        :assets="assets"
        :locations="locations"
        :loadLocations="loadLocations"
        :dumpLocations="dumpLocations"
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
      assets: state => state.assets,
      locations: state => state.locations,
      loadLocations: state => state.loadLocations,
      dumpLocations: state => state.dumpLocations,
    }),
  },
};
</script>