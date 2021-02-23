import { toUtcDate } from '../../code/time';

const PENDING_TRACK_MERGE_PERIOD = 10 * 1000;

function parseDistance(distance) {
  if (isNaN(distance) || distance == null) {
    return null;
  }
  return distance;
}

function parseAssetTypeInfo(track) {
  switch (track.asset_type) {
    case 'Haul Truck':
      const info = track.haul_truck_info || {};
      return [
        'haulTruckInfo',
        {
          loadId: info.load_location_id || null,
          dumpId: info.dump_location_id || null,
          loadDistance: parseDistance(info.load_location_distance),
          dumpDistance: parseDistance(info.dump_location_distance),
          currentClusterId: info.current_cluster_id,
          loadPath: info.load_location_path || [],
          dumpPath: info.dump_location_path || [],
        },
      ];
  }

  return ['noAssetInfo', null];
}

function parseTrack(track) {
  const [key, data] = parseAssetTypeInfo(track);
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
    [key]: data,
    timestamp: toUtcDate(track.timestamp),
    valid: track.valid,
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
