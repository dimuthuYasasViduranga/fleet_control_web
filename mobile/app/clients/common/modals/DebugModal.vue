<template>
  <ScrollView class="debug-modal" orientation="vertical">
    <StackLayout class="debug-modal-content">
      <StackLayout v-if="!valid">
        <TextField class="text-field" keyboardType="number" v-model="password" />
      </StackLayout>

      <StackLayout v-else>
        <Label class="text" text="Open Store" />

        <FlexboxLayout width="100%" flexWrap="wrap">
          <Button
            width="50%"
            v-for="(store, index) in stores"
            :key="index"
            :text="store.label || store.name"
            @tap="onOpenStore(store)"
          />
        </FlexboxLayout>

        <!-- mode -->
        <GridLayout columns="* * *">
          <Label
            col="0"
            class="text"
            text="Mode"
            verticalAlignment="center"
            horizontalAlignment="center"
          />
          <Button
            col="1"
            :class="{ selected: restartOnError }"
            text="Restart On Error"
            @tap="setRestartOnError(true)"
          />
          <Button
            col="2"
            :class="{ selected: !restartOnError }"
            text="Crash On Error"
            @tap="setRestartOnError(false)"
          />
        </GridLayout>
        <!-- Exception on logout -->
        <GridLayout columns="* * *">
          <Label
            col="0"
            class="text"
            text="Exception On Logout"
            verticalAlignment="center"
            horizontalAlignment="center"
          />
          <Button
            col="1"
            :class="{ selected: exceptionOnLogout }"
            text="Yes"
            @tap="setExceptionOnLogout(true)"
          />
          <Button
            col="2"
            :class="{ selected: !exceptionOnLogout }"
            text="No"
            @tap="setExceptionOnLogout(false)"
          />
        </GridLayout>
        <!-- Engine hours on login -->
        <GridLayout columns="* * *">
          <Label
            col="0"
            class="text"
            text="Engine Hours on Login"
            verticalAlignment="center"
            horizontalAlignment="center"
          />
          <Button
            col="1"
            :class="{ selected: engineHoursOnLogin }"
            text="Yes"
            @tap="setEngineHoursOnLogin(true)"
          />
          <Button
            col="2"
            :class="{ selected: !engineHoursOnLogin }"
            text="No"
            @tap="setEngineHoursOnLogin(false)"
          />
        </GridLayout>
        <!-- Engine hours on Logout -->
        <GridLayout columns="* * *">
          <Label
            col="0"
            class="text"
            text="Engine Hours on Logout"
            verticalAlignment="center"
            horizontalAlignment="center"
          />
          <Button
            col="1"
            :class="{ selected: engineHoursOnLogout }"
            text="Yes"
            @tap="setEngineHoursOnLogout(true)"
          />
          <Button
            col="2"
            :class="{ selected: !engineHoursOnLogout }"
            text="No"
            @tap="setEngineHoursOnLogout(false)"
          />
        </GridLayout>
        <!-- Location -->
        <GridLayout columns="* * *">
          <Label
            col="0"
            class="text"
            text="Location"
            verticalAlignment="center"
            horizontalAlignment="center"
          />
          <Button
            col="1"
            :class="{ selected: !showLocation }"
            text="Hide"
            @tap="setShowLocation(false)"
          />
          <Button
            col="2"
            :class="{ selected: showLocation }"
            text="Show"
            @tap="setShowLocation(true)"
          />
        </GridLayout>

        <Label v-if="showLocation" class="text" :text="formattedDeviceLocation" :textWrap="true" />

        <!-- battery -->
        <GridLayout columns="* * *">
          <Label
            col="0"
            class="text"
            text="Battery"
            verticalAlignment="center"
            horizontalAlignment="center"
          />
          <Button
            col="1"
            :class="{ selected: !showBattery }"
            text="Hide"
            @tap="setShowBattery(false)"
          />
          <Button
            col="2"
            :class="{ selected: showBattery }"
            text="Show"
            @tap="setShowBattery(true)"
          />
        </GridLayout>

        <Label v-if="showBattery" class="text" :text="formattedBatteryInfo" :textWrap="true" />

        <Button
          class="info-btn btn-show-store-data"
          text="Show Store Data"
          textTransform="Capitalize"
          @tap="toggleShowStoreData()"
        />

        <StackLayout v-show="showStoreData" v-for="(disk, index) in diskKeys" :key="index">
          <GridLayout columns="3*, *, *">
            <Label
              col="0"
              class="text"
              :text="`${disk.label} ${getStoreCount(disk.key)}`"
              verticalAlignment="center"
              horizontalAlignment="center"
            />
            <Button
              col="1"
              :class="{ selected: !disk.show }"
              text="Hide"
              @tap="disk.show = false"
            />
            <Button col="2" :class="{ selected: disk.show }" text="Show" @tap="disk.show = true" />
          </GridLayout>

          <Label
            v-if="disk.show"
            class="text"
            :text="formattedStoreData(disk.key)"
            :textWrap="true"
          />
        </StackLayout>

        <Button
          class="info-btn btn-restart"
          text="Restart"
          textTransform="Capitalize"
          @tap="restart"
        />

        <Button
          class="info-btn btn-crash"
          text="Force Crash"
          textTransform="Capitalize"
          @tap="crash"
        />

        <Button
          class="info-btn btn-clear-cache"
          text="Clear Cache"
          textTransform="Capitalize"
          @tap="clearCache"
        />

        <Button
          class="info-btn btn-clear-offline-data"
          text="Clear Offline Data"
          textTransform="Capitalize"
          @tap="onClearOfflineData"
        />
      </StackLayout>
    </StackLayout>
  </ScrollView>
