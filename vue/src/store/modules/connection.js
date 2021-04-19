import { Toaster as ToasterClass } from '@/code/toasts';
const Toaster = new ToasterClass();
const UPDATE_INTERVAL = 5 * 1000;
const LONG_OFFLINE_DURATION = 30 * 1000;
const COMMS_ESTABLISH_MSG = 'Connection established';
const COMMS_LOST_MSG = 'Connection lost';

function getStatus(state) {
  if (state.isAlive && state.isConnected) {
    return 'connected';
  }

  if (state.isAlive && !state.isConnected) {
    const now = new Date();
    const disconnectedAt = state.lastDisconnectedAt;

    if (disconnectedAt && now.getTime() - disconnectedAt.getTime() > LONG_OFFLINE_DURATION) {
      return 'disconnected_long';
    }

    return 'disconnected';
  }

  return null;
}

function toastConnection(newStatus, oldStatus) {
  if (!oldStatus) {
    return;
  }
  switch (newStatus) {
    case 'connected':
      Toaster.clear(toast => toast.type === 'no-comms' && toast.text === COMMS_LOST_MSG);
      Toaster.info(COMMS_ESTABLISH_MSG, { replace: true });
      break;
    case 'disconnected':
      Toaster.clear(toast => toast.type === 'info' && toast.text === COMMS_ESTABLISH_MSG);
      Toaster.noComms(COMMS_LOST_MSG, { replace: true });
      break;
  }
}

/* ------------------ module --------------- */
const state = {
  userToken: String(),
  presence: Array(),
  mode: null,
  isAlive: false,
  isConnected: false,
  lastConnectedAt: null,
  lastDisconnectedAt: null,
  updatedAt: null,
  updateInterval: null,
  messageLog: [],
  status: null,
};

const getters = {};

const actions = {
  attachMonitor({ commit }, channel) {
    console.log('[Connection] Monitoring channel');
    channel.registerMonitor((_type, info) => {
      commit('updateInfo', info);
      commit('updateStatus');
    });
    const interval = setInterval(() => {
      commit('updateStatus');
    }, UPDATE_INTERVAL);
    commit('setInterval', interval);
  },
  setUserToken({ commit }, token) {
    commit('setUserToken', token);
  },
  clearUserToken({ commit }) {
    commit('setUserToken', null);
  },
  setIsConnected({ commit }, bool) {
    commit('setIsConnected', bool);
  },
  setPresence({ commit }, presence) {
    const presenceList = presence.list(id => id);
    commit('setPresence', presenceList);
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
      toastConnection(status, state.status);
      state.status = status;
    }
    state.updatedAt = new Date();
  },
  updateInfo(state, info) {
    state.isAlive = info.isAlive;
    state.isConnected = info.isConnected;
    state.lastConnectedAt = info.lastConnectedAt;
    state.lastDisconnectedAt = info.lastDisconnectedAt;
    state.mode = info.mode;
    state.messageLog = info.log || [];

    state.updatedAt = new Date();
  },
  setUserToken(state, token) {
    state.userToken = token;
  },
  setIsConnected(state, bool) {
    state.isConnected = bool;
  },
  setPresence(state, presence = []) {
    state.presence = presence;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
