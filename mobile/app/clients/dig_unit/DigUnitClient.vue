<template>
  <Page class="page dig-unit-client" androidStatusBarBackground="#0c1419">
    <HeaderBar
      :view="view"
      :primaryViews="primaryViews"
      :secondaryViews="secondaryViews"
      initialExceptionGroup="Ready"
      @changeView="changeView"
      @confirmLogout="onConfirmLogout"
    />

    <DigUnitHome
      v-if="view === 'home'"
      :class="{ changed: activityChanged }"
      :asset="asset"
      :operator="operator"
      :activity="localActivity"
    />

    <Map v-else-if="view === 'map'" />

    <DispatcherMessages v-else-if="view === 'dispatcher messages'" />
  </Page>
</template>

<script>
import HeaderBar from '../common/HeaderBar.vue';
import EngineHoursModal from '../common/modals/EngineHoursModal.vue';
import { parseActivity } from '../../store/modules/dig_unit';

import Map from '../common/map/Map.vue';
import DispatcherMessages from '../common/pages/dispatcher_messages/DispatcherMessages.vue';
import DigUnitHome from './pages/home/DigUnitHome.vue';

const REQUIRES_NEW = 12 * 3600 * 1000;
const COLOR_CHANGE_DURATION = 2 * 1000;

function copyActivity(activity) {
  return {
    id: activity.id,
    locationId: activity.locationId,
    materialTypeId: activity.materialTypeId,
    loadStyleId: activity.loadStyleId,
  };
}

function changed(a, b, keys) {
  return keys.some(key => a[key] !== b[key]);
}

export default {
  name: 'DigUnitClient',
  components: {
    HeaderBar,
    DigUnitHome,
    DispatcherMessages,
    Map,
  },
  props: {
    operator: { type: Object, required: true },
    asset: { type: Object, required: true },
  },
  data: () => {
    const home = 'home';
    return {
      view: home,
      primaryViews: [home],
      secondaryViews: ['map', 'radio numbers', 'dispatcher messages'],
      localActivity: parseActivity({}),
      activityChanged: false,
      activityChangedTimeout: null,
    };
  },
  computed: {
    activity() {
      return this.$store.state.digUnit.activity;
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
  watch: {
    activity: {
      immediate: true,
      handler(activity) {
        const newActivity = copyActivity(activity || {});
        const hasChanged = changed(newActivity, this.localActivity, [
          'locationId',
          'materialTypeId',
          'loadStyleId',
        ]);

        if (hasChanged) {
          this.setActivityChanged();
          this.$avPlayer.playNotification();
        }
        this.localActivity = newActivity;
      },
    },
  },
  methods: {
    setActivityChanged() {
      clearTimeout(this.activityChangedTimeout);
      this.activityChanged = true;
      this.activityChangedTimeout = setTimeout(() => {
        this.activityChanged = false;
      }, COLOR_CHANGE_DURATION);
    },
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

<style>
.dig-unit-main .heading {
  font-size: 50;
}

.dig-unit-main .message {
  font-size: 40;
}
</style>