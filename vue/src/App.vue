<template>
  <div>
    <Layout :routes="routes" :username="username" :logout="logout" :login="login">
      <template slot="header">
        <TimezoneSelector v-tooltip="'Set Timezone'" />
        <ChatButton v-tooltip="'Chat'" />
        <Icon
          v-tooltip="'Global Actions'"
          class="global-action-icon"
          :icon="cellTowerIcon"
          @click="onOpenGlobalActions()"
        />
      </template>
    </Layout>
    <!-- This is persistent and a fixed overlay -->
    <ChatOverlay />
    <ChatButtonFloating />
    <NotificationBar />
    <AssetAssignmentModal />
    <LiveTimeAllocationModal />
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import Layout from 'hx-layout/Layout.vue';

import TimezoneSelector from './components/header_buttons/TimezoneSelector.vue';
import ChatButton from './components/header_buttons/ChatButton.vue';
import ChatButtonFloating from './components/header_buttons/ChatButtonFloating.vue';
import ChatOverlay from './components/chat_overlay/ChatOverlay.vue';
import NotificationBar from './components/header_buttons/NotificationBar.vue';
import AssetAssignmentModal from './components/asset_assignment_modal/AssetAssignmentModal.vue';
import LiveTimeAllocationModal from './components/live_time_allocation_modal/LiveTimeAllocationModal.vue';
import CellTowerIcon from './components/icons/CellTower.vue';
import GlobalActionsModal from './components/modals/GlobalActionsModal.vue';

