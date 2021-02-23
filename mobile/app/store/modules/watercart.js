import { addDiskKeys, clearKeys, persistAndSet } from '../persistence';
import { parseDispatch, parseDiskDispatch } from './haul_truck';

const DISK_KEYS = {
  haulDispatches: {
    key: 'haulDispatches',
    diskKey: 'WC:Dispatches',
    default: [],
    parser: parseDiskDispatch,
  },
};

const state = {
  haulDispatches: Array(),
};

addDiskKeys(state, DISK_KEYS);

const getters = {};

const actions = {
  setState({ commit }, state) {
    if (!state) {
      commit('clear');
    } else {
      commit('setHaulDispatches', state.haul_truck_dispatches.map(parseDispatch));
    }
  },
  setHaulDispatches({ commit }, dispatches = []) {
    const formattedDispatches = dispatches.map(parseDispatch);
    commit('setHaulDispatches', formattedDispatches);
  },
};

const mutations = {
  clear(state) {
    clearKeys(state, Object.values(DISK_KEYS));
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
