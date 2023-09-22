import { toShiftTimeSpans } from './timespan_formatters/shiftTimeSpans';
import { copyDate, isDateEqual } from '@/code/time';
import { uniq, chunkEvery, sortByTime } from '@/code/helpers';

let ID = -1;

export function getNextId() {
  const id = ID;
  ID -= 1;
  return id;
}

export function toLocalDigUnitActivities(digUnitActivities = [], maxDatetime) {
  return chunkEvery(sortByTime(digUnitActivities, 'timestamp'), 2, 1)
    .map(([cur, next]) => {
      const startTime = cur.timestamp;
      const endTime = (next || {}).timestamp;

      return {
        id: cur.id,
        assetId: cur.assetId,
        startTime: copyDate(startTime),
        endTime: copyDate(endTime),
        materialTypeId: cur.materialTypeId,
        locationId: cur.locationId,
        deleted: false,
      };
    })
    .filter(a => a.startTime < maxDatetime);
}

export function addActiveEndTime(timeSpan, activeEndTime) {
  if (!timeSpan.endTime) {
    timeSpan.activeEndTime = activeEndTime;
  }

  return timeSpan;
}

export function updateArrayAt(arr, index, item) {
  if (index > arr.length) {
    return arr;
  }

  const newArr = arr.slice();
  newArr[index] = item;
  return newArr;
}

export function getChartLayoutGroups([TASpans, DUASpans, DASpans, eventSpans]) {
  const activity = {
    group: 'dig-unit-activity',
    label: 'Mt',
    percent: 0.3,
    subgroups: uniq(DUASpans.map(ts => ts.level || 0)),
  };

  const otherGroups = [
    {
      group: 'shift',
      label: 'S',
      subgroups: [0],
      canHide: true,
    },

    {
      group: 'device-assignment',
      label: 'Op',
      subgroups: uniq(DASpans.map(ts => ts.level || 0)),
    },

    {
      group: 'event',
      label: 'Ev',
      subgroups: uniq((eventSpans || []).map(ts => ts.level || 0)),
      canHide: true,
    },
    {
      group: 'allocation',
      label: 'Al',
      percent: 0.5,
      subgroups: uniq(TASpans.map(ts => ts.level || 0)),
    },
  ].filter(g => !g.canHide || g.subgroups.length !== 0);

  const nOtherGroups = otherGroups.length;
  otherGroups.forEach(g => (g.percent = (1 - activity.percent) / nOtherGroups));

  return otherGroups.concat([activity]);
}

export function styleSelected(timeSpan, style, selectedAllocId) {
  if (!selectedAllocId) {
    return style;
  }

  if (timeSpan.group === 'dig-unit-activity' && timeSpan.data.id === selectedAllocId) {
    return style;
  }

  return {
    ...style,
    opacity: 0.1,
    strokeOpacity: 0.2,
  };
}

export function getActivityChanges(originalActivities, newActivities) {
  const changes = [];
  newActivities.forEach(na => {
    // if no id or negative id (ie newly created)
    if (!na || na.id < 0) {
      changes.push(na);
      return;
    }

    const originalActivity = originalActivities.find(a => a.id === na.id);
    if (isDifferentAlloc(originalActivity, na)) {
      changes.push(na);
    }
  });
  return changes;
}

export function isDifferentAlloc(a, b) {
  return (
    (a.deleted || false) !== (b.deleted || false) ||
    a.materialTypeId !== b.materialTypeId ||
    !isDateEqual(a.startTime, b.startTime) ||
    !isDateEqual(a.endTime, b.endTime)
  );
}

export function nullifyDuplicateIds(timeSpans) {
  const length = timeSpans.length;
  chunkEvery(timeSpans, length, 1).map(list => {
    const first = list.shift();
    list.forEach(ts => {
      if (ts.data.id === first.data.id) {
        ts.data.id = null;
      }
    });
  });
  return timeSpans;
}

export function defaultNewDigUnitActivity() {
  return {
    materialTypeId: null,
    startTime: null,
    endTime: null,
  };
}

export function toShiftSpans(shifts, shiftTypes, timestamps) {
  const uniqTimestamps = uniq(timestamps.filter(ts => ts).map(ts => ts.getTime()));

  const relevantShifts = uniqTimestamps
    .map(ts => shifts.find(s => s.startTime.getTime() <= ts && ts < s.endTime.getTime()))
    .filter(s => s);

  return toShiftTimeSpans(relevantShifts, shiftTypes);
}
