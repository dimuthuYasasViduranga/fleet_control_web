import { toTimeSpan, addDynamicLevels } from '../timeSpan';
import { attributeFromList } from '@/code/helpers';
import { copyDate } from '@/code/time';

const COLORS = {
  Ready: 'green',
  Standby: 'floralwhite',
  Process: 'gold',
  Down: 'grey',
  'No Task': '#004200',
};
const MISSING_COLOR = 'magenta';

export function toAllocationTimeSpans(allocations, timeCodes, timeCodeGroups) {
  // create a set of basic allocations (all level 0)
  const allocationTimeSpans = allocations.map(alloc =>
    toAllocationTimeSpan(alloc, timeCodes, timeCodeGroups),
  );

  // determine overlapping elements and update levels
  return addDynamicLevels(allocationTimeSpans)[0];
}

function toAllocationTimeSpan(allocation, timeCodes, timeCodeGroups) {
  const timeCodeId = allocation.timeCodeId;
  const assetId = allocation.assetId;

  const [timeCode, timeCodeGroupId] = attributeFromList(timeCodes, 'id', timeCodeId, [
    'name',
    'groupId',
  ]);

  const [timeCodeGroup, timeCodeGroupAlias] = attributeFromList(
    timeCodeGroups,
    'id',
    timeCodeGroupId,
    ['name', 'alias'],
  );
  const startTime = copyDate(allocation.startTime);
  const endTime = copyDate(allocation.endTime);
  const activeEndTime = endTime ? null : new Date(Math.max(Date.now(), startTime.getTime()));

  const data = {
    id: allocation.id,
    assetId,
    timeCodeId,
    timeCode,
    timeCodeGroupId,
    timeCodeGroup,
    timeCodeGroupAlias,
    deleted: allocation.deleted || false,
    lockId: allocation.lockId,
  };

  return toTimeSpan(startTime, endTime, activeEndTime, 'allocation', null, data);
}

export function allocationColors() {
  return Object.values(COLORS);
}

export function allocationStyle(timeSpan, region) {
  const isFocus = region === 'focus';
  const isOverlapping = timeSpan.isOverlapping;

  const fill = getFill(timeSpan);
  const opacity = isFocus ? 0.75 : 0.5;
  const strokeWidth = isFocus ? 0.75 : 0.1;
  const stroke = isOverlapping ? 'red' : 'black';

  return {
    fill,
    selectedFill: fill,
    opacity,
    strokeWidth,
    stroke,
    strokeOpacity: 1,
  };
}

function getFill(timeSpan) {
  const color =
    COLORS[timeSpan.data.timeCode] || COLORS[timeSpan.data.timeCodeGroup] || MISSING_COLOR;

  if (timeSpan.data.lockId) {
    return `hatch|${color}`;
  }
  return color;
}
