<template>
  <Page class="page haul-truck-client" androidStatusBarBackground="#0c1419">
    <HeaderBar
      :view="view"
      :primaryViews="primaryViews"
      :secondaryViews="secondaryViews"
      initialExceptionGroup="Ready"
      @changeView="changeView"
      @confirmLogout="onConfirmLogout"
    />

    <Dispatch
      v-if="view === 'dispatch'"
      :haulTruckDispatch="localDispatch"
      :locations="locations"
      :assets="assets"
      :digUnitActivities="digUnitActivities"
      @acknowledge="onAcknowledgePress"
      @openEngineHours="onOpenEngineHoursModal"
    />

    <DispatcherMessages v-else-if="view === 'dispatcher messages'" />

    <Map v-else-if="view === 'map'" :dispatch="localDispatch" />

    <TallyHome v-else-if="view === 'tally'" :asset="asset" :operator="operator" />

    <TallyTable v-else-if="view === 'tally table'" :asset="asset" :operator="operator" />
  </Page>
</template>

<script>
import { mapState } from 'vuex';

import HeaderBar from '../common/HeaderBar.vue';
import DispatcherMessages from '../common/pages/dispatcher_messages/DispatcherMessages.vue';
import Map from '../common/map/Map.vue';
import TallyHome from './pages/tally_home/TallyHome.vue';
import TallyTable from './pages/tally_table/TallyTable.vue';

import EngineHoursModal from '../common/modals/EngineHoursModal.vue';

import Dispatch from './pages/dispatch/Dispatch.vue';

import { attributeFromList, toUtcDate } from '../code/helper';
import { toTree, flattenTree } from '../code/tree';

const REQUIRES_NEW = 12 * 3600 * 1000;

export default {
  name: 'HaulTruckClient',
  components: {
    HeaderBar,
    Dispatch,
    DispatcherMessages,
    Map,
    TallyHome,
    TallyTable,
  },
  props: {
    operator: { type: Object, required: true },
    asset: { type: Object, required: true },
  },
  data() {
    const home = 'dispatch';
    return {
      view: home,
      home,
      primaryViews: [{ id: home, text: 'home' }],
      secondaryViews: ['radio numbers', 'dispatcher messages', 'map'],
      localDispatch: {
        id: null,
        assetId: null,
        digUnitId: null,
        dumpId: null,
        timestamp: null,
        acknowledgeId: null,
        digUnitIdChanged: true,
        dumpIdChanged: true,
      },
    };
  },
  computed: {
    ...mapState('constants', {
      locations: state => state.locations,
      assets: state => state.assets,
    }),
    ...mapState({
      unreadOperatorMessages: state => state.unreadOperatorMessages,
      digUnitActivities: state => state.digUnitActivities,
      dispatch: state => state.haulTruck.dispatch,
    }),
  },
  watch: {
    dispatch: {
      immediate: true,
      handler(newDispatch) {
        this.updateDispatch(newDispatch || {});
        if (newDispatch && !newDispatch.acknowledgeId && this.secondaryViews.includes(this.view)) {
          this.changeView('dispatch');
        }
      },
    },
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
    updateDispatch(dispatch) {
      if (this.localDispatch.id === dispatch.id) {
        this.localDispatch.acknowledgeId = dispatch.acknowledgeId;
        return;
      }

      // if the assetId changes, everything has changed
      const assetChanged = this.localDispatch.assetId !== dispatch.assetId;
      const digUnitIdChanged = this.localDispatch.digUnitId !== dispatch.digUnitId;
      const dumpChanged = this.localDispatch.dumpId !== dispatch.dumpId;

      const newDispatch = {
        id: dispatch.id,
        assetId: dispatch.assetId,
        digUnitId: dispatch.digUnitId,
        dumpId: dispatch.dumpId,
        timestamp: toUtcDate(dispatch.timestamp),
        acknowledgeId: dispatch.acknowledgeId,
        digUnitIdChanged: assetChanged || digUnitIdChanged,
        dumpIdChanged: assetChanged || dumpChanged,
      };
      this.localDispatch = newDispatch;
    },
    onAcknowledgePress() {
      this.localDispatch.digUnitIdChanged = false;
      this.localDispatch.dumpIdChanged = false;
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

<style>
</style>
