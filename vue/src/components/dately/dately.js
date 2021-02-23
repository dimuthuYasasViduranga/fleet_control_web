import { chunkEvery } from '@/code/helpers';
import { setTimeZone } from '@/code/time';

function filledArry(count, content) {
  const arr = [];
  for (let i = 0; i < count; i++) {
    arr.push(content);
  }
  return arr;
}

export function getDatesOfMonth(year, month) {
  const startMonth = month - 1;
  const date = new Date(year, month - 1, 1);
  const days = [];
  while (date.getMonth() === startMonth) {
    days.push({
      year,
      month,
      day: date.getDate(),
      dayOfWeek: date.getDay(),
    });
    date.setDate(date.getDate() + 1);
  }
  return days;
}

export function alignDatesOfMonth(dates) {
  const startingOffset = dates[0].dayOfWeek;
  const endingOffset = 42 - startingOffset - dates.length;
  const alignedDates = filledArry(startingOffset, {})
    .concat(dates)
    .concat(filledArry(endingOffset, {}));
  return chunkEvery(alignedDates, 7, 7);
}

export function extrapolateTimeFromString(value) {
  const timeStr = value.replace('.', ':');
  if (!timeStr) {
    return '';
  }

  // if only numbers
  if (isOnlyNumbers(timeStr)) {
    return extrapolateTimeFromNumbers(timeStr);
  }

  // if formatted
  if (timeStr.includes(':')) {
    return extrapolateTimeFromFormattedTime(timeStr);
  }

  return timeStr;
}

function isOnlyNumbers(value) {
  return /^\d+$/.test(value);
}

export function isValidTime(value) {
  // 'ab:cd:ef' where ab < 24, cd < 60, ef < 60
  return /(0\d|1\d|2[0-3]):([0-5]\d):([0-5]\d)/.test(value);
}

function extrapolateTimeFromNumbers(numbers) {
  const MAX_NUMBERS = 6;
  let numberString = `${numbers}`;

  const totalLength = numberString.length;
  if (totalLength > MAX_NUMBERS) {
    return numberString;
  }

  if (totalLength < MAX_NUMBERS) {
    numberString = `${numberString}${'0'.repeat(MAX_NUMBERS - totalLength)}`;
  }

  // attempt to format (could have started with something > 2)
  const formattedTime = chunkEvery(numberString, 2, 2).join(':');

  if (!isValidTime(formattedTime)) {
    // first parse invalud, try with leading zero (and no ending number)
    const trialString = `0${numberString.slice(0, 5)}`;
    const trailFormatted = chunkEvery(trialString, 2, 2).join(':');
    if (isValidTime(trailFormatted)) {
      return trailFormatted;
    }
  }

  return formattedTime;
}

function extrapolateTimeFromFormattedTime(formattedTime) {
  let chunks = formattedTime.split(':').map(chunk => {
    const chunkLength = chunk.length;
    const padding = chunkLength < 2 ? 2 - chunkLength : 0;

    return `${'0'.repeat(padding)}${chunk}`;
  });

  if (chunks.some(chunk => chunk.length > 2)) {
    return formattedTime;
  }

  const nChunks = chunks.length;
  if (nChunks > 3) {
    return formattedTime;
  }
  if (nChunks < 3) {
    chunks = chunks.concat(Array(3 - nChunks).fill(['00']));
  }
  return chunks.join(':');
}

export function deconstructDate(date, timezone = 'local') {
  if (!date) {
    return null;
  }
  // the returned object is for the given time zone
  return setTimeZone(date, timezone).toObject();
}

export function dayLessThan(day, date, timezone) {
  if (!date) {
    return false;
  }

  const dateAsObj = setTimeZone(date, timezone).toObject();

  return day.year <= dateAsObj.year && day.month <= dateAsObj.month && day.day < dateAsObj.day;
}

export function dayGreaterThan(day, date, timezone) {
  if (!date) {
    return false;
  }

  const dateAsObj = setTimeZone(date, timezone);

  return day.year >= dateAsObj.year && day.month >= dateAsObj.month && day.day > dateAsObj.day;
}

export function dateInRange(minDate, maxDate, timezone) {
  const now = Date.now();
  if (!minDate && !maxDate) {
    return setTimeZone(new Date(now), timezone);
  }

  if (minDate && now < minDate.getTime()) {
    return setTimeZone(new Date(minDate), timezone);
  }

  if (maxDate && now > maxDate.getTime()) {
    return setTimeZone(new Date(maxDate), timezone);
  }

  return setTimeZone(new Date(now), timezone);
}