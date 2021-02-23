import { toUtcDate } from '../../code/time.js';

export function parseDeviceAssignment(assignment) {
  return {
    id: assignment.id,
    deviceId: assignment.device_id,
    assetId: assignment.asset_id,
    operatorId: assignment.operator_id,
    timestamp: toUtcDate(assignment.timestamp),
    serverTimestamp: toUtcDate(assignment.server_timestamp),
  };
}

function parseDevice(device) {
  return {
    id: device.id,
    uuid: device.uuid,
    authorized: device.authorized,
    details: device.details || {},
  };
}

/* -------------------- module ------------------*/
const state = {
  devices: Array(),
  currentDeviceAssignments: Array(),
  historicDeviceAssignments: Array(),
  pendingDevices: Array(),
  acceptUntil: Number(),
};

const getters = {};

const actions = {
  setDevices({ commit }, devices = []) {
    const formattedDevices = devices.map(parseDevice);
    commit('setDevices', formattedDevices);
  },
  setCurrentDeviceAssignments({ commit }, assignments = []) {
    const formattedAssignments = assignments.map(parseDeviceAssignment);
    commit('setCurrentDeviceAssignments', formattedAssignments);
  },
  setHistoricDeviceAssignments({ commit }, assignments = []) {
    const formattedAssignments = assignments.map(parseDeviceAssignment);
    commit('setHistoricDeviceAssignments', formattedAssignments);
  },
  setPendingDevices({ commit }, pendingDevices) {
    const acceptUntil = pendingDevices.accept_until;
    const devices = pendingDevices.devices;
    commit('setPendingDevices', { devices, acceptUntil });
  },
};

const mutations = {
  setDevices(state, devices = []) {
    state.devices = devices;
  },
  setCurrentDeviceAssignments(state, assignments = []) {
    state.currentDeviceAssignments = assignments;
  },
  setHistoricDeviceAssignments(state, assignments = []) {
    state.historicDeviceAssignments = assignments;
  },
  setPendingDevices(state, { devices = [], acceptUntil }) {
    state.pendingDevices = devices;
    state.acceptUntil = acceptUntil;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
