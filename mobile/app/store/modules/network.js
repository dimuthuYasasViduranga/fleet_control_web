const connectivity = require('tns-core-modules/connectivity');

const conType = connectivity.connectionType;
const TYPES = {
  [conType.none]: null,
  [conType.wifi]: 'Wifi',
  [conType.mobile]: 'Cellular',
  [conType.ethernet]: 'Ethernet',
  [conType.bluetooth]: 'Bluetooth',
};

const state = {
  updatedAt: null,
  type: null,
  hasInternet: false,
};

function getStatus() {
  try {
    return connectivity.getConnectionType();
  } catch {
    console.log('[Network] Failed to get connection status');
    return conType.none;
  }
}

const getters = {};

const actions = {
  startMonitor({ commit }) {
    console.log('[Network] Starting monitor');
    commit('setType', getStatus());
    connectivity.startMonitoring(type => commit('setType', type));
  },
  forceUpdate({ commit }) {
    commit('setType', getStatus());
  },
};

const mutations = {
  setType(state, typeCode) {
    state.updatedAt = new Date();
    const oldType = state.type;
    state.type = TYPES[typeCode] || null;
    if (state.type !== oldType) {
      console.log(`[Network] Switched to '${state.type}'`);
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
