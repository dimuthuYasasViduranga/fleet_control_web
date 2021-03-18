import { copyDate, setTimeZone } from '../code/time';
import { attributeFromList, chunkEvery, dedupBy, dedupByMany } from '../code/helpers';

export function toEvents(
  assets,
  dispatchers,
  operators,
  devices,
  locations,
  assetRadios,
  operatorMessages,
  operatorMessageTypes,
  dispatcherMessages,
  deviceAssignments,
  haulTruckDispatches,
  timeAllocations,
  timezone,
) {
  const opMsgs = toOperatorMessageEvents(
    assets,
    operators,
    assetRadios,
    operatorMessages,
    operatorMessageTypes,
  );
  const [dispatcherMsgEvents, massDispatcherMsgEvents] = toDispatcherMessageEvents(
    assets,
    dispatchers,
    dispatcherMessages,
  );

  const [haulTruckDispatchEvents, haulTruckMassDispatchEvents] = toHaulTruckDispatchEvents(
    assets,
    locations,
    haulTruckDispatches,
  );

  const deviceAssignmentEvents = toDeviceAssignmentEvents(assets, devices, deviceAssignments);

  const loginLogoutEvents = toLoginLogoutEvents(assets, operators, deviceAssignments);

  const timeAllocEvents = toTimeAllocEvents(assets, timeAllocations);

  let events = opMsgs
    .concat(dispatcherMsgEvents)
    .concat(massDispatcherMsgEvents)
    .concat(haulTruckDispatchEvents)
    .concat(haulTruckMassDispatchEvents)
    .concat(deviceAssignmentEvents)
    .concat(loginLogoutEvents)
    .concat(timeAllocEvents);

  const assetIds = assets.map(a => a.id);
  const dateSeparators = getDateSeparators(events, assetIds, timezone);
  events = events.concat(dateSeparators);

  // order by timestamp
  events.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
  return events;
}

function groupBy(list, key) {
  const dict = list.reduce((group, element) => {
    (group[element[key]] = group[element[key]] || []).push(element);
    return group;
  }, {});

  return Object.entries(dict).map(([groupKey, value]) => [
    parseInt(groupKey, 10) || groupKey,
    value,
  ]);
}

function toOperatorMessageEvents(assets, operators, assetRadios, messages, messageTypes) {
  return messages.map(m => {
    const assetName = attributeFromList(assets, 'id', m.assetId, 'name');
    const [shortname, fullname] = attributeFromList(operators, 'id', m.operatorId, [
      'shortname',
      'fullname',
    ]);
    let text = attributeFromList(messageTypes, 'id', m.typeId, 'type');

    if (text === 'Call Me') {
      const radioNumber = attributeFromList(assetRadios, 'assetId', m.assetId, 'number');
      if (radioNumber) {
        text = `${text} (radio: ${radioNumber})`;
      }
    }

    return {
      eventType: 'operator-message',
      messageId: m.id,
      timestamp: copyDate(m.timestamp),
      assetId: m.assetId,
      assetName,

      operatorShortname: shortname,
      operatorFullname: fullname,

      acknowledged: m.acknowledged,
      text,
      searchable: ['assetName', 'operatorFullname', 'text', 'eventType'],
    };
  });
}

