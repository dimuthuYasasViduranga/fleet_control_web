import { chunkEvery, sortByTime } from '../../../../code/helpers';
import { toTimeSpan } from '../timeSpan.js';

export function toDigUnitActivitySpans(digUnitActivities) {
  return chunkEvery(sortByTime(digUnitActivities, 'timestamp'), 2, 1).map(([cur, next]) => {
    const assetId = cur.assetId;
    const materialTypeId = cur.materialTypeId;
    const materialType = cur.materialType;

    const endTime = (next || {}).timestamp;
    const activeEndTime = null;

    const data = {
      materialType,
      assetId,
      materialTypeId,
    };

    return toTimeSpan(cur.timestamp, endTime, activeEndTime, 'dig-unit-activity', null, data);
  });
}

export function materialStyle(timeSpan, region) {
  const type = timeSpan.data.materialType;

  const opacityScale = region === 'focus' ? 1 : 0.25;
  const strokeWidth = region === 'focus' ? 1 : 0.1;

  switch (type) {
    case 'Coal A':
      return {
        fill: 'grey',
        opacity: 0.75 * opacityScale,
        strokeWidth,
        strokeColor: 'black',
        strokeOpacity: 1,
      };

    case 'Coal B':
      return {
        fill: 'orange',
        opacity: 0.75 * opacityScale,
        strokeWidth,
        strokeColor: 'black',
        strokeOpacity: 1,
      };

    case 'Coal C':
      return {
        fill: 'yellow',
        opacity: 0.1 * opacityScale,
        strokeWidth,
        strokeColor: 'black',
        strokeOpacity: 1,
      };
  }
}
