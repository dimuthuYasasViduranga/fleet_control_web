import Vue from 'nativescript-vue';
import Vuex from 'vuex';

import { persistAndSet, clearKeys, addDiskKeys } from './persistence.js';

import disk from './modules/disk.js';
import constants, { parseAsset } from './modules/constants.js';
import location from './modules/location.js';
import battery from './modules/battery.js';
import connection from './modules/connection.js';
import network from './modules/network.js';
import haulTruck from './modules/haul_truck.js';
import digUnit from './modules/dig_unit.js';
import watercart from './modules/watercart.js';

import { toUtcDate, sortInPlaceByTime } from '../clients/code/helper';
import { parseActivity } from './modules/dig_unit.js';

Vue.use(Vuex);
const useDebug = process.env.NODE_ENV !== 'production';
const REQUIRED_ENGINE_HOURS_PERIOD = 24 * 3600 * 1000;

const DISK_KEYS = {
  deviceId: { key: 'deviceId', diskKey: 'S:Device Id', default: null },
  asset: { key: 'asset', diskKey: 'S:Asset', default: null },
  engineHours: {
    key: 'engineHours',
    diskKey: 'S:Engine Hours',
    default: null,
    parser: parseDiskEngineHours,
  },
  allocation: {
    key: 'allocation',
    diskKey: 'S:Allocation',
    default: null,
    parser: parseDiskAllocation,
  },
};

function parseDiskEngineHours(data) {
  if (!data) {
    return null;
  }

  return {
    id: data.id,
    assetId: data.assetId,
    hours: data.hours,
    operatorId: data.operatorId,
    timestamp: toUtcDate(data.timestamp),
    deleted: data.deleted,
  };
}

function parseDiskAllocation(data) {
  if (!data) {
    return null;
  }

  return {
    id: data.id,
    assetId: data.assetId,
    timeCodeId: data.timeCodeId,
    startTime: toUtcDate(data.startTime),
    endTime: toUtcDate(data.endTime),
    deleted: data.deleted,
    // this sent part could be funky
    sent: data.sent,
  };
}

function parseUnreadOperatorMessage(message) {
  return {
    id: message.id,
    typeId: message.type_id,
    timestamp: toUtcDate(message.timestamp),
  };
}

function parseAllocation(alloc) {
  if (!alloc) {
    return undefined;
  }

  return {
    id: alloc.id,
    assetId: alloc.asset_id,
    timeCodeId: alloc.time_code_id,
    startTime: toUtcDate(alloc.start_time),
    endTime: toUtcDate(alloc.end_time),
    deleted: alloc.deleted || false,
    sent: false,
  };
}

function parseEngineHours(engineHours) {
  if (!engineHours) {
    return undefined;
  }

  return {
    id: engineHours.id,
    assetId: engineHours.asset_id,
    hours: engineHours.hours,
    operatorId: engineHours.operator_id,
    timestamp: toUtcDate(engineHours.timestamp),
    deleted: engineHours.deleted || false,
  };
}

function parseDispatcherMessage(message) {
  return {
    id: message.id,
    assetId: message.asset_id,
    message: message.message,
    answers: message.answers || [],
    answer: message.answer,
    acknowledgeId: message.acknowledge_id,
    acknowledged: !!message.acknowledge_id,
    timestamp: toUtcDate(message.timestamp),
  };
}

function parseDeviceAssignment(assign) {
  return {
    id: assign.id,
    assetId: assign.asset_id,
    deviceId: assign.devie_id,
    operatorId: assign.operator_id,
    timestamp: toUtcDate(assign.timestamp),
    serverTimestamp: toUtcDate(assign.server_timestamp),
  };
}

/* -------------------- module ------------------ */
const state = {
  deviceId: null,
  asset: null,
  dispatcherMessages: Array(),
  deviceAssignments: Array(),
  digUnitActivities: Array(),
  unreadOperatorMessages: Array(),
  engineHours: null,
  allocation: null,
  engineHoursOld: false,
  engineHoursOldTimeout: null,
  promptExceptionOnLogout: false,
  promptEngineHoursOnLogin: false,
  promptEngineHoursOnLogout: false,
  displayedMessage: null,
};

addDiskKeys(state, DISK_KEYS);

const getters = {};

