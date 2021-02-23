import { toUtcDate } from '../../code/time';

const MISSING_EXCEPTION_AGE = 60 * 1000;

function parseDispatch(dispatch) {
  return {
    id: dispatch.id,
    groupId: dispatch.group_id,
    assetId: dispatch.asset_id,
    digUnitId: dispatch.dig_unit_id,
    loadId: dispatch.load_location_id,
    dumpId: dispatch.dump_location_id,
    timestamp: toUtcDate(dispatch.timestamp),
    serverTimestamp: toUtcDate(dispatch.server_timestamp),
    acknowledgeId: dispatch.acknowledge_id,
    acknowledged: !!dispatch.acknowledge_id,
  };
}

export function parseManualCycle(cycle) {
  return {
    id: cycle.id,
    assetId: cycle.asset_id,
    operatorId: cycle.operator_id,
    startTime: toUtcDate(cycle.start_time),
    endTime: toUtcDate(cycle.end_time),
    timestamp: toUtcDate(cycle.timestamp),
    serverTimestamp: toUtcDate(cycle.server_timestamp),
    loadUnitId: cycle.load_unit_id,
    loadLocationId: cycle.load_location_id,
    relativeLevel: cycle.relative_level,
    shot: cycle.shot,
    materialTypeId: cycle.material_type_id,
    dumpLocationId: cycle.dump_location_id,
    deleted: cycle.deleted,
  };
}

export function isMissingException(activeAllocation, locationType, timestamp) {
  if (activeAllocation.isReady !== true || !locationType || !timestamp) {
    return false;
  }

  const isOldEnough = Date.now() - timestamp.getTime() > MISSING_EXCEPTION_AGE;
  return isOldEnough && ['fuel_bay', 'parkup', 'maintenance'].includes(locationType);
}

/* --------------------- module -------------------- */
const state = {
  currentDispatches: Array(),
  historicDispatches: Array(),
  manualCycles: Array(),
};

const getters = {};

const actions = {
  setCurrentDispatches({ commit }, dispatches = []) {
    const formattedDispatches = dispatches.map(parseDispatch);
    commit('setCurrentDispatches', formattedDispatches);
  },
  setHistoricDispatches({ commit }, dispatches = []) {
    const formattedDispatches = dispatches.map(parseDispatch);
    commit('setHistoricDispatches', formattedDispatches);
  },
  setManualCycles({ commit }, cycles = []) {
    const formattedCycles = cycles.map(parseManualCycle);
    commit('setManualCycles', formattedCycles);
  },
};

const mutations = {
  setCurrentDispatches(state, dispatches = []) {
    state.currentDispatches = dispatches;
  },
  setHistoricDispatches(state, dispatches = []) {
    state.historicDispatches = dispatches;
  },
  setManualCycles(state, cycles = []) {
    state.manualCycles = cycles;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
