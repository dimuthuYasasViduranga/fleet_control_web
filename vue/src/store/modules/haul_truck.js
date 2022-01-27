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
};

const mutations = {
  setCurrentDispatches(state, dispatches = []) {
    state.currentDispatches = dispatches;
  },
  setHistoricDispatches(state, dispatches = []) {
    state.historicDispatches = dispatches;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
