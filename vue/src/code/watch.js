function normalizeMap(map) {
  return Array.isArray(map)
    ? map.map(key => ({ key, val: key }))
    : Object.keys(map).map(key => ({ key, val: map[key] }));
}

// https://github.com/vuejs/vuex/blob/dev/src/helpers.js
export const mapWatch = watchers => {
  const res = {};
  normalizeMap(watchers).forEach(({ key, val }) => {
    res[key] = function mappedWatcher(newVal, oldVal) {
      return val(this, newVal, oldVal);
    };
  });
  return res;
};

export const forEachWatch = (keys, action) => {
  const res = {};
  keys.forEach(key => {
    res[key] = function mappedWatcher(newVal, oldVal) {
      return action(this, key, newVal, oldVal);
    };
  });
  return res;
};
