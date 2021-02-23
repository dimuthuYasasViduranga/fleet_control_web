<template>
  <Page class="page watercart-client" androidStatusBarBackground="#0c1419">
    <HeaderBar
      :view="view"
      :primaryViews="primaryViews"
      :secondaryViews="secondaryViews"
      initialExceptionGroup="Ready"
      @changeView="changeView"
      @confirmLogout="onConfirmLogout"
    />

    <WaterCartHome
      v-if="view === 'home'"
      :assets="assets"
      :haulTruckDispatches="haulDispatches"
      :locations="locations"
      :digUnitActivities="digUnitActivities"
    />

    <DispatcherMessages v-else-if="view === 'dispatcher messages'" />

    <Map v-else-if="view === 'map'" :dispatch="localDispatch" />
  </Page>
</template>

<script>
import { mapState } from 'vuex';

import HeaderBar from '../common/HeaderBar.vue';

import Map from '../common/map/Map.vue';
import DispatcherMessages from '../common/pages/dispatcher_messages/DispatcherMessages.vue';
import EngineHoursModal from '../common/modals/EngineHoursModal.vue';
import WaterCartHome from './pages/WaterCartHome.vue';
export default {
  name: 'WatercartClient',
  components: {
    HeaderBar,
    Map,
    DispatcherMessages,
    WaterCartHome,
  },
  data: () => {
    const home = 'home';
    return {
      view: home,
      primaryViews: [home],
      secondaryViews: ['radio numbers', 'dispatcher messages'],
    };
  },
  computed: {
    ...mapState({
      asset: state => state.asset,
      operator: state => state.operator,
      digUnitActivities: state => state.digUnitActivities,
    }),
    ...mapState('constants', {
      locations: state => state.locations,
      assets: state => state.assets,
    }),
    ...mapState('watercart', {
      haulDispatches: state => state.haulDispatches,
    }),
  },
  mounted() {
    this.$emit('mounted');
    const { promptEngineHoursOnLogin, engineHours, operator } = this.$store.state;

    // if prompt, no engine hours or change in operator or > max age
    if (
      promptEngineHoursOnLogin &&
      (!engineHours ||
        engineHours.operatorId !== operator.id ||
        Date.now() - engineHours.timestamp.getTime() > REQUIRES_NEW)
    ) {
      this.onOpenEngineHoursModal();
    }
  },
  methods: {
    changeView(view) {
      this.view = view;
    },
    onConfirmLogout() {
      this.$emit('confirmLogout');
    },
    onOpenEngineHoursModal() {
      const opts = {
        asset: this.asset,
        operator: this.operator,
      };

      this.$modalBus.open(EngineHoursModal, opts);
    },
  },
};
</script>