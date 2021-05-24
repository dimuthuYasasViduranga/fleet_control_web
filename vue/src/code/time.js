import Vue from 'vue';
import { DateTime } from 'luxon';

export function formatDateIn(date, tz, opts) {
  const { timezone, format } = {
    format: 'yyyy-LL-dd HH:mm:ss',
    timezone: tz || 'local',
    ...(opts || {}),
  };

  if (!date) {
    return null;
  }

  const lux = DateTime.fromJSDate(new Date(date));
  const inZone = setTimeZone(lux, timezone);
  return inZone.toFormat(format);
}

export function setTimeZone(datetime, timezone) {
  if (!DateTime.isDateTime(datetime)) {
    return setTimeZone(fromJSDate(datetime), timezone);
  }
  if (!timezone) {
    return datetime;
  }
  return datetime.setZone(timezone);
}

export function formatDateRelativeToIn(date, tz, now = new Date()) {
  if (!date) {
    return null;
  }

  if (isSameDownTo(date, now, tz, 'day')) {
    return formatDateIn(date, tz, { format: 'HH:mm:ss' });
  }
  return formatDateIn(date, tz, { format: '(LLL-dd) HH:mm:ss' });
}

export function isSameDownTo(date1, date2, timezone, unit) {
  if (!date1 || !date2) {
    return false;
  }
  const lux1 = setTimeZone(date1, timezone);
  const lux2 = setTimeZone(date2, timezone);
  return lux1.hasSame(lux2, unit);
}

export function fromJSDate(date) {
  return DateTime.fromJSDate(date);
}

/* -------------------- */
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
  return date ? new Date(date) : null;
}

export function addJsDate(date, durationMs) {
  if (!date) {
    return null;
  }

  return new Date(date.getTime() + durationMs);
}

export function isDateEqual(a, b) {
  if (!a && !b) {
    return true;
  }

  if (!a || !b) {
    return false;
  }

  return a.getTime() === b.getTime();
}

export function toHHMM(date) {
  const hours = pad(date.getHours());
  const minutes = pad(date.getMinutes());
  return `${hours}:${minutes}`;
}

export function pad(number) {
  return number < 10 ? `0${number}` : `${number}`;
}

// 'HH:mm:ss' or '(MMM-dd) HH:mm:ss'
export function todayRelativeFormat(datetime) {
  let date = new Date(datetime);
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const hhmmss = date.toLocaleString(undefined, {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });

  // if it is on a previous date
  if (startOfToday.getTime() - date.getTime() > 0) {
    const prefix = date
      .toLocaleString(undefined, {
        month: 'short',
        day: '2-digit',
      })
      .replace(' ', '-');

    return `(${prefix}) ${hhmmss}`;
  }

  return hhmmss;
}

export function formatSeconds(totalSeconds, format = '%HH:%MM:%SS') {
  const sign = totalSeconds < 0 ? '-' : '';
  totalSeconds = Math.abs(totalSeconds);

  // calculate the components
  const [hours, hRemSeconds] = divMod(totalSeconds, 3600);
  let [minutes, seconds] = divMod(hRemSeconds, 60);
  seconds = Math.trunc(seconds);
  // parse the format
  return `${sign}${format}`
    .replace('%HH', pad(hours))
    .replace('%H', hours)
    .replace('%MM', pad(minutes))
    .replace('%M', minutes)
    .replace('%SS', pad(seconds))
    .replace('%S', seconds);
}

export function formatSecondsRelative(totalSeconds) {
  const [hours, hRemSeconds] = divMod(totalSeconds, 3600);
  let [minutes, seconds] = divMod(hRemSeconds, 60);
  seconds = Math.trunc(seconds);

  if (hours > 1) {
    return `${hours} hours ago`;
  }

  if (hours === 1) {
    return `1 hour ago`;
  }

  if (minutes > 1) {
    return `${minutes} minutes ago`;
  }

  if (minutes === 1) {
    return '1 minute ago';
  }

  if (seconds === 1) {
    return `1 second ago`;
  }

  return `${seconds} seconds ago`;
}

export function divMod(dividend, divisor) {
  const div = Math.floor(dividend / divisor);
  const mod = dividend % divisor;
  return [div, mod];
}

export function formatDate(date, format = '%d-%m-%Y %HH:%MM:%SS') {
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

export function formatDateUTC(date, format = '%d-%m-%Y %HH:%MM:%SS') {
  if (!date) {
    return null;
  }
  return format
    .replace('%d', pad(date.getUTCDate()))
    .replace('%m', pad(date.getUTCMonth() + 1))
    .replace('%Y', pad(date.getUTCFullYear()))
    .replace('%y', `${date.getUTCFullYear()}`.slice(2))
    .replace('%HH', pad(date.getUTCHours()))
    .replace('%H', date.getUTCHours())
    .replace('%MM', pad(date.getUTCMinutes()))
    .replace('%M', date.getUTCMinutes())
    .replace('%SS', pad(date.getUTCSeconds()))
    .replace('%S', date.getUTCSeconds())
    .replace('%b', date.toLocaleString('default', { month: 'short', timeZone: 'UTC' }));
}

export class Now {
  constructor(period = 1000) {
    this.timestamp = Date.now();
    this.start(period);
  }

  start(period) {
    this._interval = setInterval(() => {
      this.timestamp = Date.now();
    }, period);
  }

  stop() {
    this._interval = clearInterval(this._interval);
  }
}

export function nowTimer(period) {
  return Vue.observable(new Now(period));
}
