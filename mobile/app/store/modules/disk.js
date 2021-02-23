import * as Toaster from '../../clients/code/toaster';

import {
  clearKeys,
  simplePersist,
  persistAndSet,
  retrieve,
  simpleRetrieve,
} from '../persistence.js';

const DISK_KEYS = {
  client: {
    key: 'client',
    diskKey: 'Client',
    default: {},
    parser: parseDiskClient,
    clearable: false,
  },
  deviceToken: { key: 'deviceToken', diskKey: 'Device', default: null, clearable: false },
  offlineLogins: {
    key: 'offlineLogins',
    diskKey: 'Offline Logins',
    default: [],
    sendable: 'sendStoredOfflineLogins',
  },
  logouts: { key: 'logouts', diskKey: 'Logouts', default: [], sendable: 'sendStoredLogouts' },
  allocations: {
    key: 'allocations',
    diskKey: 'Allocations',
    default: [],
    sendable: 'sendStoredAllocations',
  },
  messages: { key: 'messages', diskKey: 'Messages', default: [], sendable: 'sendStoredMessages' },
  dispatcherMsgAcks: {
    key: 'dispatcherMsgAcks',
    diskKey: 'Dispatcher Message Acknowledgements',
    default: [],
    sendable: 'sendStoredDispatcherMsgAcks',
  },
  engineHours: {
    key: 'engineHours',
    diskKey: 'Engine Hours',
    default: [],
    sendable: 'sendStoredEngineHours',
  },
  haulTruckDispatchAcks: {
    key: 'haulTruckDispatchAcks',
    diskKey: 'Acknowledgements',
    default: [],
    sendable: 'sendStoredHaulTruckDispatchAcks',
  },
  manualCycles: {
    key: 'manualCycles',
    diskKey: 'Manual Cycles',
    default: [],
    sendable: 'sendStoredManualCycles',
  },
  digUnitActivities: {
    key: 'digUnitActivities',
    diskKey: 'Dig Unit Activities',
    default: [],
    sendable: 'sendStoredDigUnitActivities',
  },
  preStartSubmissions: {
    key: 'preStartSubmissions',
    diskKey: 'Pre Start Submissions',
    default: [],
    sendable: 'sendStoredPreStartSubmissions',
  },
};

const TRANSIT_TIMEOUT = 20 * 1000;

function appendData(state, config, element, predicate) {
  console.log(`[Disk] Appending on '${config.key}'`);
  const storedData = retrieve(config);
  if (predicate) {
    pushIfUnableToFind(storedData, element, predicate);
  } else {
    storedData.push(element);
  }

  persistAndSet(state, config, storedData);
}

function filterAndPersist(dataName, keepFilter, sent) {
  const stored = simpleRetrieve(dataName, []);
  const unsentData = stored.filter(s => keepFilter(s, sent));
  simplePersist(dataName, unsentData);

  if (sent.length > 0 && unsentData.length === 0) {
    Toaster.info(`All ${dataName} sent`).show();
  }

  return unsentData;
}

function storeKeepFilter(stored, sent = [], fields) {
  // check any sent elements are stored on disk (compare all given fields are equal)
  const storedInSent = sent.findIndex(e => fields.every(f => stored[f] === e[f])) !== -1;
  return !storedInSent;
}

function pushIfUnableToFind(arr, element, findPredicate) {
  if (!arr.find(findPredicate)) {
    arr.push(element);
  }
}

function parseDiskClient(rawClient) {
  const client = rawClient || {};
  return {
    version: client.version,
    changedAt: toDate(client.changedAt),
  };
}

function sortAllocations(allocation) {
  const orderedAllocations = allocation.slice();
  orderedAllocations.sort((a, b) => a.start_time - b.start_time);
  return orderedAllocations;
}

function toDate(date) {
  return date ? new Date(date) : date;
}

/* --------------------------- module ----------------------*/

function addDiskKeys(state, keys) {
  Object.values(keys).forEach(item => {
    state[item.key] = retrieve(item);

    if (item.sendable) {
      state.inTransit[item.key] = false;
    }
  });
}

