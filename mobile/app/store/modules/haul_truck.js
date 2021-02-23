import * as Toaster from '../../clients/code/toaster.js';
import { persistAndSet, clearKeys, addDiskKeys } from '../persistence.js';

import { toUtcDate } from '../../clients/code/helper';

const DISK_KEYS = {
  dispatch: { key: 'dispatch', diskKey: 'HT:Dispatch', default: null, parser: parseDiskDispatch },
  activeManualCycle: {
    key: 'activeManualCycle',
    diskKey: 'HT:Active Manual Cycle',
    default: null,
    parser: parseDiskManualCycle,
  },
  manualCycles: {
    key: 'manualCycles',
    diskKey: 'HT:Manual Cycles',
    default: [],
    parser: parseDiskManualCycle,
  },
};

export function parseDiskDispatch(dispatch) {
  if (!dispatch) {
    return null;
  }

  return {
    id: dispatch.id,
    assetId: dispatch.assetId,
    digUnitId: dispatch.digUnitId,
    dumpId: dispatch.dumpId,
    acknowledgeId: dispatch.acknowledgeId,
    timestamp: toUtcDate(dispatch.timestamp),
  };
}

function parseDiskManualCycle(cycle) {
  if (!cycle) {
    return null;
  }

  return {
    id: cycle.id,
    assetId: cycle.assetId,
    operatorId: cycle.operatorId,
    loadUnitId: cycle.loadUnitId,
    startTime: toUtcDate(cycle.startTime),
    endTime: toUtcDate(cycle.endTime),
    loadLocationId: cycle.loadLocationId,
    relativeLevel: cycle.relativeLevel,
    shot: cycle.shot,
    materialTypeId: cycle.materialTypeId,
    dumpLocationId: cycle.dumpLocationId,
  };
}

export function parseDispatch(dispatch) {
  if (!dispatch) {
    return null;
  }

  return {
    id: dispatch.id,
    assetId: dispatch.asset_id,
    digUnitId: dispatch.dig_unit_id,
    dumpId: dispatch.dump_location_id,
    acknowledgeId: dispatch.acknowledge_id,
    timestamp: toUtcDate(dispatch.timestamp),
  };
}

function parseManualCycle(cycle) {
  return {
    id: cycle.id,
    assetId: cycle.asset_id,
    operatorId: cycle.operator_id,
    loadUnitId: cycle.load_unit_id,
    startTime: toUtcDate(cycle.start_time),
    endTime: toUtcDate(cycle.end_time),
    loadLocationId: cycle.load_location_id,
    relativeLevel: cycle.relative_level,
    shot: cycle.shot,
    materialTypeId: cycle.material_type_id,
    dumpLocationId: cycle.dump_location_id,
  };
}

function defaultManualCycle() {
  return {
    assetId: null,
    operatorId: null,
    startTime: null,
    endTime: null,
    // data
    loadUnitId: null,
    loadLocationId: null,
    dumpLocationId: null,
    relativeLevel: null,
    shot: null,
    materialTypeId: null,
  };
}

/* ----------------------- module -------------------- */

const state = {
  dispatch: null,
  activeManualCycle: null,
  manualCycles: Array(),
};

addDiskKeys(state, DISK_KEYS);

const getters = {};

const actions = {
  setState({ commit }, state) {
    if (!state) {
      commit('clear');
    } else {
      commit('setDispatch', parseDispatch(state.dispatch));
      commit('setManualCycles', state.manual_cycles.map(parseManualCycle));
    }
  },
  setDispatch({ commit }, dispatch) {
    if (!dispatch) {
      return;
    }
    commit('setDispatch', parseDispatch(dispatch));
  },
  submitAcknowledgement({ dispatch, commit }, { acknowledgement, channel }) {
    const payload = {
      id: acknowledgement.id,
      device_id: acknowledgement.deviceId,
      timestamp: acknowledgement.timestamp || Date.now(),
    };

    commit('disk/storeHaulTruckDispatchAcks', payload, { root: true });

    dispatch('disk/sendStoredHaulTruckDispatchAcks', channel, { root: true });
  },
  setActiveManualCycle({ commit }, cycle) {
    commit('setActiveManualCycle', cycle);
  },
  clearActiveManualCycle({ commit }) {
    commit('setActiveManualCycle', null);
  },
  updateActiveManualCycle({ state, commit }, params) {
    if (!state.activeManualCycle) {
      console.error(`[HaulTruck] Cannot update 'null' active tally cycle`);
      return;
    }

    const cycle = state.activeManualCycle || defaultManualCycle();

    commit('setActiveManualCycle', { ...cycle, ...params });
  },
  startActiveManualCycle({ commit }, params) {
    commit('setActiveManualCycle', { ...defaultManualCycle(), ...params });
  },
  submitManualCycle({ commit }, { cycle, channel }) {
    const payload = {
      id: cycle.id,
      asset_id: cycle.assetId,
      operator_id: cycle.operatorId,
      start_time: cycle.startTime,
      end_time: cycle.endTime,
      timestamp: cycle.timestamp || cycle.endTime,
      load_unit_id: cycle.loadUnitId,
      load_location_id: cycle.loadLocationId,
      relative_level: cycle.relativeLevel,
      shot: cycle.shot,
      material_type_id: cycle.materialTypeId,
      dump_location_id: cycle.dumpLocationId,
    };

    const storeFn = () => {
      Toaster.info('Cycle stored').show();
      commit('disk/storeManualCycle', payload);
    };

    channel
      .push('haul:submit manual cycles', [payload])
      .receive('ok', () => Toaster.info('Cycle sent').show())
      .receive('error', storeFn)
      .receive('timeout', storeFn);
  },
  setManualCycles({ commit }, cycles = []) {
    const formattedCycles = cycles.map(parseManualCycle);
    commit('setManualCycles', formattedCycles);
  },
};

const mutations = {
  clear(state) {
    clearKeys(state, Object.values(DISK_KEYS));
  },
  setDispatch(state, dispatch) {
    persistAndSet(state, DISK_KEYS.dispatch, dispatch);
  },
  setActiveManualCycle(state, cycle) {
    persistAndSet(state, DISK_KEYS.activeManualCycle, cycle);
  },
  setManualCycles(state, cycles) {
    persistAndSet(state, DISK_KEYS.manualCycles, cycles || []);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
