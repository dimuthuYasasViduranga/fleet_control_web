import { copyDate } from '../../../code/time';

export function toTimeSpan(
  startTime,
  endTime,
  activeEndTime,
  group = 'group',
  level = 0,
  data = {},
) {
  return {
    startTime: copyDate(startTime),
    endTime: copyDate(endTime),
    activeEndTime: copyDate(activeEndTime),
    group,
    level,
    data,
  };
}

export function copyTimeSpan(timeSpan) {
  return {
    ...timeSpan,
    startTime: copyDate(timeSpan.startTime),
    endTime: copyDate(timeSpan.endTime),
    activeEndTime: copyDate(timeSpan.activeEndTime),
    data: { ...timeSpan.data },
  };
}

export function isOverlapping(a, b) {
  return coverage(a, b) !== 'no-overlap';
}

/**
 * Returns a list of timespans that overlap the target
 * @param {Object} timeSpan - target span
 * @param {Object} timeSpans - spans to check target against
 */
export function findOverlapping(targetTimeSpan, timeSpans) {
  return timeSpans.reduce((acc, checkAgainst) => {
    if (isOverlapping(checkAgainst, targetTimeSpan)) {
      acc.push(checkAgainst);
    }
    return acc;
  }, []);
}

/**
 * Returns a NEW list
 * @param {Object} timeSpans - a list of timeSpans to sort
 */
export function sortTimeSpansAscending(timeSpans) {
  const toSort = timeSpans.slice();
  toSort.sort(
    (a, b) => a.startTime.getTime() - b.startTime.getTime() || (a.data.id || 0) - (b.data.id || 0),
  );
  return toSort;
}

/**
 * Returns a 'x' b
 * where x can be:
 *  - 'covers'       -> a completely covers b (a.start <= b.start && a.end >= b.end)
 *  - 'within'       -> a is within b (a.start > b.start && a.end < b.end)
 *  - 'end-within'   -> a.endTime is within b
 *  - 'start-within' -> a.startTime is within b
 *  - 'no-overlap'   -> a and b have no overlap
 * @param {Object} a - timeSpan
 * @param {Object} b - timeSpan
 */
export function coverage(a, b) {
  const aStart = a.startTime.getTime();
  const aEnd = (a.endTime || a.activeEndTime).getTime();
  const bStart = b.startTime.getTime();
  const bEnd = (b.endTime || b.activeEndTime).getTime();

  // if a completely covers b (covers)
  if (aStart <= bStart && aEnd >= bEnd) {
    return 'covers';
  }

  // if a is completely within b (within)
  if (aStart > bStart && aEnd < bEnd) {
    return 'within';
  }

  // if a end is within b (end-within)
  if (aEnd > bStart && aEnd < bEnd) {
    return 'end-within';
  }

  // if a start is within b (start-within)
  if (aStart > bStart && aStart < bEnd) {
    return 'start-within';
  }

  return 'no-overlap';
}

/**
 * Returns a new list (and new timeSpans) of timeSpans where the levels
 * are calculated based on overlapping elements in order of startTime.
 *
 * Any invalid timeSpans are returned separately
 *
 * Attempts are made to minimise the number of levels, but certain elements
 * naturally cause higher stacks
 *
 * existing {data} component is mutable
 * @param {Array} timeSpans - a list of timeSpans
 */
export function addDynamicLevels(timeSpans, allowDeleted = true) {
  const timeSpansAsc = sortTimeSpansAscending(timeSpans).map(copyTimeSpan);

  // yes this could be a reduce, but having the acc at the bottom is hard to read
  const levels = [[]];
  const [validTimeSpans, invalidTimeSpans] = splitValidTimeSpans(timeSpansAsc, allowDeleted);
  validTimeSpans.forEach(ts => {
    ts.isOverlapping = false;

    // Added prevents adding to multiple levels
    let added = false;
    for (let i = 0; i < levels.length; i++) {
      const level = levels[i];
      const overlaps = findOverlapping(ts, level);
      const hasOverlap = overlaps.length !== 0;

      if (hasOverlap) {
        // set this element as overlapping, as well as overlaps
        ts.isOverlapping = true;
        overlaps.forEach(o => (o.isOverlapping = true));
      } else if (!added) {
        added = true;
        ts.level = i;
        level.push(ts);
      }
    }

    // if no valid level, add a new one
    if (!added) {
      ts.level = levels.length;
      levels.push([ts]);
    }
  });

  return [validTimeSpans, invalidTimeSpans];
}

