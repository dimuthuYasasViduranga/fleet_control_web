import { toUtcDate } from '@/code/time';
import Toaster from '@/code/toaster';
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

function onlineStatusFromPresence(presence) {
  return presence
    .list((id, { metas: [data] }) => {
      return { id, timestamp: data?.online_at };
    })
    .reduce((acc, device) => {
      const epoch = Number(device.timestamp);
      if (isNaN(epoch)) {
        return acc;
      }

      acc[device.id] = toUtcDate(epoch * 1000);
      return acc;
    }, {});
}

function updateDeviceOnlineStatus(oldStatus, newStatus) {
  // if not in new status, set as offline
  const now = Date.now();

  const status = Object.keys(oldStatus).reduce((acc, key) => {
    // if it has been seen before, set to disconnected
    if (oldStatus[key]?.status === 'not_seen') {
      acc[key] = oldStatus[key];
      return acc;
    }
    acc[key] = {
      status: 'disconnected',
      timestamp: new Date(now),
    };
    return acc;
  }, {});

  Object.entries(newStatus).forEach(([key, timestamp]) => {
    status[key] = {
      status: 'connected',
      timestamp,
    };
  });

  return status;
}

/* ------------------ module --------------- */
const state = {
  userToken: String(),
  presence: Array(),
  deviceOnlineStatus: Object(),
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
  setDeviceOnlineStatus({ commit }, data) {
    const deviceOnlineStatus = Object.entries(data).reduce((acc, [uuid, info]) => {
      acc[uuid] = {
        status: info.status,
        timestamp: toUtcDate(info.timestamp),
      };
      return acc;
    }, {});

    commit('setDeviceOnlineStatus', deviceOnlineStatus);
  },
  updatePresence({ commit }, presence) {
    const presenceList = presence.list(id => id);
    const onlineStatus = onlineStatusFromPresence(presence);

    commit('setPresence', presenceList);
    commit('updateDeviceOnlineStatus', onlineStatus);
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
  setDeviceOnlineStatus(state, status = {}) {
    state.deviceOnlineStatus = status;
  },
  updateDeviceOnlineStatus(state, status = {}) {
    state.deviceOnlineStatus = updateDeviceOnlineStatus(state.deviceOnlineStatus, status);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
