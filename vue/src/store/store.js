import Vue from 'vue';
import Vuex from 'vuex';

import Toaster from '@/code/toaster';
import * as Transforms from './transforms.js';
import { toEvents } from './events.js';
import { toUtcDate, copyDate } from '@/code/time.js';
import { Titler } from '@/code/titler.js';
import { AVPlayer } from '@/code/audio.js';
import { PageVisibility } from '@/code/visibility.js';

import { parsePreStartForm } from './modules/constants.js';

import TimeIcon from '@/components/icons/Time.vue';

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
  currentPreStartSubmissions: Array(),
  dndSettings: {
    orientation: 'horizontal',
    assetOrdering: 'normal',
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
    form: parsePreStartForm(submission.form),
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
    assetId: ticket.asset_id,
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

function notifyPreStartSubmissionChanges(state, newSubs) {
  const oldSubs = state.currentPreStartSubmissions;

  if (!oldSubs || oldSubs.length === 0) {
    return;
  }

  const changedSubs = newSubs.filter(s => {
    const oldSub = oldSubs.find(os => os.assetId === s.assetId);

    return oldSub && oldSub.id !== s.id;
  });

  const assets = state.constants.assets || [];

  changedSubs.forEach(sub => {
    const assetName = attributeFromList(assets, 'id', sub.assetId, 'name');

    const status = getPreStartSubmissionStatus(sub, state.constants.preStartTicketStatusTypes);

    const opts = {
      id: `pre-start-submission-${sub.assetId}`,
      replace: true,
    };

    if (status === 'Pass') {
      Toaster.info(`${assetName} | Pre-Start Passed`, opts);
    } else {
      Toaster.error(`${assetName} | Pre-Start ${status}`, opts);
    }
  });
}

function notifyActiveTimeAllocationChanges(state, newAllocs) {
  const oldAllocs = state.activeTimeAllocations;

  if (!oldAllocs || oldAllocs.length === 0) {
    return;
  }

  const changedAllocs = newAllocs.filter(newAlloc => {
    const oldAlloc = oldAllocs.find(oa => oa.assetId === newAlloc.assetId);

    return !oldAlloc || oldAlloc.timeCodeId !== newAlloc.timeCodeId;
  });

  const assets = state.constants.allAssets || [];
  const timeCodes = state.constants.timeCodes || [];
  const timeCodeGroups = state.constants.timeCodeGroups || [];

  changedAllocs.forEach(alloc => {
    const assetName = attributeFromList(assets, 'id', alloc.assetId, 'name');

    const [timeCodeName, timeCodeGroupId] = attributeFromList(timeCodes, 'id', alloc.timeCodeId, [
      'name',
      'groupId',
    ]);
    const timeCodeGroup = attributeFromList(timeCodeGroups, 'id', timeCodeGroupId) || {};
    const groupName = timeCodeGroup.alias || timeCodeGroup.name;

    const msg = `${assetName} | ${groupName} - ${timeCodeName}`;
    const id = `time-allocation-change-${alloc.assetId}`;
    Toaster.custom(msg, 'info', {
      id,
      replace: true,
      duration: 5000,
      icon: TimeIcon,
      actions: [
        {
          text: 'Change',
          onClick: (_e, toast) => {
            Vue.prototype.$eventBus.$emit('asset-assignment-open', alloc.assetId);
            toast.goAway(0);
          },
        },
        {
          text: 'Clear',
          onClick: (_e, toast) => toast.goAway(0),
        },
      ],
    });
  });
}

function getPreStartSubmissionStatus(submission, ticketStatusTypes) {
  const failures = submission.responses.filter(r => r.answer === false);

  if (failures.length === 0) {
    return 'Pass';
  }

  const closedTicketStatusId = attributeFromList(ticketStatusTypes, 'name', 'closed', 'id');

  const closed = failures.filter(
    f => f.ticket && f.ticket.activeStatus.statusTypeId === closedTicketStatusId,
  );

  if (closed.length === failures.length) {
    return 'Pass';
  }

  return 'Fail';
}

function notifyUnreadMessages(oldMessages, newMessages) {
  const oldUnread = oldMessages.filter(m => !m.acknowledged).length;
  const newUnread = newMessages.filter(m => !m.acknowledged).length;

  if (PageVisibility.hidden && newUnread > oldUnread) {
    AVPlayer.chime();
  }

  if (!newUnread) {
    Titler.reset();
  } else {
    Titler.change(`FleetControl | msgs (${newUnread})`);
  }
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
    const { operatorMessages, dispatcherMessages, activeTimeAllocations, historicTimeAllocations } =
      state;

    const {
      allAssets,
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
      allAssets,
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
    return operatorMessages
      .filter(m => !m.acknowledged)
      .map(m => {
        return Transforms.toOperatorMessage(m, assets, operators, operatorMessageTypes);
      });
  },
  unreadDispatcherMessages: ({ dispatcherMessages }) => {
    return dispatcherMessages.filter(d => d.acknowledged !== true);
  },
  engineHours:
    ({ currentEngineHours, constants }) =>
    assetType => {
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
  setCurrentPreStartSubmissions({ commit }, submissions = []) {
    const formattedSubmissions = submissions.map(parsePreStartSubmission);
    commit('setCurrentPreStartSubmissions', formattedSubmissions);
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
    notifyActiveTimeAllocationChanges(state, allocs);
    state.activeTimeAllocations = allocs;
  },
  setHistoricTimeAllocations(state, allocs = []) {
    state.historicTimeAllocations = allocs;
  },
  setActivityLog(state, log = []) {
    state.activityLog = log;
  },
  setOperatorMessages(state, messages = []) {
    notifyUnreadMessages(state.operatorMessages, messages);
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
  setCurrentPreStartSubmissions(state, submissions = []) {
    notifyPreStartSubmissionChanges(state, submissions);
    state.currentPreStartSubmissions = submissions;
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