function splitValidTimeSpans(timeSpans, allowDeleted = true) {
  const valid = [];
  const invalid = [];

  timeSpans.forEach(ts => {
    if (!allowDeleted && (ts.deleted || ts.data.deleted)) {
      invalid.push(ts);
    } else if (ts.startTime && (ts.endTime || ts.activeEndTime)) {
      const startTime = ts.startTime.getTime();
      const endTime = (ts.endTime || ts.activeEndTime).getTime();

      if (startTime >= endTime) {
        invalid.push(ts);
      } else {
        valid.push(ts);
      }
    } else {
      invalid.push(ts);
    }
  });

  return [valid, invalid];
}

/**
 * Return a list of timespans as a result of the overriding 'overridee' within
 * 'overrider'
 * Returned timeSpans are copies (bar the data property) with their levels removed
 *
 * @param {Object} overrider - timespan to override with
 * @param {Object} overridee - timespan to be overriden
 */
export function override(overrider, overridee) {
  const overriderC = copyTimeSpan(overrider);
  const overrideeC = copyTimeSpan(overridee);

  overriderC.level = null;
  overrideeC.level = null;

  switch (coverage(overriderC, overrideeC)) {
    case 'covers':
      overrideeC.deleted = true;
      return [overriderC, overrideeC];

    case 'within':
      const start = copyTimeSpan(overrideeC);
      const middle = overriderC;
      const end = copyTimeSpan(overrideeC);

      start.endTime = copyDate(middle.startTime);
      start.activeEndTime = null;
      end.startTime = copyDate(middle.endTime || middle.activeEndTime);

      return [start, middle, end];

    case 'start-within':
      overrideeC.endTime = copyDate(overriderC.startTime);
      overrideeC.activeEndTime = null;
      return [overriderC, overrideeC];

    case 'end-within':
      overrideeC.startTime = copyDate(overriderC.endTime || overriderC.activeEndTime);
      return [overriderC, overrideeC];

    default:
      return [overriderC, overrideeC];
  }
}

/**
 * Return the result of overriding all overridees with overrider, but
 * the result will only have 1 'overrider' present
 * @param {Object} overrider - timeSpan to override with
 * @param {Array} overridees - timeSpans to be overriden
 */
export function overrideAll(overrider, overridees) {
  const overriderC = copyTimeSpan(overrider);
  overriderC._isOverrider = true;
  const results = overridees
    .map(oee => override(overriderC, oee))
    .flat()
    .filter(ts => !ts._isOverrider);

  delete overriderC._isOverrider;

  results.push(overriderC);
  return results;
}

/**
 * Conditional overriding based on the overrideOverCallback.
 * This is useful for overriding when elements can have priority
 * ie (2 can override 3 but not 1)
 *
 * Levels are removed
 *
 * @param {Object} merger - timeSpan to be merged
 * @param {Object} mergee - timeSpan to be merged with
 * @param {Function} overrideOrderCallback - (merger, mergee) returns the override order
 * default: (overrider: merger, overridee: mergee)
 */
export function merge(
  merger,
  mergee,
  overrideOrderCallback = (merger, mergee) => [merger, mergee],
) {
  const mergerC = copyTimeSpan(merger);
  const mergeeC = copyTimeSpan(mergee);

  const [overrider, overridee] = overrideOrderCallback(mergerC, mergeeC);

  return override(overrider, overridee);
}

/**
 * Merge the given 'merger' against all 'mergees'. Each iteration uses the updated 'mergee' and will
 * short circuit should it become deleted
 *
 * Levels are removed
 *
 * Without a custom merge function mergeAll == overrideAll
 *
 * Merges are done based on the oder of mergees are provided
 * @param {Object} merger - timeSpan to be merged
 * @param {Array} mergees - timeSpans to be merged into
 * @param {Function} overrideOrderCallback - (merger, mergee) returns the override order
 * default: (overrider: merger, overridee: mergee)
 */
export function mergeAll(
  merger,
  mergees,
  overrideOrderCallback = (merger, mergee) => [merger, mergee],
) {
  // index is added to help find the merger during overrides
  let mergerC = copyTimeSpan(merger);
  mergerC._index = 1;

  const merges = mergees
    .map(mergee => {
      const mergeeC = copyTimeSpan(mergee);

      if (mergerC.deleted == true) {
        return [mergeeC];
      }

      // determine which element has presedent to merge with the other
      const [overrider, overridee] = overrideOrderCallback(mergerC, mergeeC);

      const [updatedMerger, updatedMerges] = separateOverrider(override(overrider, overridee));

      mergerC = updatedMerger;
      return updatedMerges;
    })
    .flat();

  delete mergerC._index;

  merges.push(mergerC);
  return merges;
}

function separateOverrider(timeSpans) {
  let overrider = null;
  const overridees = [];

  timeSpans.forEach(ts => {
    if (ts._index) {
      overrider = ts;
    } else {
      overridees.push(ts);
    }
  });

  return [overrider, overridees];
}