const state = {
  client: null,
  deviceToken: null,
  inTransit: {},
  offlineLogins: [],
  logouts: [],
  allocations: [],
  messages: [],
  dispatcherMsgAcks: [],
  engineHours: [],
  haulTruckDispatchAcks: [],
  manaulCycles: [],
  digUnitActivities: [],
  preStartSubmissions: [],
};

addDiskKeys(state, DISK_KEYS);

const getters = {};

const actions = {
  setClientVersion({ commit, state }, version) {
    if (!version) {
      console.log('[Disk] No version given');
      commit('setClientVersion', version);

      return;
    }

    if (state.client.version === version) {
      console.log('[Disk] Version unchanged');
      return;
    }

    commit('clear');
    commit('setClientVersion', version);

    // notify about the change
    const msg = `Client updated to ${version}`;
    console.log(`[Disk] ${msg}`);
    Toaster.green(msg, 'long').show();
  },
  sendAll({ dispatch }, channel) {
    Object.values(DISK_KEYS)
      .filter(item => item.sendable)
      .forEach(item => dispatch(item.sendable, channel));
  },
  sendStoredData({ dispatch, commit, state }, { channel, diskConfig, topic, filterKeys, toast }) {
    const diskName = diskConfig.diskKey;
    const stateName = diskConfig.key;
    const storedData = retrieve(diskConfig);
    // check if no point sending or if stored data is already in transit
    if (state.inTransit[stateName]) {
      console.log(`[Disk] Message already in transit for '${diskName}'`);
      return;
    }

    if (storedData.length === 0) {
      console.log(`[Disk] No data to send for '${diskName}'`);
      return;
    }

    // start of transit
    commit('setInTransit', stateName);

    // fallback timer incase anything goes wrong/takes too long
    const fallback = setTimeout(() => {
      commit('clearInTransit', stateName);
    }, TRANSIT_TIMEOUT);

    const onTransitEnd = () => {
      clearTimeout(fallback);
      commit('clearInTransit', stateName);
    };

    channel
      .push(topic, storedData)
      .receive('ok', () => {
        Toaster.info(toast).show();
        const filter = (stored, sent) => storeKeepFilter(stored, sent, filterKeys);
        const persistedData = filterAndPersist(diskName, filter, storedData);
        commit('setStoredData', { stateName, data: persistedData });
        onTransitEnd();
        // If data was push to disk during transit, send again
        if (retrieve(diskConfig) !== []) {
          console.log(`[Disk] Data in store '${diskName}' exists. Sending again `);
          dispatch('sendStoredData', { channel, diskConfig, topic, filter, toast });
        }
      })
      .receive('error', onTransitEnd)
      .receive('timeout', onTransitEnd);
  },
  sendStoredMessages({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.messages,
      topic: 'submit messages',
      filterKeys: ['id', 'timestamp'],
      toast: 'All messages sent',
    });
  },
  sendStoredAllocations({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.allocations,
      topic: 'submit allocations',
      filterKeys: ['id', 'start_time', 'end_time'],
      toast: 'All allocations sent',
    });
  },
  sendStoredDispatcherMsgAcks({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.dispatcherMsgAcks,
      topic: 'submit dispatcher message acknowledgements',
      filterKeys: ['id', 'timestamp'],
      toast: 'All dispatcher message acknowledgements sent',
    });
  },
  sendStoredEngineHours({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.engineHours,
      topic: 'submit engine hours',
      filterKeys: ['id', 'timestamp', 'hours'],
      toast: 'All engine hours sent',
    });
  },
  sendStoredOfflineLogins({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.offlineLogins,
      topic: 'submit offline logins',
      filterKeys: ['timestamp', 'asset_id'],
      toast: 'All offline logins sent',
    });
  },
  sendStoredLogouts({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.logouts,
      topic: 'submit logouts',
      filterKeys: ['timestamp', 'asset_id'],
      toast: 'All logouts sent',
    });
  },
  sendStoredPreStartSubmissions({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.preStartSubmissions,
      topic: 'submit pre-start submissions',
      filterKeys: ['asset_id', 'operator_id', 'timestamp'],
      toast: 'All Pre-Starts sent',
    });
  },
  // haul truck
  sendStoredHaulTruckDispatchAcks({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.haulTruckDispatchAcks,
      topic: 'haul:acknowledge dispatches',
      filterKeys: ['timestamp'],
      toast: 'All dispatch acknowledgements sent',
    });
  },
  sendStoredManualCycles({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.manualCycles,
      topic: 'haul:submit manual cycles',
      filterKeys: ['asset_id', 'operator_id', 'start_time'],
      toast: 'All manual cycles sent',
    });
  },
  // dig unit
  sendStoredDigUnitActivities({ dispatch }, channel) {
    dispatch('sendStoredData', {
      channel,
      diskConfig: DISK_KEYS.digUnitActivities,
      topic: 'dig:submit activities',
      filterKeys: ['timestamp'],
      toast: 'All activities sent',
    });
  },
};

