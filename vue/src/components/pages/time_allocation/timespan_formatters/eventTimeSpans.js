import { toTimeSpan } from '../timeSpan';

const MISSING_COLOR = 'purple';
const COLORS = {
  compliant: 'green',
  warn: 'orange',
  issues: 'red',
};

function getComplianceLevel(compliance) {
  if (compliance > 0.9) {
    return 'compliant';
  }
  if (compliance > 0.6) {
    return 'warn';
  }
  return 'issues';
}

export function toEventTimeSpans(events) {
  return events.map(event => {
    const data = {
      event: event.event,
      spans: event.spans,
      compliance: event.compliance,
      level: getComplianceLevel(event.compliance),
      details: event.details,
    };

    return toTimeSpan(event.startTime, event.endTime, null, 'event', null, data);
  });
}

export function eventStyle(eventSpan, region) {
  const fill = COLORS[eventSpan.data.level] || MISSING_COLOR;
  const strokeWidth = region === 'focus' ? 0.5 : 0;
  const opacity = region === 'focus' ? 0.75 : 0.25;

  return {
    fill,
    opacity,
    strokeWidth,
  };
}