function toDispatcherMessageEvents(assets, dispatchers, messages) {
  const singleMsgs = [];
  const massMsgs = [];

  // group into single or mass messages
  messages.forEach(m => {
    if (m.groupId) {
      massMsgs.push(m);
    } else {
      singleMsgs.push(m);
    }
  });

  // create single messages
  const singleEvents = singleMsgs.map(m => {
    const assetName = attributeFromList(assets, 'id', m.assetId, 'name');
    const dispatcher = attributeFromList(dispatchers, 'id', m.dispatcherId, 'name');
    return {
      eventType: 'dispatcher-message',
      messageId: m.id,
      timestamp: copyDate(m.timestamp),
      serverTimestamp: copyDate(m.serverTimestamp),
      assetId: m.assetId,
      dispatcherId: m.dispatcherId,
      dispatcher,
      answers: m.answers,
      answer: m.answer,
      assetName,
      text: m.message,
      acknowledged: m.acknowledged,
      groupId: m.groupId,
      searchable: ['assetName', 'text', 'eventType', 'answer'],
    };
  });

  // create mass messages
  const groupIds = [...new Set(massMsgs.map(m => m.groupId))];
  const massEvents = groupIds.map(groupId => {
    const msgs = massMsgs.filter(m => m.groupId === groupId);
    const subjects = msgs.map(m => {
      const assetName = attributeFromList(assets, 'id', m.assetId, 'name');
      return {
        assetId: m.assetId,
        assetName,
        answer: m.answer,
        acknowledged: m.acknowledged,
      };
    });

    const assetNames = msgs.map(m => m.assetName).join(',');
    const assetIds = msgs.map(m => m.assetId);

    // the base message represents data similar to all recipients
    const baseMessage = msgs[0];
    const dispatcher = attributeFromList(dispatchers, 'id', baseMessage.dispatcherId, 'name');

    return {
      eventType: 'dispatcher-mass-message',
      groupId,
      timestamp: copyDate(baseMessage.timestamp),
      serverTimestamp: copyDate(baseMessage.serverTimestamp),
      text: baseMessage.message,
      assetIds,
      assetNames,
      dispatcherId: baseMessage.dispatcherId,
      dispatcher,
      answers: baseMessage.answers,
      subjects,
      searchable: ['assetNames', 'text', 'eventType'],
    };
  });

  return [singleEvents, massEvents];
}

function toHaulTruckDispatchEvents(assets, locations, dispatches) {
  const events = toHaulTruckDispatchEvent(assets, locations, dispatches);

  const keys = ['loadLocation', 'dumpLocation'];
  const singleEvents = groupBy(events, 'assetName')
    .map(([_asset, events]) => dedupByMany(events, keys))
    .flat()
    .filter(e => !e.groupId);

  const groupedEvents = toHaulTruckMassDispatchEvents(events.filter(e => e.groupId));

  return [singleEvents, groupedEvents];
}

function getLocationName(locations, id) {
  return attributeFromList(locations, 'id', id, 'name');
}

function toHaulTruckDispatchEvent(assets, locations, dispatches) {
  return dispatches.map(d => {
    const assetName = attributeFromList(assets, 'id', d.assetId, 'name');

    const loadLocation = getLocationName(locations, d.loadId);
    const dumpLocation = getLocationName(locations, d.dumpId);

    return {
      eventType: 'haul-truck-dispatch',
      groupId: d.groupId,
      assetId: d.assetId,
      assetName,

      loadLocation,
      dumpLocation,
      timestamp: copyDate(d.timestamp),
      serverTimestamp: copyDate(d.serverTimestamp),
      searchable: ['loadLocation', 'dumpLocation', 'nextLocation', 'assetName'],
    };
  });
}

function toHaulTruckMassDispatchEvents(events) {
  const groupIds = [...new Set(events.map(e => e.groupId))];
  return groupIds.map(groupId => {
    const relatedEvents = events.filter(e => e.groupId === groupId);
    const assetIds = relatedEvents.map(e => e.assetId);
    const assetNames = relatedEvents.map(e => e.assetName);
    assetNames.sort((a, b) => a.localeCompare(b));
    const assetNamesString = assetNames.join(',');

    // take one event to serve as the base for all common information
    const baseEvent = relatedEvents[0];

    return {
      eventType: 'haul-truck-mass-dispatch',
      groupId,
      assetIds,
      assetNames: assetNamesString,
      loadLocation: baseEvent.loadLocation,
      dumpLocation: baseEvent.dumpLocation,
      timestamp: copyDate(baseEvent.timestamp),
      serverTimestamp: copyDate(baseEvent.serverTimestamp),
      searchable: ['assetNames', 'loadLocation', 'dumpLocation'],
    };
  });
}

function toLoginLogoutEvents(assets, operators, deviceAssignments) {
  // operator login/logout from asset
  const assignmentsByAsset = groupBy(deviceAssignments.filter(a => a.assetId), 'assetId');
  return assignmentsByAsset.map(assigns => toLoginLogoutEvent(assigns, assets, operators)).flat();
}

