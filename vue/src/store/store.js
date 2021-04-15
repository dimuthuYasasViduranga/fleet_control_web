import Vue from 'vue';
import Vuex from 'vuex';

import * as Transforms from './transforms.js';
import { toEvents } from './events.js';
import { toUtcDate, copyDate } from '../code/time.js';
import { parsePreStart } from './modules/constants.js';

import connection from './modules/connection.js';
import constants from './modules/constants.js';
import deviceStore from './modules/device_store.js';
import trackStore from './modules/track_store.js';

import haulTruck from './modules/haul_truck.js';
import digUnit from './modules/dig_unit.js';
import { attributeFromList } from '../code/helpers.js';

export function parseEngineHour(engineHour) {
  return {
    id: engineHour.id,
    assetId: engineHour.asset_id,
    operatorId: engineHour.operator_id,
    hours: engineHour.hours,
    timestamp: toUtcDate(engineHour.timestamp),
    serverTimestamp: toUtcDate(engineHour.server_timestamp),
    deleted: engineHour.deleted,
  };
}

export function parseTimeAllocation(alloc) {
  return {
    id: alloc.id,
    assetId: alloc.asset_id,
    timeCodeId: alloc.time_code_id,
    startTime: toUtcDate(alloc.start_time),
    endTime: toUtcDate(alloc.end_time),
    deleted: alloc.deleted || false,
    lockId: alloc.lock_id,
  };
}

function parseActivity(activity) {
  return {
    activity: activity.activity,
    source: activity.source,
    assetId: activity.asset_id,
    operatorId: activity.operator_id,
    timestamp: new Date(activity.device_timestamp),
    serverTimestamp: new Date(activity.server_timestamp),
  };
}

function parseOperatorMessage(message) {
  return {
    id: message.id,
    deviceId: message.device_id,
    assetId: message.asset_id,
    operatorId: message.operator_id,
    typeId: message.type_id,
    timestamp: toUtcDate(message.timestamp),
    serverTimestamp: toUtcDate(message.server_timestamp),
    acknowledgeId: message.acknowledge_id,
    acknowledged: !!message.acknowledge_id,
  };
}

function parseDispatcherMessage(message) {
  return {
    id: message.id,
    dispatcherId: message.dispatcher_id,
    assetId: message.asset_id,
    groupId: message.group_id,
    message: message.message,
    answers: message.answers || [],
    answer: message.answer,
    timestamp: toUtcDate(message.timestamp),
    serverTimestamp: toUtcDate(message.server_timestamp),
    acknowledgeId: message.acknowledge_id,
    acknowledged: !!message.acknowledge_id,
  };
}

export function parseCycle(cycle) {
  const startTime = toUtcDate(cycle.start_time);
  const endTime = toUtcDate(cycle.end_time);
  const duration = endTime - startTime;
  return {
    id: cycle.id,
    dimAssetId: cycle.dim_asset_id,
    assetId: cycle.asset_id,
    assetName: cycle.asset_name,

    // locations
    // start
    startHistId: cycle.location_history_start_id,
    startLocation: cycle.start_location,
    startLocationType: cycle.start_location_type,
    // load
    loadHistId: cycle.location_history_load_id,
    loadLocation: cycle.load_location,
    loadLocationType: cycle.load_location_type,
    // dump
    dumpHistId: cycle.location_history_dump_id,
    dumpLocation: cycle.dump_location,
    dumpLocationType: cycle.dump_location_type,

    // time
    calendarId: cycle.calendar_id,
    startTime,
    endTime,
    duration,

    // metrics
    distance: cycle.distance,
    timeusage: {
      emptyHaul: cycle.empty_haul_duration,
      queueAtLoad: cycle.queue_at_load_duration,
      spotAtLoad: cycle.spot_at_load_duration,
      loading: cycle.loading_duration,
      fullHaul: cycle.full_haul_duration,
      queueAtDump: cycle.queue_at_dump_duration,
      spotAtDump: cycle.spot_at_dump_duration,
      dumping: cycle.dumping_duration,
      crib: cycle.crib_duration,
      changeoverEmpty: cycle.change_over_empty,
      changeoverFull: cycle.change_over_full,
    },
  };
}

export function parseTimeusage(tu) {
  return {
    id: tu.id,
    dimAssetId: tu.dim_asset_id,
    assetId: tu.asset_id,
    assetName: tu.asset_name,

    // timeusage info
    cycleId: tu.cycle_id,
    typeId: tu.type_id,
    type: tu.type,

    // location
    location: tu.location,

    // time
    calendarId: tu.calendar_id,
    startTime: toUtcDate(tu.start_time),
    endTime: toUtcDate(tu.end_time),

    // metrics
    transmission: tu.transmission,
    distance: tu.distance,
    duration: tu.duration,
  };
}

