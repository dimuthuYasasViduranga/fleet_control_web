import { copyDate } from '../../../code/time';
import { addDynamicLevels, toTimeSpan } from '../time_allocation/timeSpan';

const COLORS = {
  Ready: 'green',
  Standby: 'floralwhite',
  Process: 'gold',
  Down: 'grey',
  'No Task': '#004200',
};

const MISSING_COLOR = 'black';

export function toOperatorTimeSpans(allocations, assetName) {
  // create a set of basic allocations (all level 0)
  const spans = allocations.map(alloc => toOperatorTimeSpan(alloc, assetName));

  // determine overlapping elements and update levels
  return addDynamicLevels(spans)[0];
}

function toOperatorTimeSpan(alloc, assetName) {
  const data = {
    operatorName: alloc.operatorName,
    assetName: alloc.assetName,
    timeCode: alloc.timeCode,
    timeCodeGroup: alloc.timeCodeGroup,
  };

  return toTimeSpan(
    copyDate(alloc.startTime),
    copyDate(alloc.endTime),
    null,
    assetName,
    null,
    data,
  );
}

export function operatorColors() {
  return Object.values(COLORS);
}

export function operatorStyler(timeSpan, region) {
  const isFocus = region === 'focus';
  const isOverlapping = timeSpan.isOverlapping;

  const opacityScale = isFocus ? 0.75 : 0.5;
  const strokeWidth = isFocus ? 0.75 : 0.1;
  const stroke = isOverlapping ? 'red' : 'black';

  if (!timeSpan.data.assetName) {
    return {
      fill: 'orange',
      opacity: 0.2 * opacityScale,
      strokeWidth,
      stroke,
      strokeOpacity: 1,
    };
  } else {
    return {
      fill: getFill(timeSpan),
      opacity: opacityScale,
      strokeWidth,
      stroke,
      strokeOpacity: 1,
    };
  }
}

function getFill(timeSpan) {
  return COLORS[timeSpan.data.timeCode] || COLORS[timeSpan.data.timeCodeGroup] || MISSING_COLOR;
}
