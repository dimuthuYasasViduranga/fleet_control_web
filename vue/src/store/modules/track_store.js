import { toUtcDate } from '@/code/time';

const PENDING_TRACK_MERGE_PERIOD = 10 * 1000;

function parseTrack(track) {
  const acc = track.accuracy || {};
  return {
    name: track.asset_name,
    assetId: parseInt(track.asset_id, 10),
    assetType: track.asset_type,
    userId: track.user_id,
    position: track.position,
    velocity: {
      heading: parseFloat(track.heading),
      speed: parseFloat(track.speed_ms),
    },
    ignition: track.ignition,
    location: {
      id: track.location_id,
      historyId: track.location_history_id,
      name: track.location_name,
      type: track.location_type,
    },
    accuracy: {
      vertical: acc.vertical || null,
      horizontal: acc.horizontal || null,
    },
    timestamp: toUtcDate(track.timestamp),
    valid: track.valid,
    source: track.source,
  };
}

function mergeTracks(original = [], newTracks = []) {
  const originalMap = original.reduce((acc, track) => {
    acc[track.assetId] = track;
    return acc;
  }, {});

  return Object.values({ ...originalMap, ...newTracks });
}

const state = {
  tracks: Array(),
  pendingTracks: Object(),
  pendingInterval: null,
};

const getters = {};

const actions = {
  startPendingInterval({ commit }) {
    commit('clearPendingInterval');
    const callback = () => {
      commit('mergePendingTracks');
    };
    commit('startPendingInterval', callback);
  },
  setTracks({ commit }, tracks = []) {
    const formattedTracks = tracks.map(parseTrack);
    commit('setTracks', formattedTracks);
  },
  addTrack({ commit }, track) {
    if (track) {
      commit('addTrack', parseTrack(track));
    }
  },
};

const mutations = {
  startPendingInterval(state, callback) {
    state.pendingTracks = {};
    state.pendingInterval = setInterval(callback, PENDING_TRACK_MERGE_PERIOD);
  },
  clearPendingInterval(state) {
    state.pendingTracks = {};
    clearInterval(state.pendingInterval);
  },
  mergePendingTracks() {
    state.tracks = mergeTracks(state.tracks, state.pendingTracks);
    state.pendingTracks = {};
  },
  setTracks(state, tracks = []) {
    state.pendingTracks = {};
    state.tracks = tracks;
  },
  addTrack(state, track) {
    state.pendingTracks[track.assetId] = track;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
