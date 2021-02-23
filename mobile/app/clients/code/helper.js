export function attributeFromList(items, matchKey, matchValue, retKey) {
  const item = items.find(i => i[matchKey] === matchValue);
  if (retKey === undefined) {
    return item;
  }
  return item === undefined ? undefined : item[retKey];
}

export function toUtcDate(validDate) {
  if (!validDate) {
    return null;
  }

  if (typeof validDate === 'string') {
    return validDate.includes('Z') ? new Date(validDate) : new Date(`${validDate}Z`);
  }

  return new Date(validDate);
}

export function copyDate(date) {
  if (!date) {
    return null;
  }

  return new Date(date);
}

export function chunkEvery(list, count, step, leftOver = []) {
  const stepSize = step || count;
  const listOut = [];
  for (let i = 0; i < list.length; i += stepSize) {
    let chunk = list.slice(i, i + count);

    if (chunk.length < count) {
      if (leftOver === 'discard') {
        continue;
      }
      chunk = chunk.concat(leftOver);
    }

    listOut.push(chunk);
  }
  return listOut;
}

export function formatDeviceUUID(uuid) {
  if (!uuid) {
    return '';
  }

  const uuidChunks = chunkUUID(`${uuid}`.split(''), 4);
  return uuidChunks.map(c => c.join('')).join('-');
}

function chunkUUID(arr, size) {
  const maxLen = arr.length;
  const repeats = Math.ceil(maxLen / size);
  const ranges = [];
  for (let i = 0; i < repeats; i++) {
    const start = i * size;
    const end = start + size;
    ranges.push([start, end]);
  }

  return ranges.map(([start, end]) => arr.slice(start, end));
}

export function sortInPlaceByTime(list, key, direction = 'asc') {
  if (direction === 'asc') {
    return list.sort((a, b) => b[key].getTime() - a[key].getTime());
  }
  return list.sort((a, b) => a[key].getTime() - b[key].getTime());
}

export function pad(number) {
  return number < 10 ? `0${number}` : `${number}`;
}

export function formatDate(date, format = '%Y-%m-%d %HH:%MM:%SS') {
  if (!date) {
    return null;
  }
  return format
    .replace('%d', pad(date.getDate()))
    .replace('%m', pad(date.getMonth() + 1))
    .replace('%Y', pad(date.getFullYear()))
    .replace('%y', `${date.getFullYear()}`.slice(2))
    .replace('%HH', pad(date.getHours()))
    .replace('%H', date.getHours())
    .replace('%MM', pad(date.getMinutes()))
    .replace('%M', date.getMinutes())
    .replace('%SS', pad(date.getSeconds()))
    .replace('%S', date.getSeconds())
    .replace('%b', date.toLocaleString('default', { month: 'short' }));
}

export function formatSeconds(totalSeconds, format = '%HH:%MM:%SS') {
  const sign = totalSeconds < 0 ? '-' : '';
  totalSeconds = Math.abs(totalSeconds);

  // calculate the components
  const [hours, hRemSeconds] = divMod(totalSeconds, 3600);
  const [minutes, seconds] = divMod(hRemSeconds, 60);
  // parse the format
  return `${sign}${format}`
    .replace('%R', getLargestRelative(hours, minutes, seconds))
    .replace('%HH', pad(hours))
    .replace('%H', hours)
    .replace('%MM', pad(minutes))
    .replace('%M', minutes)
    .replace('%SS', pad(seconds))
    .replace('%S', seconds);
}

function getLargestRelative(hours, minutes, seconds) {
  const options = [
    [Math.trunc(hours), 'hour'],
    [Math.trunc(minutes), 'minute'],
    [Math.trunc(seconds), 'second'],
  ];
  for (const [value, singular] of options) {
    if (value === 1) {
      return `${value} ${singular} ago`;
    }
    if (value > 1) {
      return `${value} ${singular}s ago`;
    }
  }
}

export function toPlural(value, unit, suffix, extra = '') {
  if (value === 1) {
    return `${value} ${unit}${extra}`;
  }
  return `${value} ${unit}${suffix}${extra}`;
}

export function divMod(dividend, divisor) {
  const div = Math.floor(dividend / divisor);
  const mod = dividend % divisor;
  return [div, mod];
}

export function isSameDay(date1, date2) {
  if (!date1 || !date2) {
    return false;
  }

  return (
    date1.getDate() === date2.getDate() &&
    date1.getMonth() === date2.getMonth() &&
    date1.getFullYear() === date2.getFullYear()
  );
}

export function todayRelativeFormat(date, now = new Date()) {
  if (!date) {
    return null;
  }

  if (isSameDay(date, now)) {
    return formatDate(date, '%HH:%MM:%SS');
  }

  return formatDate(date, '(%d-%b) %HH:%MM:%SS');
}

export function isInText(source, text) {
  return (source || '').toLowerCase().indexOf((text || '').toLowerCase()) > -1;
}

export function isEqualDate(a, b) {
  if (a == null || b == null) {
    return a == b;
  }

  return a.getTime() == b.getTime();
}

export function uniq(list) {
  return [...new Set(list)];
}
