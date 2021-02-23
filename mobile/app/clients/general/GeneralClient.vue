<template>
  <Page class="page general-client" androidStatusBarBackground="#0c1419">
    <HeaderBar
      :view="view"
      :primaryViews="primaryViews"
      :secondaryViews="secondaryViews"
      initialExceptionGroup="Ready"
      @changeView="changeView"
      @confirmLogout="onConfirmLogout"
    />

    <Map v-if="view === 'map'" />

    <DispatcherMessages v-else-if="view === 'dispatcher messages'" />
  </Page>
</template>

<script>
import HeaderBar from '../common/HeaderBar.vue';

import Map from '../common/map/Map.vue';
import DispatcherMessages from '../common/pages/dispatcher_messages/DispatcherMessages.vue';
import EngineHoursModal from '../common/modals/EngineHoursModal.vue';

const REQUIRES_NEW = 12 * 3600 * 1000;

export default {
  name: 'GeneralClient',
  components: {
    HeaderBar,
    Map,
    DispatcherMessages,
  },
  props: {
    operator: { type: Object, required: true },
    asset: { type: Object, required: true },
  },
  data: () => {
    const home = 'map';
    return {
      view: home,
      primaryViews: [{ id: home, text: 'home' }],
      secondaryViews: ['radio numbers', 'dispatcher messages'],
    };
  },
  mounted() {
    this.$emit('mounted');
    const operator = this.operator;
    const { promptEngineHoursOnLogin, engineHours } = this.$store.state;

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