</template>

<script>
import { mapState } from 'vuex';

import ConfirmModal from './ConfirmModal.vue';
import StoreViewerModal from './StoreViewerModal.vue';

import { formatSeconds } from '../../code/helper';

const DEBUG_PSWD = '0786';

function copy(obj) {
  return JSON.parse(JSON.stringify(obj));
}

function toDate(date) {
  if (!date) {
    return null;
  }
  return new Date(date);
}

function getAge(date, now = Date.now()) {
  if (!date) {
    return null;
  }

  return `${Math.trunc((now - date.getTime()) / 1000)} secs`;
}

export default {
  name: 'DebugModal',
  data: () => {
    const stores = [
      {
        name: null,
        label: 'General',
        ignore: [],
      },
      { name: 'constants', ignore: ['operators'], mask: ['locations', 'clusters'] },
      { name: 'disk', label: 'Store And Forward', mask: ['deviceToken'] },
      { name: 'location', raw: true },
      { name: 'battery', raw: true },
      { name: 'connection', raw: true },
      { name: 'network', raw: true },
      { name: 'haulTruck', label: 'Haul Trucks' },
      { name: 'digUnit', label: 'Dig Units' },
      { name: 'watercart', label: 'Watercarts' },
    ];

    // root store must ignore all children
    const rootIgnore = stores.slice(1).map(s => s.name);
    stores[0].ignore = rootIgnore;

    return {
      password: '',
      restartOnError: global.process.restartOnError,
      deviceLocation: null,
      deviceLocationInterval: null,
      showLocation: false,
      showBattery: false,
      showStoreData: false,
      stores,
      diskKeys: [
        { label: 'Offline Logins', key: 'storedOfflineLogins', show: false },
        { label: 'Logouts', key: 'storedLogouts', show: false },
        { label: 'Allocations', key: 'storedAllocations', show: false },
        { label: 'Operator Messages', key: 'storedMessages', show: false },
        { label: 'Dispatcher Msg Acks', key: 'storedDispatcherMsgAcks', show: false },
        { label: 'Engine Hours', key: 'storedEngineHours', show: false },
        { label: 'Pre-Start Submissions', key: 'storedPreStartSubmissions', show: false },
        { label: 'Haul Truck Dispatches', key: 'storedHaulTruckDispatchAcks', show: false },
        { label: 'Haul Manual Cycles', key: 'storedManualCycles', show: false },
        { label: 'Dig Unit Activites', key: 'storedDigUnitActivities', show: false },
      ],
    };
  },
  computed: {
    ...mapState('disk', {
      storedOfflineLogins: state => state.offlineLogins,
      storedLogouts: state => state.logouts,
      storedAllocations: state => state.allocations,
      storedMessages: state => state.messages,
      storedDispatcherMsgAcks: state => state.dispatcherMsgAcks,
      storedEngineHours: state => state.engineHours,
      storedPreStartSubmissions: state => state.preStartSubmissions,
      storedHaulTruckDispatchAcks: state => state.haulTruckDispatchAcks,
      storedManualCycles: state => state.manualCycles,
      storedDigUnitActivities: state => state.digUnitActivities,
    }),
    ...mapState({
      exceptionOnLogout: state => state.promptExceptionOnLogout,
      engineHoursOnLogin: state => state.promptEngineHoursOnLogin,
      engineHoursOnLogout: state => state.promptEngineHoursOnLogout,
    }),
    valid() {
      return TNS_ENV !== 'production' || this.password === DEBUG_PSWD;
    },
    formattedDeviceLocation() {
      return JSON.stringify(this.deviceLocation, null, 2);
    },
    formattedBatteryInfo() {
      const info = { ...this.$store.getters['battery/info'] };
      const duration = Math.trunc((this.$store.state.battery.wakeLockTimeoutDuration || 0) / 1000);
      info.wakeLockDuration = formatSeconds(duration);
      return JSON.stringify(info, null, 2);
    },
  },
  mounted() {
    this.setDeviceLocationInterval();
  },
  beforeDestroy() {
    this.clearDeviceLocationInterval();
  },
  methods: {
    getStoreCount(key) {
      const list = this[key] || [];
      if (list.length > 0) {
        return ` (${list.length})`;
      }
      return '';
    },
    formattedStoreData(key) {
      return JSON.stringify(this[key] || [], null, 2);
    },
    clearDeviceLocationInterval() {
      clearInterval(this.deviceLocationInterval);
    },
    setDeviceLocationInterval() {
      this.clearDeviceLocationInterval();
      this.deviceLocationInterval = setInterval(() => {
        const location = this.$store.state.location.deviceLocation;
        const deviceLocation = copy(location);

        deviceLocation.timestamp = toDate(location.timestamp);
        deviceLocation.positionAge = getAge(location.timestamp) || '--';

        this.deviceLocation = deviceLocation;
      }, 1000);
    },
    setRestartOnError(bool) {
      global.process.restartOnError = bool;
      this.restartOnError = bool;
    },
    setExceptionOnLogout(bool) {
      this.$store.commit('setPromptExceptionOnLogout', bool);
    },
    setEngineHoursOnLogin(bool) {
      this.$store.commit('setPromptEngineHoursOnLogin', bool);
    },
    setEngineHoursOnLogout(bool) {
      this.$store.commit('setPromptEngineHoursOnLogout', bool);
    },
    setShowLocation(bool) {
      this.showLocation = bool;
    },
    setShowBattery(bool) {
      this.showBattery = bool;
    },
    toggleShowStoreData() {
      this.showStoreData = !this.showStoreData;
    },
    restart() {
      global.process.restart();
    },
    crash() {
      // yes this is meant to fail and crash the program
      // It is used to test the crash handling of the app (auto restart, sending logs etc)
      throw '[crash] This has been a requested crash';
    },
    clearCache() {
      this.$store.commit('disk/clear');
    },
    onClearOfflineData() {
      const confirmName = 'Clear';
      const opts = {
        message: 'Offline mode will be unavailable until next successful connection',
        confirmName,
        rejectName: 'cancel',
      };
      this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
        if (answer === confirmName) {
          this.$store.dispatch('clearAllDiskData');
          this.$toaster.info('Offline Data Cleared').show();
        }
      });
    },
    onOpenStore(store) {
      let state = this.$store.state;

      if (store.name !== 'store') {
        state = state[store.name];
      }

      this.$modalBus.open(StoreViewerModal, {
        name: store.name,
        raw: store.raw,
        ignore: store.ignore,
        mask: store.mask,
      });
    },
  },
};
</script>

<style>
.debug-modal {
  background-color: white;
  height: 80%;
  width: 85%;
}

.debug-modal-content {
  padding: 25 50;
}

.debug-modal .text {
  color: black;
  font-size: 20;
}

.debug-modal .selected {
  background-color: lightslategray;
  color: white;
}

.debug-modal .info-btn {
  height: 50;
  font-size: 20;
}
</style>
