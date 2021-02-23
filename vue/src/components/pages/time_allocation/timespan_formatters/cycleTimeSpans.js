import { toTimeSpan } from '../timeSpan';
import { copyDate } from '../../../../code/time';

const MISSING_COLOR = 'magenta';
const COLORS = {
  production: 'green',
  stockpile: 'darkorange',
  crusher: 'skyblue',
  rehab: 'violet',
  waste_dump: 'saddlebrown',
  waste_stockpile: 'chocolate',
};

export function toCycleTimeSpans(cycles) {
  return cycles.map(cycle => {
    const data = {
      ...cycle,
      timeusage: { ...cycle.timeusage },
      startTime: copyDate(cycle.startTime),
      endTime: copyDate(cycle.endTime),
    };

    return toTimeSpan(cycle.startTime, cycle.endTime, null, 'cycle', null, data);
  });
}

export function cycleStyle(timeSpan, region) {
  const fill = COLORS[timeSpan.data.dumpLocationType] || MISSING_COLOR;
  const strokeWidth = region === 'focus' ? 1 : 0.1;
  const opacity = region === 'focus' ? 0.75 : 0.25;

  return {
    fill,
    opacity,
    strokeWidth,
  };
}
