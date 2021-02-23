<template>
  <Page :actionBarHidden="true">
    <GridLayout>
      <StackLayout>
        <DispatcherModalManager />

        <Frame id="hx-frame">
          <!-- stack layout wrapper needed to prevent orphaning in frame -->
          <StackLayout>
            <Login
              v-if="!isLoggedIn"
              :site="site"
              :employeeId="employeeId"
              :deviceToken="deviceToken"
              :error="loginError"
              @employeeIdChange="onEmployeeIdChange"
              @login="onAdaptiveLogin()"
              @offlinePreStart="onOfflinePreStart()"
            />
            <StackLayout v-else>
              <Clients
                :isLoggedIn="isLoggedIn"
                :connectionStatus="connectionStatus"
                :operator="operator"
                :asset="asset"
                @mounted="onClientMounted()"
                @login="onForgroundLogin()"
                @confirmLogout="onConfirmLogout()"
              />
            </StackLayout>
          </StackLayout>
        </Frame>
      </StackLayout>
      <ModalOverlayManager />
    </GridLayout>
  </Page>
</template>

<script>
import { mapState } from 'vuex';

import * as application from 'tns-core-modules/application';
const platformModule = require('tns-core-modules/platform');

import DispatcherModalManager from './common/modals/DispatcherModalManager.vue';
import Login from './common/pages/login/Login.vue';
import Clients from './Clients.vue';

import ModalOverlayManager from './common/modals/ModalOverlayManager.vue';
import ConfirmModal from './common/modals/ConfirmModal.vue';
import ConnectModal from './common/modals/ConnectModal.vue';
import EngineHoursModal from './common/modals/EngineHoursModal.vue';
import AllocationSelectModal from './common/modals/AllocationSelectModal.vue';
import PreStartSelectionModal from './common/modals/PreStartSelectionModal.vue';
import { attributeFromList } from './code/helper';

const { LoginLooper } = require('./common/pages/login/login.js');
const { Spinner } = require('./code/spinner.js');

const SUCCESSFUL_LOGOUT_RESPONSE_LIMIT = 5000;
const SPINNER_CLOSE_DELAY = 1000;
const CLEAR_ID_TIMEOUT_MS = 3 * 1000;
const MAX_HARD_CONNECT_ATTEMPTS = 1000;
const LOGOUT_AFTER_EXCEPTION_WINDOW = 20 * 1000;
const CLIENT_VERSION_TIMEOUT = 1 * 1000;