export default {
  name: 'app',
  components: {
    Layout,
    Icon,
    TimezoneSelector,
    ChatButton,
    ChatOverlay,
    ChatButtonFloating,
    NotificationBar,
    AssetAssignmentModal,
    LiveTimeAllocationModal,
  },
  props: {
    routes: Array,
    logout: Function,
    login: Function,
  },
  data: () => {
    return {
      cellTowerIcon: CellTowerIcon,
    };
  },
  computed: {
    ...mapState('connection', {
      channelAlive: state => state.isAlive,
      userToken: state => state.userToken,
    }),
    ...mapState('constants', {
      username: state => state?.user?.name || 'Unknown User',
    }),
  },
  watch: {
    channelAlive(newAlive, oldAlive) {
      if (oldAlive && !newAlive) {
        console.error('[Channel] The channel has been corrupted, recreating');
        this.initialiseChannel();
      }
    },
    $route(to, from) {
      if (to && from && to.name !== from.name) {
        this.$channel.push('set page visited', { page: to.name });
      }
    },
  },
  mounted() {
    this.initialiseChannel();
  },
  methods: {
    initialiseChannel() {
      const channel = this.$channel;
      const { dispatch, commit } = this.$store;

      channel.setOnConnect(this.onJoin);
      dispatch('connection/attachMonitor', channel);

      const presenceSyncCallback = presence => dispatch('connection/setPresence', presence);
      channel.create(this.$hostname, this.userToken, presenceSyncCallback);

      channel.setOns([
        // settings
        ['set settings', data => commit('settings/set', data)],

        // devices
        ['set devices', data => dispatch('deviceStore/setDevices', data.devices)],
        [
          'set device assignments',
          data => {
            dispatch('deviceStore/setCurrentDeviceAssignments', data.current);
            dispatch('deviceStore/setHistoricDeviceAssignments', data.historic);
          },
        ],
        ['set pending devices', data => dispatch('deviceStore/setPendingDevices', data)],

        // semi-constants
        [
          'set asset data',
          data => {
            dispatch('constants/setAssetTypes', data.asset_types);
            dispatch('constants/setAssets', data.assets);
          },
        ],
        ['set location data', data => dispatch('constants/setLocationData', data.locations)],
        [
          'set operator message types',
          data => {
            dispatch('constants/setOperatorMessageTypes', data.message_types);
            dispatch('constants/setOperatorMessageTypeTree', data.message_type_tree);
          },
        ],
        [
          'set operator message type tree',
          data => {
            dispatch('constants/setOperatorMessageTypeTree', data.message_type_tree);
          },
        ],
        [
          'set calendar data',
          data => {
            dispatch('constants/setShifts', data.shifts);
            dispatch('constants/setShiftTypes', data.shift_types);
          },
        ],
        ['set asset radios', data => dispatch('constants/setRadioNumbers', data.asset_radios)],
        ['set operators', data => dispatch('constants/setOperators', data.operators)],
        ['set dispatchers', data => dispatch('constants/setDispatchers', data.dispatchers)],
        [
          'set time code tree elements',
          data => dispatch('constants/setTimeCodeTreeElements', data.time_code_tree_elements),
        ],
        [
          'set time code data',
          data => {
            dispatch('constants/setTimeCodeTreeElements', data.time_code_tree_elements);
            dispatch('constants/setTimeCodes', data.time_codes);
            dispatch('constants/setTimeCodeGroups', data.time_code_groups);
            dispatch('constants/setTimeCodeCategories', data.time_code_categories);
          },
        ],
        [
          'set pre-start forms',
          data => dispatch('constants/setPreStartForms', data.pre_start_forms),
        ],
        [
          'set pre-start categories',
          data => dispatch('constants/setPreStartControlCategories', data.categories),
        ],
        ['set routing data', data => dispatch('constants/setRoutingData', data.routing)],

        // shared
        ['set fleetops data', data => dispatch('setFleetOpsData', data)],
        [
          'set engine hours',
          data => {
            dispatch('setCurrentEngineHours', data.current);
            dispatch('setHistoricEngineHours', data.historic);
          },
        ],
        ['set activity log', data => dispatch('setActivityLog', data.activities)],
        ['set operator messages', data => dispatch('setOperatorMessages', data.messages)],
        ['set dispatcher messages', data => dispatch('setDispatcherMessages', data.messages)],
        [
          'set pre-start submissions',
          data => dispatch('setCurrentPreStartSubmissions', data.current),
        ],
        ['new track', resp => dispatch('trackStore/addTrack', resp.track)],
        [
          'set time allocations',
          data => {
            dispatch('setActiveTimeAllocations', { allocations: data.active, action: data.action });
            dispatch('setHistoricTimeAllocations', data.historic);
          },
        ],
      ]);

      // haul truck specific calls
      channel.setOns([
        [
          'haul:set dispatches',
          data => {
            dispatch('haulTruck/setCurrentDispatches', data.current);
            dispatch('haulTruck/setHistoricDispatches', data.historic);
          },
        ],
      ]);

      // dig unit specific calls
      channel.setOns([
        [
          'dig:set activities',
          data => {
            dispatch('digUnit/setCurrentActivities', data.current);
            dispatch('digUnit/setHistoricActivities', data.historic);
          },
        ],
      ]);
    },
    onJoin(resp) {
      const { dispatch, commit } = this.$store;

      commit('settings/set', resp.settings);

      [
        ['constants/setPermissions', resp.permissions],

        // semi-constants
        ['constants/setTimeCodeTreeElements', resp.time_code_tree_elements],
        ['constants/setOperatorMessageTypeTree', resp.operator_message_type_tree],
        ['constants/setRadioNumbers', resp.radio_numbers],
        ['constants/setOperators', resp.operators],
        ['constants/setDispatchers', resp.dispatchers],
        ['constants/setPreStartForms', resp.pre_start_forms],
        ['constants/setPreStartTicketStatusTypes', resp.pre_start_ticket_status_types],
        ['constants/setPreStartControlCategories', resp.pre_start_control_categories],
        ['constants/setRoutingData', resp.routing],

        // devices
        ['deviceStore/setDevices', resp.devices],
        ['deviceStore/setCurrentDeviceAssignments', resp.device_assignments.current],
        ['deviceStore/setHistoricDeviceAssignments', resp.device_assignments.historic],
        ['deviceStore/setPendingDevices', resp.pending_devices],

        // shared
        ['setActivityLog', resp.activities],
        ['setOperatorMessages', resp.operator_messages],
        ['setDispatcherMessages', resp.dispatcher_messages],
        ['setHistoricTimeAllocations', resp.time_allocations.historic],
        [
          'setActiveTimeAllocations',
          { allocations: resp.time_allocations.active, action: resp.action },
        ],
        ['setCurrentEngineHours', resp.engine_hours.current],
        ['setHistoricEngineHours', resp.engine_hours.historic],
        ['setFleetOpsData', resp.fleetops_data],
        ['setCurrentPreStartSubmissions', resp.current_pre_start_submissions],
        ['trackStore/setTracks', resp.tracks],

        // haul truck specific
        ['haulTruck/setCurrentDispatches', resp.haul_truck.dispatches.current],
        ['haulTruck/setHistoricDispatches', resp.haul_truck.dispatches.historic],

        // dig unit specific
        ['digUnit/setCurrentActivities', resp.dig_unit.activities.current],
        ['digUnit/setHistoricActivities', resp.dig_unit.activities.historic],
      ].map(([path, data]) => dispatch(path, data));
    },
    onOpenGlobalActions() {
      this.$modal.create(GlobalActionsModal);
    },
  },
};
</script>

<style>
@import './assets/tooltip.css';
@import './assets/toasted.css';
@import './assets/toggle.css';
@import './assets/contextMenu.css';
@import './assets/googleMaps.css';

/* firefox scrollbar color was transparent */
html {
  scrollbar-color: #c1c1c1 #f1f1f1;
}

.wrapper {
  display: flex;
}

.contents-wrapper {
  display: contents;
}

a {
  cursor: pointer;
  color: #007acc;
}

a[href^='#/gap'] {
  pointer-events: none;
  cursor: default;
  display: block;
}

a[href^='#/gap'] div {
  height: 1.5em;
  background-color: #121f26;
}

g.custom-icon {
  stroke-width: 1;
}

.global-action-icon {
  margin-left: 1rem;
  cursor: pointer;
}

.global-action-icon.hx-icon svg {
  stroke-width: 1.3;
}

.global-action-icon:hover {
  opacity: 0.75;
}
</style>
