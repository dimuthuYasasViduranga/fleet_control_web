import { attributeFromList } from '../code/helpers';
import { copyDate } from '../code/time';

export function toOperatorMessage(message, assets, operators, messageTypes) {
  const assetName = attributeFromList(assets, 'id', message.assetId, 'name');
  const operator = attributeFromList(operators, 'id', message.operatorId) || {};
  const messageText = attributeFromList(messageTypes, 'id', message.typeId, 'type');
  return {
    id: message.id,
    deviceId: message.deviceId,
    assetId: message.assetId,
    assetName,
    operatorId: message.operatorId,
    operatorName: operator.name,
    operatorNickname: operator.nickname,
    operatorFullname: operator.fullname,
    typeId: message.typeId,
    message: messageText,
    timestamp: copyDate(message.timestamp),
    serverTimestamp: copyDate(message.serverTimestamp),
    acknowledgeId: message.acknowledgeId,
    acknowledged: message.acknowledged,
  };
}

export function toEngineHour(engineHour, assets, operators) {
  const [asset, assetType] = attributeFromList(assets, 'id', engineHour.assetId, ['name', 'type']);
  const [name, nickname, fullname] = attributeFromList(operators, 'id', engineHour.operatorId, [
    'name',
    'nickname',
    'fullname',
  ]);
  return {
    id: engineHour.id,
    assetId: engineHour.assetId,
    asset,
    assetType,
    operatorId: engineHour.operatorId,
    operatorName: name,
    operatorNickname: nickname,
    operatorFullname: fullname,
    hours: engineHour.hours,
    timestamp: copyDate(engineHour.timestamp),
    serverTimestamp: copyDate(engineHour.serverTimestamp),
    deleted: engineHour.deleted,
  };
}

export function toFullAsset(
  asset,
  devices,
  operators,
  fullTimeCodes,
  radioNumbers,
  presence,
  currentDeviceAssignments,
  activeTimeAllocations,
) {
  const assetId = asset.id;
  const radioNumber = attributeFromList(radioNumbers, 'assetId', assetId, 'number');
  const deviceAssignment = currentDeviceAssignments.find(da => da.assetId === assetId) || {};
  const operator = operators.find(o => o.id === deviceAssignment.operatorId) || {};
  const device = devices.find(d => d.id === deviceAssignment.deviceId) || {};
  const activeTimeAllocation = activeTimeAllocations.find(a => a.assetId == assetId) || {};
  const activeTimeAllocationTC =
    fullTimeCodes.find(tc => tc.id === activeTimeAllocation.timeCodeId) || {};

  const present = !!presence.find(p => p === device.uuid);

  return {
    id: asset.id,
    name: asset.name,
    type: asset.type,
    typeId: asset.typeId,
    secondaryType: asset.secondaryType,
    deviceId: device.id,
    deviceUUID: device.uuid,
    operator: {
      id: operator.id,
      name: operator.name,
      nickname: operator.name,
      fullname: operator.fullname,
      shortname: operator.shortname,
    },
    activeTimeAllocation: {
      id: activeTimeAllocation.id,
      timeCodeId: activeTimeAllocation.timeCodeId,
      code: activeTimeAllocationTC.code,
      name: activeTimeAllocationTC.name,
      groupId: activeTimeAllocationTC.groupId,
      groupName: activeTimeAllocationTC.groupName,
      isReady: activeTimeAllocationTC.isReady,
      startTime: copyDate(activeTimeAllocation.startTime),
      endTime: copyDate(activeTimeAllocation.endTime),
    },
    radioNumber,
    hasDevice: !!device.id,
    present,
    deviceAssignedAt: copyDate(deviceAssignment.timestamp),
  };
}

export function fromGMapsGeofences(geofences) {
  return geofences.map(fromGMapsGeofence).filter(g => g);
}

export function fromGMapsGeofence(geofence) {
  const type = geofence.type;
  switch (type) {
    case 'marker':
      const pos = geofence.position;
      return {
        type: 'marker',
        position: {
          latitude: pos.lat,
          longitude: pos.lng,
        },
      };
    case 'circle':
      const center = geofence.center;
      return {
        type: 'circle',
        center: {
          latitude: center.lat,
          longitude: center.lng,
        },
        radius: geofence.radius,
      };
    case 'rectangle':
      const bounds = geofence.bounds || {};
      return {
        type: 'rectangle',
        bounds: {
          north: bounds.north,
          south: bounds.south,
          east: bounds.east,
          west: bounds.west,
        },
      };

    case 'polygon':
      const polygonPath = (geofence.path || []).map(e => {
        return {
          latitude: e.lat,
          longitude: e.lng,
        };
      });
      return {
        type: 'polygon',
        path: polygonPath,
      };

    case 'polyline':
      const polylinePath = (geofence.path || []).map(e => {
        return {
          latitude: e.lat,
          longitude: e.lng,
        };
      });
      return {
        type: 'polyline',
        path: polylinePath,
      };
  }
}

export function toGMapsGeofences(geofences) {
  return geofences.map(toGMapsGeofence).filter(g => g);
}

export function toGMapsGeofence(geofence) {
  const type = geofence.type;
  switch (type) {
    case 'marker':
      const pos = geofence.position;
      return {
        type: 'marker',
        position: {
          lat: pos.latitude,
          lng: pos.longitude,
        },
      };
    case 'circle':
      const center = geofence.center;
      return {
        type: 'circle',
        center: {
          lat: center.latitude,
          lng: center.longitude,
        },
        radius: geofence.radius,
      };
    case 'rectangle':
      const bounds = geofence.bounds || {};
      return {
        type: 'rectangle',
        bounds: {
          north: bounds.north,
          south: bounds.south,
          east: bounds.east,
          west: bounds.west,
        },
      };

    case 'polygon':
      const polygonPath = (geofence.path || []).map(e => {
        return {
          lat: e.latitude,
          lng: e.longitude,
        };
      });
      return {
        type: 'polygon',
        path: polygonPath,
      };

    case 'polyline':
      const polylinePath = (geofence.path || []).map(e => {
        return {
          lat: e.latitude,
          lng: e.longitude,
        };
      });
      return {
        type: 'polyline',
        path: polylinePath,
      };
  }
}