const mutations = {
  setClientVersion(state, version) {
    const now = new Date();
    simplePersist(DISK_KEYS.client.diskKey, { version, changedAt: now.getTime() });
    state.client.version = version;
    state.client.changedAt = now;
  },
  saveDeviceToken(state, token) {
    console.log('[Disk] saving device token');
    persistAndSet(state, DISK_KEYS.deviceToken, token);
  },
  clearDeviceToken(state) {
    console.log('[Disk] clearing device token');
    persistAndSet(state, DISK_KEYS.deviceToken, null);
  },
  setInTransit(state, stateName) {
    state.inTransit[stateName] = true;
  },
  clearInTransit(state, stateName) {
    state.inTransit[stateName] = false;
  },
  setStoredData(state, { stateName, data }) {
    state[stateName] = data;
  },
  // operator messages
  storeMessage(state, message) {
    appendData(state, DISK_KEYS.messages, message);
  },
  storeAllocation(state, allocation) {
    if (!allocation) {
      return;
    }
    const config = DISK_KEYS.allocations;
    const storedAllocs = retrieve(config);
    const latestAlloc = storedAllocs[storedAllocs.length - 1];

    // if the latest allocation was ended offline
    if (latestAlloc && latestAlloc.start_time === allocation.start_time) {
      latestAlloc.end_time = allocation.end_time;
      persistAndSet(state, config, sortAllocations(storedAllocs));

      return;
    }

    // if a new allocation, end an outstanding one
    if (latestAlloc && !latestAlloc.end_time) {
      latestAlloc.end_time = allocation.start_time;
    }

    storedAllocs.push(allocation);
    persistAndSet(state, config, sortAllocations(storedAllocs));
  },
  // dispatcher message acknowledgements
  storeDispatcherMsgAck(state, dispatcherMsgAck) {
    appendData(
      state,
      DISK_KEYS.dispatcherMsgAcks,
      dispatcherMsgAck,
      da => da.id === dispatcherMsgAck.id,
    );
  },
  storeEngineHours(state, engineHours) {
    appendData(state, DISK_KEYS.engineHours, engineHours);
  },
  storePreStartSubmission(state, submission) {
    appendData(state, DISK_KEYS.preStartSubmissions, submission);
  },
  storeOfflineLogin(state, login) {
    if (login.asset_id) {
      appendData(state, DISK_KEYS.offlineLogins, login);
    }
  },
  storeLogout(state, logout) {
    if (logout.asset_id) {
      appendData(state, DISK_KEYS.logouts, logout);
    }
  },
  // haul truck info
  storeHaulTruckDispatchAcks(state, acknowledgement) {
    appendData(
      state,
      DISK_KEYS.haulTruckDispatchAcks,
      acknowledgement,
      sa => sa.id === acknowledgement.id,
    );
  },
  storeManualCycle(state, cycle) {
    appendData(state, DISK_KEYS.manualCycles, cycle);
  },
  // dig unit
  storeDigUnitActivity(state, activity) {
    appendData(state, DISK_KEYS.digUnitActivities, activity);
  },
  clear(state) {
    console.error('[Disk] Clearing all stored data');
    clearKeys(state, Object.values(DISK_KEYS));
    Toaster.info('Stored Data Cleared').show();
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
