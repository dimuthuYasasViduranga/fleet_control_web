import { attributeFromList } from '../../../../code/helpers';
import { toTimeSpan } from '../timeSpan';

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

export function shiftStyle(region) {
  const opacityScale = region === 'focus' ? 1 : 0.25;
  const strokeWidth = region === 'focus' ? 1 : 0.1;

  return {
    fill: 'darkslateblue',
    opacity: 0.75 * opacityScale,
    strokeWidth,
    strokeColor: 'black',
    strokeOpacity: 1,
  };
}
