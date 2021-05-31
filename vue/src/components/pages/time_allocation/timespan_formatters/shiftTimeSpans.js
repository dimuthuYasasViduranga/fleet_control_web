import { attributeFromList } from '@/code/helpers';
import { toTimeSpan } from '../timeSpan';

const COLORS = {
  'Day Shift': '#9a9937',
  'Night Shift': '#3d6c6d',
  default: 'lightblue',
};

export function toShiftTimeSpans(shifts, shiftTypes) {
  return shifts.map(s => {
    const shiftType = attributeFromList(shiftTypes, 'id', s.shiftTypeId, 'name');
    const data = {
      id: s.id,
      shiftType,
    };
    return toTimeSpan(s.startTime, s.endTime, null, 'shift', 0, data);
  });
}

export function shiftStyle(timeSpan, region) {
  const shiftType = timeSpan.data.shiftType;
  const opacityScale = region === 'focus' ? 1 : 0.25;
  const strokeWidth = region === 'focus' ? 1 : 0.1;

  const fill = COLORS[shiftType] || COLORS.default;

  return {
    fill,
    opacity: 0.75 * opacityScale,
    strokeWidth,
    strokeColor: 'black',
    strokeOpacity: 1,
  };
}
