import { toUtcDate } from '../../code/time';

function parseActivity(activity) {
  return {
    id: activity.id,
    assetId: activity.asset_id,
    locationId: activity.location_id,
    materialTypeId: activity.material_type_id,
    loadStyleId: activity.load_style_id,
    timestamp: toUtcDate(activity.timestamp),
    server_timestamp: toUtcDate(activity.server_timestamp),
  };
}

const state = {
  currentActivities: Array(),
  historicActivities: Array(),
};

const getters = {};

const actions = {
  setCurrentActivities({ commit }, activities = []) {
    const formattedActivities = activities.map(parseActivity);
    commit('setCurrentActivities', formattedActivities);
  },
  setHistoricActivities({ commit }, activities = []) {
    const formattedActivities = activities.map(parseActivity);
    commit('setHistoricActivities', formattedActivities);
  },
};

const mutations = {
  setCurrentActivities(state, activities = []) {
    state.currentActivities = activities;
  },
  setHistoricActivities(state, activities = []) {
    state.historicActivities = activities;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
