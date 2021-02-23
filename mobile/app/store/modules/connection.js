const UPDATE_INTERVAL = 5 * 1000;
const LONG_OFFLINE_DURATION = 30 * 1000;
const SUSPECTED_NETWORK_FAILURE_DURATION = 60 * 1000;

function getStatus(state) {
  if (state.isAlive && state.isConnected) {
    return 'connected';
  }

  if (state.isAlive && !state.isConnected) {
    const now = new Date();
    const disconnectedAt = state.lastDisconnectedAt;

    const disconnectDuration = getDisconnectDuration(disconnectedAt, now);

    if (disconnectDuration > SUSPECTED_NETWORK_FAILURE_DURATION) {
      return 'disconnected_suspected_network_failure';
    }

    if (disconnectDuration > LONG_OFFLINE_DURATION) {
      return 'disconnected_long';
    }

    return 'disconnected';
  }

  if (state.status) {
    return 'disconnected_no_channel';
  }

  return null;
}

function getDisconnectDuration(disconnectedAt, now) {
  if (!disconnectedAt) {
    return 0;
  }

  return now.getTime() - disconnectedAt.getTime();
}

const state = {
  mode: null,
  isAlive: false,
  isConnected: false,
  lastConnectedAt: null,
  lastDisconnectedAt: null,
  updatedAt: null,
  updateInterval: null,
  status: null,
};

const getters = {};

const actions = {
  attachMonitor({ commit }, channel) {
    channel.registerMonitor((status, info) => {
      commit('updateInfo', { status, info });
      commit('updateStatus');
    });
    const interval = setInterval(() => {
      commit('updateStatus');
    }, UPDATE_INTERVAL);
    commit('setInterval', interval);
  },
};

const mutations = {
  setInterval(state, interval) {
    clearInterval(state.updateInterval);
    state.updateInterval = interval;
  },
  updateStatus(state) {
    const status = getStatus(state);
    if (status !== state.status) {
      console.log(`[Connection] Status updated: ${state.status} -> ${status}`);
      state.status = status;
    }
  },
  updateInfo(state, { info }) {
    state.isAlive = info.isAlive;
    state.isConnected = info.isConnected;
    state.lastConnectedAt = info.lastConnectedAt;
    state.lastDisconnectedAt = info.lastDisconnectedAt;
    state.mode = info.mode;

    state.updatedAt = new Date();
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
