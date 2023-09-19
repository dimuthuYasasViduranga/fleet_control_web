import { attributeFromList } from '../../../../code/helpers';
import { toTimeSpan, addDynamicLevels } from '../timeSpan.js';
import { copyDate } from '@/code/time';

const COLORS = {
  1: '#dedc57',
  2: '#d4c311',
  3: '#8a8786',
  4: '#0e55cf',
  5: '#de8e0d',
  6: '#10b0eb',
  7: '#3bf00a',
};

const MISSING_COLOR = 'magenta';

function getFill(materialTypeCode) {
  const color = COLORS[materialTypeCode] || MISSING_COLOR;
  return color;
}

export function toDigUnitActivitySpans(digUnitActivities, materialTypes) {
  const activityTimeSpans = digUnitActivities.map(activity => {
    const materialTypeId = activity.materialTypeId;
    const [materialType] = attributeFromList(materialTypes, 'id', materialTypeId, ['type']);
    const startTime = copyDate(activity.startTime);
    const endTime = copyDate(activity.endTime);
    const activeEndTime = endTime ? null : new Date(Math.max(Date.now(), startTime.getTime()));

    const data = {
      id: activity.id,
      materialType: materialType || null,
      assetId: activity.assetId,
      materialTypeId,
    };
    return toTimeSpan(startTime, endTime, activeEndTime, 'dig-unit-activity', null, data);
  });

  return addDynamicLevels(activityTimeSpans)[0];
}

export function materialStyle(timeSpan, region, materialTypes) {
  const isOverlapping = timeSpan.isOverlapping;

  const opacityScale = region === 'focus' ? 1 : 0.25;
  const strokeWidth = region === 'focus' ? 1 : 0.1;
  const stroke = isOverlapping ? 'red' : 'black';
  const [materialTypeCode] = attributeFromList(materialTypes, 'id', timeSpan.data.materialTypeId, [
    'materialTypeCode',
  ]);
  const fill = getFill(materialTypeCode);

  return {
    fill,
    opacity: 0.75 * opacityScale,
    strokeWidth,
    stroke,
    strokeOpacity: 1,
  };
}
