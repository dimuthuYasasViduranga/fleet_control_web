import { chunkEvery, sortByTime, attributeFromList } from '../../../../code/helpers';
import { toTimeSpan } from '../timeSpan.js';

export function toDeviceAssignmentSpans(deviceAssignments, devices, operators) {
  return chunkEvery(sortByTime(deviceAssignments, 'timestamp'), 2, 1).map(([cur, next]) => {
    const assetId = cur.assetId;
    const operatorId = cur.operatorId;
    const deviceId = cur.deviceId;

    const [shortname, fullname] = attributeFromList(operators, 'id', operatorId, [
      'shortname',
      'fullname',
    ]);
    const deviceUUID = attributeFromList(devices, 'id', deviceId, 'uuid');

    const endTime = (next || {}).timestamp;
    const activeEndTime = null;

    const type = getType(operatorId, deviceId);

    const data = {
      type,
      assetId,
      operatorId,
      operatorShortname: shortname,
      operatorFullname: fullname,
      deviceId,
      deviceUUID,
    };

    return toTimeSpan(cur.timestamp, endTime, activeEndTime, 'device-assignment', null, data);
  });
}

export function loginStyle(timeSpan, region) {
  const type = timeSpan.data.type;

  const opacityScale = region === 'focus' ? 1 : 0.25;
  const strokeWidth = region === 'focus' ? 1 : 0.1;

  switch (type) {
    case 'logged-in':
      return {
        fill: 'green',
        opacity: 0.75 * opacityScale,
        strokeWidth,
        strokeColor: 'black',
        strokeOpacity: 1,
      };

    case 'logged-out':
      return {
        fill: 'grey',
        opacity: 0.75 * opacityScale,
        strokeWidth,
        strokeColor: 'black',
        strokeOpacity: 1,
      };

    case 'no-device':
      return {
        fill: 'orange',
        opacity: 0.1 * opacityScale,
        strokeWidth,
        strokeColor: 'black',
        strokeOpacity: 1,
      };
  }
}

function getType(operatorId, deviceId) {
  if (operatorId) {
    return 'logged-in';
  }

  if (deviceId) {
    return 'logged-out';
  }

  return 'no-device';
}