function toLoginLogoutEvent([assetId, assignments], assets, operators) {
  if (assignments.length === 0) {
    return [];
  }
  const assetName = attributeFromList(assets, 'id', assetId, 'name');

  // dedup by operator id for the same asset
  const filteredAssignments = dedupBy(assignments.reverse(), 'operatorId');

  // chunk groups by 2 so that logout info has who logged out
  return chunkEvery(filteredAssignments, 2, 1, 'discard').map(([prevAssign, curAssign]) => {
    const eventType = curAssign.operatorId ? 'login' : 'logout';
    const operatorId = curAssign.operatorId || prevAssign.operatorId;

    const [operatorFullname, operatorShortname] = attributeFromList(operators, 'id', operatorId, [
      'fullname',
      'shortname',
    ]);

    return {
      eventType,
      assetId,
      assetName,
      operatorId,
      operatorFullname,
      operatorShortname,
      timestamp: copyDate(curAssign.timestamp),
      serverTimestamp: copyDate(curAssign.serverTimestamp),
      searchable: ['operatorFullname', 'assetName', 'eventType'],
    };
  });
}

function toDeviceAssignmentEvents(assets, devices, deviceAssignments) {
  // device assigned/unassigned from asset
  const assignmentsByAsset = groupBy(deviceAssignments, 'assetId');
  return assignmentsByAsset.map(group => toDeviceAssignment(group, assets, devices)).flat();
}

function toDeviceAssignment([assetId, assignments], assets, devices) {
  const assetName = attributeFromList(assets, 'id', assetId, 'name');

  const filteredAssignments = dedupBy(assignments.reverse(), 'deviceId');
  return chunkEvery(filteredAssignments, 2, 1, 'discard').map(([prev, assignment]) => {
    const eventType = assignment.deviceId ? 'device-assigned' : 'device-unassigned';
    const deviceId = assignment.deviceId || prev.deviceId;

    const deviceUUID = attributeFromList(devices, 'id', deviceId, 'uuid');

    return {
      eventType,
      assetId,
      assetName,
      deviceId,
      deviceUUID,
      timestamp: copyDate(assignment.timestamp),
      serverTimestamp: copyDate(assignment.serverTimestamp),
      searchable: ['deviceUUID', 'assetName', 'eventType'],
    };
  });
}

function toTimeAllocEvents(assets, timeAllocations) {
  const allocsByAsset = groupBy(timeAllocations, 'assetId');
  return allocsByAsset.map(group => toTimeAllocEvent(group, assets)).flat();
}

function toTimeAllocEvent([assetId, allocs], assets) {
  const assetName = attributeFromList(assets, 'id', assetId, 'name');

  return allocs
    .map(alloc => {
      const duration = alloc.endTime ? Math.trunc((alloc.endTime - alloc.startTime) / 1000) : null;
      const base = {
        id: alloc.id,
        assetId,
        assetName,
        timeCodeId: alloc.timeCodeId,
        timeCode: alloc.timeCode,
        timeCodeGroupId: alloc.timeCodeGroupId,
        timeCodeGroup: alloc.timeCodeGroup,
        isReady: alloc.isReady,
        duration,
        searchable: ['assetName', 'eventType', 'timeCode', 'timeCodeGroup'],
      };
      return [{ ...base, eventType: 'time-allocation', timestamp: copyDate(alloc.startTime) }];
    })
    .flat()
    .filter(alloc => alloc.timestamp);
}

function getDateSeparators(events, assetIds, timezone) {
  // asset ids are added so that all filters work with them
  if (!events) {
    return [];
  }

  const timestamps = events.map(e => e.timestamp);
  timestamps.unshift(new Date());

  const separators = timestamps.map(ts => toDateSeparator(ts, assetIds, timezone));

  return dedupBy(separators, 'date');
}

function toDateSeparator(date, assetIds, timezone) {
  const site = setTimeZone(date, timezone).startOf('day');
  const dateString = site.toFormat('yyyy-MM-dd');
  const timestamp = site.toJSDate();
  return {
    eventType: 'date-separator',
    timestamp,
    date: dateString,
    assetIds,
  };
}