/* ------------------------ module --------------------- */

const state = {
  notification: { device: null, message: '' },
  overlayOpen: false,

  currentEngineHours: Array(),
  historicEngineHours: Array(),
  radioNumbers: Array(),
  activeTimeAllocations: Array(),
  historicTimeAllocations: Array(),

  operatorMessages: Array(),
  dispatcherMessages: Array(),
  activityLog: Array(),
  fleetOps: {
    cycles: Array(),
    timeusage: Array(),
  },
  preStartSubmissions: Array(),
  dndSettings: {
    orientation: 'horizontal',
    vertical: {
      orderBy: 'location',
      columns: 2,
    },
    horizontal: {
      orderBy: 'location',
    },
  },
};

export function parsePreStartSubmission(submission) {
  return {
    id: submission.id,
    formId: submission.form_id,
    assetId: submission.asset_id,
    operatorId: submission.operator_id,
    employeeId: submission.employee_id,
    comment: submission.comment,
    form: parsePreStart(submission.form),
    responses: submission.responses.map(parseResponse),
    timestamp: toUtcDate(submission.timestamp),
    serverTimestamp: toUtcDate(submission.server_timestamp),
  };
}

function parseResponse(response) {
  return {
    id: response.id,
    submissionId: response.submission_id,
    controlId: response.control_id,
    answer: response.answer,
    comment: response.comment,
    ticketId: response.ticket_id,
    ticket: parseTicket(response.ticket),
  };
}

function parseTicket(ticket) {
  if (!ticket) {
    return null;
  }
  const status = ticket.active_status;
  return {
    id: ticket.id,
    assetId: ticket.assetId,
    createdByDispatcherId: ticket.created_by_dispatcher_id,
    activeStatus: {
      id: status.id,
      ticketId: status.ticket_id,
      reference: status.reference,
      details: status.details,
      statusTypeId: status.status_type_id,
      createdByDispatcherId: status.created_by_dispatcher_id,
      timestamp: toUtcDate(status.timestamp),
      serverTimestamp: toUtcDate(status.server_timestamp),
    },
    timestamp: toUtcDate(ticket.timestamp),
    serverTimestamp: toUtcDate(ticket.server_timestamp),
  };
}

const getters = {
  fullAssets: (state, getters) => {
    // info like 'track data' is not included because it updates
    // very frequently which could cause some performance issues
    const { assets, operators, radioNumbers } = state.constants;
    const { devices, currentDeviceAssignments } = state.deviceStore;
    const { presence } = state.connection;
    const { activeTimeAllocations } = state;
    const fullTimeCodes = getters['constants/fullTimeCodes'];

    return assets.map(a =>
      Transforms.toFullAsset(
        a,
        devices,
        operators,
        fullTimeCodes,
        radioNumbers,
        presence,
        currentDeviceAssignments,
        activeTimeAllocations,
      ),
    );
  },
  events: state => timezone => {
    const {
      operatorMessages,
      dispatcherMessages,
      activeTimeAllocations,
      historicTimeAllocations,
    } = state;

    const {
      assets,
      dispatchers,
      operators,
      operatorMessageTypes,
      locations,
      radioNumbers,
      timeCodes,
      timeCodeGroups,
    } = state.constants;

    const { devices, historicDeviceAssignments } = state.deviceStore;
    const haulTruckDispatches = state.haulTruck.historicDispatches;
    const timeAllocations = []
      .concat(activeTimeAllocations)
      .concat(historicTimeAllocations)
      .map(alloc => {
        const [timeCode, timeCodeGroupId] = attributeFromList(timeCodes, 'id', alloc.timeCodeId, [
          'name',
          'groupId',
        ]);
        const timeCodeGroup = attributeFromList(timeCodeGroups, 'id', timeCodeGroupId, 'name');
        const isReady = timeCodeGroup === 'Ready';
        return {
          id: alloc.id,
          assetId: alloc.assetId,
          timeCodeId: alloc.timeCodeId,
          timeCode,
          timeCodeGroupId,
          timeCodeGroup,
          isReady,
          startTime: copyDate(alloc.startTime),
          endTime: copyDate(alloc.endTime),
        };
      });

    return toEvents(
      assets,
      dispatchers,
      operators,
      devices,
      locations,
      radioNumbers,
      operatorMessages,
      operatorMessageTypes,
      dispatcherMessages,
      historicDeviceAssignments,
      haulTruckDispatches,
      timeAllocations,
      timezone,
    );
  },
  operatorMessages: ({ operatorMessages, constants }) => {
    const { assets, operators, operatorMessageTypes } = constants;
    return operatorMessages.map(m => {
      return Transforms.toOperatorMessage(m, assets, operators, operatorMessageTypes);
    });
  },
  unreadOperatorMessages: ({ operatorMessages, constants }) => {
    const { assets, operators, operatorMessageTypes } = constants;
    return operatorMessages.filter(m => !m.acknowledged).map(m => {
      return Transforms.toOperatorMessage(m, assets, operators, operatorMessageTypes);
    });
  },
  unreadDispatcherMessages: ({ dispatcherMessages }) => {
    return dispatcherMessages.filter(d => d.acknowledged !== true);
  },
  engineHours: ({ currentEngineHours, constants }) => assetType => {
    const engineHours = currentEngineHours.map(eh =>
      Transforms.toEngineHour(eh, constants.assets, constants.operators),
    );

    if (!assetType) {
      return engineHours;
    }

    return engineHours.filter(eh => eh.assetType === assetType);
  },
};