export default {
  components: {
    DispatcherModalManager,
    Clients,
    Login,
    ModalOverlayManager,
  },
  data: () => {
    return {
      spinner: new Spinner('Fetching Asset Information'),
      employeeId: null,
      employeeIdTimeout: null,
      operatorToken: null,
      logoutExceptionBefore: null,
      loginError: '',
      operator: null,
    };
  },
  computed: {
    ...mapState({
      deviceId: state => state.deviceId,
      asset: state => state.asset,
      deviceToken: state => state.disk.deviceToken,
      connectionStatus: state => state.connection.status,
    }),
    ...mapState('constants', {
      operators: state => state.operators,
      assets: state => state.assets,
      preStarts: state => state.preStarts,
    }),
    site() {
      return this.$site;
    },
    loginLooper() {
      return new LoginLooper(this.$hostname);
    },
    deviceUUID() {
      return platformModule.device.uuid;
    },
    isLoggedIn() {
      return !!this.operator;
    },
    allocationIsReady() {
      const alloc = this.$store.state.allocation;
      if (!alloc) {
        return false;
      }

      const fullTimeCodes = this.$store.getters['constants/fullTimeCodes'];
      return attributeFromList(fullTimeCodes, 'id', alloc.timeCodeId, 'isReady') || false;
    },
  },
  watch: {
    connectionStatus(status) {
      if (status === 'disconnected_suspected_network_failure') {
        console.log('[Hard Reconnect] Suspected network failure, trying background connect');
        this.backgroundConnect({ type: 'hard_reconnect', maxAttempts: MAX_HARD_CONNECT_ATTEMPTS });
      }
      if (status === 'connected') {
        this.hideLoading(2500);
      }
    },
  },
  mounted() {
    // overide back button
    application.android.on(application.AndroidApplication.activityBackPressedEvent, args => {
      args.cancel = true;
    });

    // capture suspend
    application.on(application.suspendEvent, () => this.onLogout());
    application.on(application.exitEvent, () => this.onLogout());

    // listen for a shutdown event and logout if possible
    application.android.registerBroadcastReceiver(android.content.Intent.ACTION_SHUTDOWN, () => {
      console.error('[Shutdown] logging out');
      this.logout();
    });

    // register channel to monitor within the store (separates concerns better)
    this.$store.dispatch('connection/attachMonitor', this.$channel);

    // this is given some time before calling to ensure that it shows up in debug logs
    setTimeout(() => {
      this.$store.dispatch('disk/setClientVersion', this.$clientVersion);
    }, CLIENT_VERSION_TIMEOUT);
  },
  methods: {
    setOperator(operator) {
      if (!operator) {
        return;
      }
      console.log(`[App] Operator set to '${operator.id}'`);
      this.operator = operator;
    },
    clearOperator() {
      console.log('[App] Operator cleared');
      this.operator = null;
    },
    onEmployeeIdChange(employeeId) {
      this.employeeId = employeeId;
      this.clearEmployeeTimeout();
    },
    onClientMounted() {
      console.log('[App] Client mounted');
      this.hideLoading(5000);
    },
    onOfflinePreStart() {
      const opts = {
        employeeId: this.employeeId,
        assetId: (this.asset || {}).id,
        assets: this.assets,
        operators: this.operators,
        preStarts: this.preStarts,
      };

      this.$modalBus.open(PreStartSelectionModal, opts);
    },
    onAdaptiveLogin() {
      // always try to login offline first, if it fails, login in the forground
      this.onOfflineLogin() || this.onForgroundLogin();
    },
    onForgroundLogin() {
      this.clearEmployeeTimeout();

      const opts = {
        employeeId: this.employeeId,
        maxAttempts: 30,
        heading: 'Awaiting Comms',
        subTitle: 'Logging In',
      };

      this.$modalBus.open(ConnectModal, opts).onClose(response => {
        const resp = response || {};
        if (resp.token) {
          this.afterLogin(resp, 'new');
          this.clearLoginError();
        } else {
          this.clearOperator();
          this.setLoginError(resp.error);
        }
      });
    },
    afterLogin({ token }, connectionType) {
      this.operatorToken = token;
      this.createChannel(connectionType);
    },
    onOfflineLogin() {
      this.clearEmployeeTimeout();
      this.clearLoginError();
      const employeeId = this.employeeId;

      if (!employeeId) {
        this.setLoginError('Please enter valid employee Id');
        return false;
      }

      const operator = this.operators.find(o => o.employeeId === employeeId);

      if (!operator) {
        this.setLoginError('No operator found for offline use');
        return false;
      }

      this.showLoading();

      // this give some time before child components are loaded (very heavy)
      setTimeout(() => {
        if (!this.operator) {
          this.operator = operator;
        }
      }, 3000);

      this.backgroundConnect({ type: 'new', maxAttempts: Infinity });

      return true;
    },
    onConfirmLogout(actions = {}) {
      if (actions.skip) {
        console.log('[Confirm Logout] Skipping prompts');
        this.onLogout();
        return;
      }

      const promptExceptionOnLogout = this.$store.state.promptExceptionOnLogout;
      if (promptExceptionOnLogout && this.allocationIsReady) {
        const confirmName = 'Enter delay';
        const opts = {
          message: 'Pleae enter a delay before logging out',
          confirmName,
          rejectName: 'cancel',
        };

        this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
          if (answer === confirmName) {
            this.onEnterDelay();
          }
        });

        return;
      }

      const confirmName = 'Yes';
      const opts = {
        message: 'Are you sure you want to logout?',
        confirmName,
        rejectName: 'No',
      };
      this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
        if (answer === confirmName) {
          this.onLogout();
        }
      });
    },
    onEnterDelay() {
      const opts = {
        asset: this.asset,
        group: 'Standby',
        groups: ['Process', 'Standby', 'Down'],
      };

      this.$modalBus.open(AllocationSelectModal, opts).onClose(response => {
        if (!response) {
          return;
        }

        const allocation = {
          assetId: this.asset.id,
          timeCodeId: response.timeCodeId,
          startTime: Date.now(),
          endTime: null,
        };

        this.$store
          .dispatch('submitAllocation', { allocation, channel: this.$channel })
          .then(() => this.onLogout());
      });
    },
    onLogout(opts) {
      this.clearLoginError();
      this.loginLooper.cancel();
      this.$modalBus.closeAll();

      if (!this.operator) {
        console.log('[Logout] No operator logged in, skipping logout request');
        return;
      }

      console.log(`[Logout] Logging out operator '${this.operator.id}' `);
      this.clearOperator();

      const assetId = (this.asset || {}).id;
      const logoutEvent = {
        asset_id: assetId || null,
        timestamp: Date.now(),
      };

      this.showLoading('Logging Out');

      new Promise((resolve, reject) => {
        this.$channel
          .push('logout', {})
          .receive('ok', () => resolve())
          .receive('error', () => reject())
          .receive('timeout', () => reject());
        setTimeout(() => reject(), SUCCESSFUL_LOGOUT_RESPONSE_LIMIT);
      })
        .catch(() => {
          console.error('[Logout] stored');
          this.$toaster.info('Logout stored').show();
          this.$store.commit('disk/storeLogout', logoutEvent);
        })
        .finally(() => this.afterLogout(opts));
    },
    afterLogout(opts = {}) {
      this.operatorToken = null;
      this.$channel.destroy();
      this.hideLoading();

      if (this.employeeId) {
        this.setEmployeeTimeout();
      }

      if (opts.revoke === true) {
        console.error('[Logout] Revoking device token');
        this.$store.commit('clearDeviceToken');
        this.$store.dispatch('clearAllDiskData');
      }

      if (opts.rejoin === true) {
        this.$toaster.info('Auto re-join').show();
        setTimeout(() => this.onForgroundLogin(), 1000);
      }
    },
    setLoginError(error) {
      this.loginError = error;
    },
    clearLoginError() {
      this.loginError = '';
    },
    showLoading(msg) {
      this.spinner.show(msg);
    },
    hideLoading(timeout = 0) {
      setTimeout(() => {
        this.spinner.hide();
      }, timeout);
    },
    setEmployeeTimeout() {
      this.clearEmployeeTimeout();
      this.employeeIdTimeout = setTimeout(() => {
        this.employeeId = null;
      }, CLEAR_ID_TIMEOUT_MS);
    },
    clearEmployeeTimeout() {
      clearTimeout(this.employeeIdTimeout);
    },
    createChannel(connectType) {
      this.showLoading();

      const channel = this.$channel;

      channel.create(
        this.$hostname,
        'operator-socket',
        'operators',
        this.deviceUUID,
        this.operatorToken,
        connectType,
      );

      const dispatch = this.$store.dispatch;

      channel.setOns([
        //special calls
        ['force logout', this.forceLogout],

        // semi-constants
        [
          'set time code tree elements',
          resp => dispatch('constants/setTimeCodeTreeElements', resp.time_code_tree_elements),
        ],
        [
          'set time code data',
          resp => {
            const assetTypeId = (this.$store.state.asset || {}).typeId;
            const treeElements = resp.time_code_tree_elements.filter(
              tct => tct.asset_type_id === assetTypeId,
            );

            dispatch('constants/setTimeCodeTreeElements', treeElements);
            dispatch('constants/setTimeCodes', resp.time_codes);
            dispatch('constants/setTimeCodeGroups', resp.time_code_groups);
          },
        ],
        ['set location data', resp => dispatch('constants/setLocations', resp.locations)],
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

        ['set clusters', resp => dispatch('constants/setClusters', resp.clusters)],
        ['set operators', resp => dispatch('constants/setOperators', resp.operators)],
        ['set asset radios', resp => dispatch('constants/setAssetRadios', resp.asset_radios)],
        ['set pre-starts', resp => dispatch('constants/setPreStarts', resp.pre_starts)],

        // active data
        ['set dispatcher messages', resp => dispatch('setDispatcherMessages', resp.messages)],
        ['set unread messages', resp => dispatch('setUnreadOperatorMessages', resp.messages)],
        ['set allocation', resp => dispatch('setAllocation', resp.allocation)],
        ['set device assignments', resp => dispatch('setDeviceAssignments', resp.assignments)],
        ['set engine hours', resp => dispatch('setEngineHours', resp.engine_hours)],

        // dig unit activities are useful to all asset types
        ['dig:set activities', resp => dispatch('setDigUnitActivities', resp.activities)],

        // asset location
        ['set track', resp => dispatch('location/setServerLocation', resp.track)],
        ['other track', resp => dispatch('location/addOtherLocation', resp.track)],

        // haul trucks
        ['haul:set dispatch', resp => dispatch('haulTruck/setDispatch', resp.dispatch)],
        ['haul:set manual cycles', resp => dispatch('haulTruck/setManualCycles', resp.cycles)],

        // dig units
        ['dig:set activity', resp => dispatch('digUnit/setActivity', resp.activity)],
        ['dig:set dispatches', resp => dispatch('digUnit/setHaulDispatches', resp.dispatches)],

        // water carts
        [
          'watercart:set dispatches',
          resp => dispatch('watercart/setHaulDispatches', resp.dispatches),
        ],
      ]);

      channel.setOnConnect(state => this.onConnect(state));
      channel.setOnError(() => this.onDisconnect());
      channel.setOnClose(() => this.onDisconnect());
    },
    clearState() {
      this.setState({});
    },
    setState(state = {}) {
      if (state.logout) {
        this.$toaster.info('You have been logged out', 'long').show();
        this.onLogout();
        return;
      }
      const dispatch = this.$store.dispatch;
      const common = state.common || {};

      const setup = [
        // semi-constants
        ['constants/setAssets', common.assets],
        ['constants/setAssetTypes', common.asset_types],
        ['constants/setOperators', common.operators],
        ['constants/setLocations', common.locations],
        ['constants/setTimeCodes', common.time_codes],
        ['constants/setTimeCodeGroups', common.time_code_groups],
        ['constants/setTimeCodeTreeElements', common.time_code_tree_elements],
        ['constants/setOperatorMessageTypes', common.operator_message_types],
        ['constants/setOperatorMessageTypeTree', common.operator_message_type_tree],
        ['constants/setClusters', common.clusters],
        ['constants/setMaterialTypes', common.material_types],
        ['constants/setLoadStyles', common.load_styles],
        ['constants/setAssetRadios', common.asset_radios],
        ['constants/setPreStarts', common.pre_starts],

        // active information
        ['setDeviceId', common.device_id],
        ['setAsset', common.asset],
        ['setDispatcherMessages', common.dispatcher_messages],
        ['setUnreadOperatorMessages', common.unread_operator_messages],
        ['setEngineHours', common.engine_hours],
        ['setAllocation', common.allocation],
        ['setDeviceAssignments', common.device_assignments],
        ['setDigUnitActivities', common.dig_unit_activities],

        // location (track)
        ['location/setServerLocation', common.track],
        ['location/setOtherLocations', common.other_tracks],
      ];

      setup.forEach(([store, data]) => dispatch(store, data));

      // set specific asset type state
      dispatch('haulTruck/setState', state['Haul Truck']);
      dispatch('digUnit/setState', state['Dig Unit']);
      dispatch('watercart/setState', state['Watercart']);
    },
    onConnect(state) {
      this.setOperator(state.common.operator);
      this.setState(state);
      this.$store.dispatch('disk/sendAll', this.$channel);
    },
    onDisconnect(state) {
      this.hideLoading();
    },
    forceLogout(opts) {
      this.$toaster.info('You have been logged out remotely', 'long').show();
      this.onLogout(opts);
    },
    backgroundConnect(opts = {}) {
      console.log('[BH Connect] starting');
      const options = {
        maxAttempts: opts.maxAttempts || 30,
        type: opts.type || 'new',
      };

      this.$channel.destroy();

      const payload = {
        device_uuid: this.deviceUUID,
        device_token: this.deviceToken,
        employee_id: this.employeeId,
      };

      this.loginLooper
        .connect(payload, { maxAttempts: options.maxAttempts })
        .then(resp => {
          if (resp.token) {
            console.log('[BG Connect] success');
            this.afterLogin(resp, opts.type);
            this.$toaster.info('Connection successful').show();
          } else {
            console.error('[BG Connect] failure');
            this.setLoginError(resp.error);
            this.$toaster.red('Connection attempt denied. Logging out ...', 'long').show();
            this.onLogout();
          }
        })
        .catch(error => {
          if (error.cancelled) {
            console.log('[BG Connect] Cancelled');
            return;
          }
          console.error(`[BG Connect] ${error}`);
          this.$toaster.red('Suspected network failure. Logging out ...', 'long').show();
          this.onLogout();
        });
    },
  },
};
</script>

<style>
</style>
