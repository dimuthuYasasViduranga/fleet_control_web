import { toUtcDate } from '../../clients/code/helper';
import { parseDispatch, parseDiskDispatch } from './haul_truck.js';
import { persistAndSet, clearKeys, addDiskKeys } from '../persistence.js';

const DISK_KEYS = {
  activity: { key: 'activity', diskKey: 'DU:Activity', parser: parseDiskActivity },
  haulDispatches: {
    key: 'haulDispatches',
    diskKey: 'DU:Dispatches',
    default: [],
    parser: parseDiskDispatch,
  },
};

function parseDiskActivity(activity) {
  if (!activity) {
    return null;
  }

  return { ...activity, timestamp: toUtcDate(activity.timestamp) };
}

export function parseActivity(activity) {
  return {
    id: activity.id,
    assetId: activity.asset_id,
    groupId: activity.group_id,
    locationId: activity.location_id,
    materialTypeId: activity.material_type_id,
    loadStyleId: activity.load_style_id,
    timestamp: toUtcDate(activity.timestamp),
  };
}
/* ----------------------- module -------------------- */

const state = {
  activity: null,
  haulDispatches: Array(),
};

addDiskKeys(state, DISK_KEYS);

const getters = {};

const actions = {
  setState({ commit }, state) {
    if (!state) {
      commit('clear');
    } else {
      commit('setActivity', parseActivity(state.activity || {}));
      commit('setHaulDispatches', state.haul_truck_dispatches.map(parseDispatch));
    }
  },
  setActivity({ commit }, activity) {
    const formattedActivity = parseActivity(activity || {});
    commit('setActivity', formattedActivity);
  },
  setHaulDispatches({ commit }, dispatches = []) {
    const formattedDispatches = dispatches.map(parseDispatch);
    commit('setHaulDispatches', formattedDispatches);
  },
  submitActivity({ dispatch, commit }, { activity, channel }) {
    const payload = {
      asset_id: activity.assetId,
      location_id: activity.locationId,
      material_type_id: activity.materialTypeId,
      load_style_id: activity.loadStyleId,
      timestamp: activity.timestamp || Date.now(),
    };

    commit('setActivity', activity);
    commit('disk/storeDigUnitActivity', payload, { root: true });

    dispatch('disk/sendStoredDigUnitActivities', channel, { root: true });
  },
};

const mutations = {
  clear(state) {
    clearKeys(state, Object.values(DISK_KEYS));
  },
  setActivity(state, activity) {
    persistAndSet(state, DISK_KEYS.activity, activity);
  },
  setHaulDispatches(state, dispatches = []) {
    persistAndSet(state, DISK_KEYS.haulDispatches, dispatches);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