const actions = {
  setNotification({ commit }, { device, message }) {
    commit('setNotification', { device, message });
  },
  setOverlayOpen({ commit }, bool) {
    commit('setOverlayOpen', bool);
  },
  setCurrentEngineHours({ commit }, engineHours = []) {
    const formattedHours = engineHours.map(parseEngineHour);
    commit('setCurrentEngineHours', formattedHours);
  },
  setHistoricEngineHours({ commit }, engineHours = []) {
    const formattedHours = engineHours.map(parseEngineHour);
    commit('setHistoricEngineHours', formattedHours);
  },
  setActiveTimeAllocations({ commit }, allocs = []) {
    const formattedAllocations = allocs.map(parseTimeAllocation);
    commit('setActiveTimeAllocations', formattedAllocations);
  },
  setHistoricTimeAllocations({ commit }, allocs = []) {
    const formattedAllocations = allocs.map(parseTimeAllocation);
    commit('setHistoricTimeAllocations', formattedAllocations);
  },
  setActivityLog({ commit }, activities = []) {
    const formattedActivities = activities.map(parseActivity);
    commit('setActivityLog', formattedActivities);
  },
  setOperatorMessages({ commit }, messages = []) {
    const formattedMessages = messages.map(parseOperatorMessage);
    commit('setOperatorMessages', formattedMessages);
  },
  setDispatcherMessages({ commit }, messages = []) {
    const formattedMessages = messages.map(parseDispatcherMessage);
    commit('setDispatcherMessages', formattedMessages);
  },
  setFleetOpsData({ commit }, { cycles = [], timeusage = [] }) {
    const formattedCycles = cycles.map(parseCycle);
    const formattedTimeUsage = timeusage.map(parseTimeusage);
    commit('setFleetOpsCycles', formattedCycles);
    commit('setFleetOpsTimeusage', formattedTimeUsage);
  },
  setPreStartSubmissions({ commit }, submissions = []) {
    const formattedSubmissions = submissions.map(parsePreStartSubmission);
    commit('setPreStartSubmissions', formattedSubmissions);
  },
};

const mutations = {
  setOverlayOpen(state, bool) {
    state.overlayOpen = bool;
  },
  setNotification(state, { device, message }) {
    state.notification = {
      device,
      message,
    };
  },
  setCurrentEngineHours(state, engineHours = []) {
    state.currentEngineHours = engineHours;
  },
  setHistoricEngineHours(state, engineHours = []) {
    state.historicEngineHours = engineHours;
  },
  setActiveTimeAllocations(state, allocs = []) {
    state.activeTimeAllocations = allocs;
  },
  setHistoricTimeAllocations(state, allocs = []) {
    state.historicTimeAllocations = allocs;
  },
  setActivityLog(state, log = []) {
    state.activityLog = log;
  },
  setOperatorMessages(state, messages = []) {
    state.operatorMessages = messages;
  },
  setDispatcherMessages(state, messages = []) {
    state.dispatcherMessages = messages;
  },
  setFleetOpsCycles(state, cycles = []) {
    state.fleetOps.cycles = cycles;
  },
  setFleetOpsTimeusage(state, timeusage = []) {
    state.fleetOps.timeusage = timeusage;
  },
  setPreStartSubmissions(state, submissions = []) {
    state.preStartSubmissions = submissions;
  },
  setDndSettings(state, settings) {
    state.dndSettings = settings;
  },
};

Vue.use(Vuex);
const useDebug = process.env.NODE_ENV !== 'production';

export default new Vuex.Store({
  state,
  getters,
  actions,
  mutations,
  modules: {
    connection,
    constants,
    deviceStore,
    trackStore,
    haulTruck,
    digUnit,
  },
  strict: useDebug,
});