const actions = {
  clearAllDiskData({ commit }) {
    console.log('[Store] Clearing all disk data');
    commit('clear');
    commit('disk/clear');
    commit('constants/clear');
    commit('haulTruck/clear');
    commit('digUnit/clear');
    commit('watercart/clear');
  },
  setEngineHours({ commit }, engineHours) {
    const formattedEngineHours = parseEngineHours(engineHours);
    commit('setEngineHours', formattedEngineHours);

    commit('clearEngineHoursTimeout');
    if (formattedEngineHours && formattedEngineHours.timestamp) {
      const untilRequired =
        REQUIRED_ENGINE_HOURS_PERIOD - (Date.now() - formattedEngineHours.timestamp);

      commit('setEngineHoursOld', false);

      const timeout = setTimeout(() => {
        commit('setEngineHoursOld', true);
      }, untilRequired);
      commit('setEngineHoursOldTimeout', timeout);
    }
  },
  setAllocation({ commit }, allocation) {
    const formattedAllocation = parseAllocation(allocation);
    commit('setAllocation', formattedAllocation);
  },
  setUnreadOperatorMessages({ commit }, messages = []) {
    const formattedMessages = messages.map(parseUnreadOperatorMessage);
    commit('setUnreadOperatorMessages', formattedMessages);
  },
  setAsset({ commit }, asset) {
    const formattedAsset = parseAsset(asset);
    commit('setAsset', formattedAsset);
  },
  setDeviceId({ commit }, deviceId) {
    commit('setDeviceId', deviceId);
  },
  setDispatcherMessages({ commit }, messages = []) {
    const formattedMessages = messages.map(parseDispatcherMessage);
    commit('setDispatcherMessages', formattedMessages);
  },
  setDeviceAssignments({ commit }, assignments = []) {
    const formattedAssignments = assignments.map(parseDeviceAssignment);
    commit('setDeviceAssignments', formattedAssignments);
  },
  setDigUnitActivities({ commit }, activities = []) {
    const formattedActivities = activities.map(parseActivity);
    commit('setDigUnitActivities', formattedActivities);
  },
  // submits
  submitAllocation({ dispatch, commit, state }, { allocation, channel }) {
    const activeAlloc = state.allocation;

    let endedAlloc = undefined;
    if (activeAlloc) {
      endedAlloc = {
        id: activeAlloc.id,
        asset_id: activeAlloc.assetId,
        time_code_id: activeAlloc.timeCodeId,
        start_time: activeAlloc.startTime,
        end_time: allocation.startTime,
        deleted: false,
      };
    }

    const newAlloc = {
      id: allocation.id,
      asset_id: allocation.assetId,
      time_code_id: allocation.timeCodeId,
      start_time: allocation.startTime,
      end_time: allocation.endTime,
      deleted: false,
    };

    // set local copy (better ui experience)
    dispatch('setAllocation', newAlloc);

    // commit changes to disk
    commit('disk/storeAllocation', endedAlloc);
    commit('disk/storeAllocation', newAlloc);

    // submit the disk
    dispatch('disk/sendStoredAllocations', channel);
  },
  submitEngineHours({ dispatch, commit }, { engineHours, channel }) {
    const payload = {
      asset_id: engineHours.assetId,
      operator_id: engineHours.operatorId,
      hours: engineHours.hours,
      timestamp: engineHours.timestamp,
      deleted: false,
    };

    dispatch('setEngineHours', payload);

    commit('disk/storeEngineHours', payload);

    dispatch('disk/sendStoredEngineHours', channel);
  },
  submitMessage({ dispatch, commit }, { message, channel }) {
    const payload = {
      device_id: message.deviceId,
      asset_id: message.assetId,
      operator_id: message.operatorId,
      type_id: message.typeId,
      timestamp: message.timestamp,
    };

    commit('disk/storeMessage', payload);

    dispatch('disk/sendStoredMessages', channel);
  },
  submitPreStartSubmission({ dispatch, commit }, { submission, channel }) {
    const payload = {
      form_id: submission.formId,
      asset_id: submission.assetId,
      operator_id: submission.operatorId,
      employee_id: submission.employeeId,
      comment: submission.comment,
      timestamp: submission.timestamp,
      responses: submission.responses.map(r => {
        return {
          control_id: r.controlId,
          answer: r.answer,
          comment: r.comment,
        };
      }),
    };

    commit('disk/storePreStartSubmission', payload);

    dispatch('disk/sendStoredPreStartSubmissions', channel);
  },
  submitDispatcherMessageAck({ dispatch, commit }, { acknowledgement, channel }) {
    const payload = {
      id: acknowledgement.messageId,
      deviceId: acknowledgement.device_id,
      answer: acknowledgement.answer,
      timestamp: acknowledgement.timestamp || Date.now(),
    };

    commit('disk/storeDispatcherMsgAck', payload);

    dispatch('disk/sendStoredDispatcherMsgAcks', channel);
  },
};

const mutations = {
  clear() {
    console.log('[Store] Clearing data from disk');
    clearKeys(state, Object.values(DISK_KEYS));
  },
  setEngineHours(state, engineHours) {
    persistAndSet(state, DISK_KEYS.engineHours, engineHours);
    if (!engineHours || !engineHours.timestamp) {
      state.engineHoursOld = true;
      return;
    }

    // if engine hours are too old, set required
    if (Date.now() - engineHours.timestamp > REQUIRED_ENGINE_HOURS_PERIOD) {
      state.engineHoursOld = true;
      return;
    }
  },
  clearEngineHoursTimeout(state) {
    clearTimeout(state.engineHoursOldTimeout);
  },
  setEngineHoursOldTimeout(timeout) {
    state.engineHoursOldTimeout = timeout;
  },
  setEngineHoursOld(state, bool) {
    state.engineHoursOld = bool;
  },
  setAllocation(state, allocation) {
    persistAndSet(state, DISK_KEYS.allocation, allocation);
  },
  setUnreadOperatorMessages(state, messages = []) {
    state.unreadOperatorMessages = messages;
  },
  setAsset(state, asset) {
    persistAndSet(state, DISK_KEYS.asset, asset);
  },
  setDeviceId(state, deviceId) {
    persistAndSet(state, DISK_KEYS.deviceId, deviceId);
  },
  setDispatcherMessages(state, messages = []) {
    sortInPlaceByTime(messages, 'timestamp', 'desc');
    state.dispatcherMessages = messages;
  },
  setDeviceAssignments(state, assignments = []) {
    state.deviceAssignments = assignments;
  },
  setDigUnitActivities(state, activities = []) {
    state.digUnitActivities = activities;
  },
  setPromptExceptionOnLogout(state, bool) {
    state.promptExceptionOnLogout = bool;
  },
  setPromptEngineHoursOnLogin(state, bool) {
    state.promptEngineHoursOnLogin = bool;
  },
  setPromptEngineHoursOnLogout(state, bool) {
    state.promptEngineHoursOnLogout = bool;
  },
};

export default new Vuex.Store({
  state,
  getters,
  actions,
  mutations,
  modules: {
    disk,
    constants,
    battery,
    location,
    connection,
    network,
    haulTruck,
    digUnit,
    watercart,
  },
  strict: useDebug,
});
