import { toUtcDate } from '../../clients/code/helper.js';

const { DeviceLocationMonitor } = require('../../clients/code/locationMonitor.js');

const VALID_SOURCES = ['server', 'device', 'router'];

function emptyLocation(timestamp) {
  return {
    position: {
      lat: 0,
      lng: 0,
      alt: 0,
    },
    velocity: {
      speed: 0,
      heading: 0,
    },
    accuracy: {
      horizontal: 0,
      verticalAccuracy: 0,
    },
    valid: false,
    timestamp,
  };
}

function parseTrack(track) {
  const pos = track.position;
  return {
    assetId: parseInt(track.asset_id, 10),
    assetName: track.asset_name,
    assetType: track.asset_type,
    position: {
      lat: parseFloat(pos.lat),
      lng: parseFloat(pos.lng),
      alt: parseFloat(pos.alt),
    },
    velocity: {
      heading: parseFloat(track.heading),
      speed: parseFloat(track.speed_ms),
    },
    accuracy: {
      horizontal: 0,
      verticalAccuracy: 0,
    },
    valid: track.valid,
    timestamp: toUtcDate(track.timestamp),
  };
}

function sourceValid(source) {
  return ['device', 'router', 'server'].includes(source);
}

// this is not placed in state because it observes internal state, causing errors
const deviceLocationMonitor = new DeviceLocationMonitor();

const state = {
  source: 'server',
  sources: VALID_SOURCES,
  deviceLocation: emptyLocation(),
  routerLocationMonitor: null,
  routerLocation: emptyLocation(),
  serverLocation: emptyLocation(),
  otherLocations: [],
};

const getters = {
  location: state => {
    return state[`${state.source}Location`];
  },
};

const actions = {
  setServerLocation({ commit }, track) {
    if (!track) {
      return;
    }
    const formattedTrack = parseTrack(track);
    commit('setServerLocation', formattedTrack);
  },
  setOtherLocations({ commit }, tracks = []) {
    const formattedTracks = tracks.map(parseTrack);
    commit('setOtherLocations', formattedTracks);
  },
  addOtherLocation({ commit }, track) {
    if (!track) {
      return;
    }
    const formattedTrack = parseTrack(track);
    commit('addOtherLocation', formattedTrack);
  },
  startLocationMonitor({ commit }) {
    const opts = {
      callback: pos => commit('setDeviceLocation', pos),
    };

    deviceLocationMonitor.start(opts);
  },
  stopLocationMonitor() {
    deviceLocationMonitor.stop();
  },
  startRouterMonitor() {
    console.error('[RouterMonitor] start not implemented');
  },
  stopRouterMonitor() {
    console.error('[RouterMonitor] stop not implemented');
  },
};

const mutations = {
  setSource(state, source) {
    const lowerSource = (source || '').toLowerCase();
    if (!sourceValid(lowerSource)) {
      console.error(`[Location] Cannot set invalid source '${lowerSource}'`);
      return;
    }

    console.log(`[Location] Source set to ${lowerSource}'`);
    state.source = lowerSource;
  },
  setDeviceLocation(state, position) {
    state.deviceLocation = position || emptyLocation(new Date());
  },
  setServerLocation(state, location) {
    state.serverLocation = location || emptyLocation(new Date());
  },
  setRouterLocation() {
    console.error('[RouterLocation] set location not implemented');
  },
  setOtherLocations(state, tracks = []) {
    state.otherLocations = tracks;
  },
  addOtherLocation(state, track) {
    const tracks = state.otherLocations.filter(t => t.assetId !== track.assetId);
    tracks.push(track);
    state.otherLocations = tracks;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
