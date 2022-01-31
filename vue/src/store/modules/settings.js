const state = {
  use_pre_starts: false,
  send_device_gps: false,
  prompt_exception_on_logout: false,
  prompt_hngine_hours_on_login: false,
  prompt_pre_start_on_login: false,
  prompt_engine_hours_on_logout: false,
};

const getters = {};

const actions = {};

const mutations = {
  set(state, settings = {}) {
    Object.entries(settings).forEach(([key, bool]) => (state[key] = bool));
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
