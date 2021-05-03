export function attributeFromList(items, matchKey, matchValue, retKey) {
  const item = items.find(i => i[matchKey] === matchValue);
  if (retKey === undefined) {
    return item;
  }

  if (Array.isArray(retKey)) {
    if (!item) {
      return Array(retKey.length).fill(undefined);
    }
    return retKey.map(key => item[key]);
  }

  return item === undefined ? undefined : item[retKey];
}

export function copy(obj) {
  return JSON.parse(JSON.stringify(obj));
}

export function formatDeviceUUID(uuid) {
  return chunkStr(uuid.toUpperCase(), 4).join('-');
}

function chunkStr(str, size) {
  if (size <= 0) {
    return [str];
  }

  const arr = Array.from(str);
  const chunks = chunk(arr, size);
  return chunks.map(c => c.join(''));
}

function chunk(arr, size) {
  const maxLen = arr.length;
  const repeats = Math.ceil(maxLen / size);
  const ranges = [];
  for (let i = 0; i < repeats; i++) {
    const start = i * size;
    const end = start + size;
    ranges.push([start, end]);
  }

  const chunks = ranges.map(([start, end]) => arr.slice(start, end));
  return chunks;
}

export function filterLocations(locations, allLocations, id, showAll) {
  if (!id) {
    if (showAll) {
      return allLocations;
    }
    return locations;
  }

  if (showAll) {
    return allLocations;
  }

  // check if the location is in the given set, else, add it from all locations
  if (locations.find(e => e.id === id)) {
    return locations;
  }

  // Otherwise, add the extra to the given list
  const extra = allLocations.find(e => e.id === id);
  if (extra) {
    return [extra].concat(locations);
  }
  return locations.slice();
}

export function toFullName(name, nickname) {
  if (nickname) {
    return `${name} (${nickname})`;
  }
  return name;
}

export function getOperatorNames(operators, id) {
  const operator = attributeFromList(operators, 'id', id);
  if (!operator) {
    return {};
  }

  const name = operator.name;
  const nickname = operator.nickname;
  const fullname = toFullName(name, nickname);

  return { name, nickname, fullname };
}

export function isInText(source, text) {
  return (source || '').toLowerCase().indexOf((text || '').toLowerCase()) > -1;
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

export function dedupBy(list, key) {
  const deduped = [];
  let match = undefined;

  list.forEach(element => {
    if (element[key] !== match) {
      deduped.push(element);
      match = element[key];
    }
  });

  return deduped;
}

export function dedupByMany(list, keys) {
  const deduped = [];
  let match = {};

  list.forEach(element => {
    if (keys.some(key => match[key] !== element[key])) {
      deduped.push(element);
      match = element;
    }
  });

  return deduped;
}

/**
 * Returns a map of {key => element | element[valKey]}
 * @param {Array} list - array to group
 * @param {String} key - key to group on
 * @param {String} valKey - key to group. default null (all keys)
 * @returns {Object}
 */
export function groupBy(list, key, valKey = null) {
  return list.reduce((group, element) => {
    const value = valKey ? element[valKey] : element;
    const matchKey = nestedGet(element, key);
    (group[matchKey] = group[matchKey] || []).push(value);
    return group;
  }, {});
}

export function nestedGet(obj, keys) {
  const accessors = Array.isArray(keys) ? keys : [keys];
  return accessors.reduce((acc, key) => (acc && acc[key] ? acc[key] : null), obj);
}

/**
 * Returns a sorted list based on the key given
 * @param {Array} list - array of objects
 * @param {String} key - string of a Date attribute
 */
export function sortByTime(list, key) {
  const toSort = list.slice();
  toSort.sort((a, b) => a[key].getTime() - b[key].getTime());
  return toSort;
}

export function uniq(list) {
  return [...new Set(list)];
}

export function hasOrderedSubArray(arr, subarr) {
  const arrLength = arr.length;
  const subLength = subarr.length;
  if (subLength > arrLength) {
    return false;
  }

  const maxStartIndex = arrLength - subLength;

  for (let i = 0; i <= maxStartIndex; i++) {
    if (equalFrom(arr, subarr, i)) {
      return true;
    }
  }

  return false;
}

function equalFrom(arr, subarr, offset) {
  const length = subarr.length;
  for (let i = 0; i < length; i++) {
    if (subarr[i] !== arr[i + offset]) {
      return false;
    }
  }

  return true;
}

export class Dictionary {
  constructor(hasher = JSON.stringify) {
    this._entries = {};
    this._hasher = hasher;
  }

  get(keys) {
    return (this._entries[this._hasher(keys)] || {}).value;
  }

  add(keys, value, onConflict = (n, o) => n) {
    const accessor = this._hasher(keys);
    const existing = this._entries[accessor];
    if (existing) {
      this._entries[accessor].value = onConflict(value, existing.value);
    } else {
      this._entries[accessor] = { keys, value };
    }
  }

  append(keys, value) {
    const accessor = this._hasher(keys);
    const existing = this._entries[accessor];
    if (existing) {
      this._entries[accessor].value.push(value);
    } else {
      this._entries[accessor] = { keys, value: [value] };
    }
  }

  remove(keys) {
    delete this._entries[this._hasher(keys)];
  }

  has(keys) {
    return !!this._entries[this._hasher(keys)];
  }

  forEach(predicate = (ks, v) => null) {
    Object.values(this._entries).forEach(data => predicate(data.keys, data.value));
  }

  map(predicate = (ks, v) => null) {
    return Object.values(this._entries).map(data => predicate(data.keys, data.value));
  }

  reduce(predicate = (acc, ks, v) => null, init) {
    return Object.values(this._entries).reduce((acc, data) => predicate(acc, data.keys, data.value), init)
  }
}
