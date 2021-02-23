import { allowSleep, disableSleep } from '../../clients/code/wake_lock';

const power = require('nativescript-powerinfo');
const BM = android.os.BatteryManager;
const DEFAULT_WAKE_LOCK_TIMEOUT_DURATION = 30 * 60 * 1000;

const CHARGING_MODE = {
  [BM.BATTERY_PLUGGED_AC]: 'AC',
  [BM.BATTERY_PLUGGED_USB]: 'USB',
  [BM.BATTERY_PLUGGED_WIRELESS]: 'Wireless',
};

const HEALTH = {
  [BM.BATTERY_HEALTH_COLD]: 'Cold',
  [BM.BATTERY_HEALTH_DEAD]: 'Dead',
  [BM.BATTERY_HEALTH_GOOD]: 'Good',
  [BM.BATTERY_HEALTH_OVERHEAT]: 'Overheat',
  [BM.BATTERY_HEALTH_OVER_VOLTAGE]: 'Over Voltage',
  [BM.BATTERY_HEALTH_UNKNOWN]: 'Unknown',
  [BM.BATTERY_HEALTH_UNSPECIFIED_FAILURE]: 'Unspecified Failure',
};

const STATUS = {
  [BM.BATTERY_STATUS_CHARGING]: 'Charging',
  [BM.BATTERY_STATUS_DISCHARGING]: 'Discharging',
  [BM.BATTERY_STATUS_FULL]: 'Full',
  [BM.BATTERY_STATUS_NOT_CHARGING]: 'Not Charging',
  [BM.BATTERY_STATUS_UNKNOWN]: 'Unknown',
};

function getIsCharging(status) {
  return [BM.BATTERY_STATUS_CHARGING, BM.BATTERY_STATUS_FULL].includes(status);
}

const state = {
  percent: 0,
  health: null,
  status: null,
  chargingMode: null,
  isCharging: false,
  scale: 100,
  temperature: null,
  voltage: null,
  updatedAt: null,
  wakeLockTimeout: null,
  wakeLockTimeoutDuration: DEFAULT_WAKE_LOCK_TIMEOUT_DURATION,
};

const getters = {
  info: state => {
    return {
      percent: state.percent,
      health: state.health,
      status: state.status,
      chargingMode: state.chargingMode,
      isCharging: state.isCharging,
      scale: state.scale,
      temperature: state.temperature,
      voltage: state.voltage,
      updatedAt: state.updatedAt,
    };
  },
};

const actions = {
  startMonitor({ commit }, duration = DEFAULT_WAKE_LOCK_TIMEOUT_DURATION) {
    console.log('[Battery] Starting monitor');
    commit('setDuration', duration);
    power.startPowerUpdates(info => {
      commit('setInfo', info);
    });
  },
};

const mutations = {
  setDuration(state, duration) {
    state.wakeLockTimeoutDuration = duration || 0;
    console.log(`[Battery] Duration set to '${duration}' ms`);
  },
  setInfo(state, info) {
    if (!info) {
      return;
    }

    try {
      state.percent = parseInt(info.percent, 10);
      state.health = HEALTH[info.health] || null;
      state.status = STATUS[info.status] || null;
      state.chargingMode = CHARGING_MODE[info.plugged] || null;
      state.isCharging = getIsCharging(info.status);
      state.scale = info.scale;
      state.temperature = info.temperature / 10;
      state.voltage = info.voltage / 1000;
      state.updatedAt = new Date();

      if (state.isCharging && state.wakeLockTimeout) {
        disableSleep();
        state.wakeLockTimeout = clearTimeout(state.wakeLockTimeout);
      } else if (!state.isCharging && !state.wakeLockTimeout) {
        state.wakeLockTimeout = setTimeout(() => {
          allowSleep();
        }, state.wakeLockTimeoutDuration);
      }
    } catch {
      console.error('[Battery] Failed to set info');
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
