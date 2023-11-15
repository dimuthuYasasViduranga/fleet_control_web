import { toTimeSpan } from '../timeSpan';
import { copyDate } from '../../../../code/time';

const MISSING_COLOR = 'magenta';
const TU_COLORS = {
  // cycle components
  EmptyHaul: 'green',
  QueueAtLoad: 'orange',
  SpotAtLoad: 'darkcyan',
  Loading: 'cyan',
  FullHaul: 'darkgreen',
  QueueAtDump: 'orange',
  SpotAtDump: 'saddlebrown',
  Dumping: 'chocolate',
  // other components
  NonProductiveTravel: 'silver',
  Parkup: 'red',
  CribOnHaul: 'darkred',
  UnknownStationary: 'darkred',
  Refuelling: 'yellow',
  MEM: 'darkgrey',
  ChangeOverEmpty: 'darkred',
  ChangeOverFull: 'darkred',
};

export function toTimeusageTimeSpans(timeusage) {
  // might want to dedup on location (so there arnt large chunks by transmission)

  return timeusage.map(tu => {
    const data = {
      type: 'timeusage',
      assetId: tu.assetId,
      assetName: tu.assetName,

      id: tu.id,
      cycleId: tu.cycleId,
      type: tu.type,

      location: tu.location,

      startTime: copyDate(tu.startTime),
      endTime: copyDate(tu.endTime),

      transmission: tu.transmission,
      distance: tu.distance,
      duration: tu.duration,
    };

    return toTimeSpan(tu.startTime, tu.endTime, null, 'timeusage', null, data);
  });
}

export function timeusageStyle(timeSpan, region) {
  const tut = timeSpan.data.type || timeSpan.data.time_usage_type;
  const fill = TU_COLORS[tut] || MISSING_COLOR;
  const strokeWidth = 0;
  const opacity = region === 'focus' ? 0.75 : 0.25;

  return {
    fill,
    opacity,
    strokeWidth,
  };
}
