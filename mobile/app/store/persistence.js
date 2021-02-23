import * as ApplicationSettings from 'application-settings';
import { SecureStorage } from 'nativescript-secure-storage';
const secureStorage = new SecureStorage();

export function addDiskKeys(state, keys) {
  Object.values(keys).forEach(item => {
    state[item.key] = retrieve(item);
  });
}

export function clearKeys(state, diskKeys) {
  diskKeys
    .filter(item => item.clearable !== false)
    .forEach(item => {
      remove(item);
      state[item.key] = item.default;
    });
}

export function simplePersist(key, data) {
  ApplicationSettings.setString(key, JSON.stringify(data || null));
}

export function securePersist(key, data) {
  secureStorage.setSync({ key, value: JSON.stringify(data || null) });
}

export function persist(config, data) {
  const persistMode = config.secure ? securePersist : simplePersist;
  persistMode(config.diskKey, data);
}

export function persistAndSet(state, config, data) {
  persist(config, data);
  state[config.key] = data;
}

export function simpleRemove(key) {
  ApplicationSettings.remove(key);
}

export function secureRemove(key) {
  secureStorage.removeSync({ key });
}

export function remove(config) {
  const removeMode = config.secure ? secureRemove : simpleRemove;
  removeMode(config.diskKey);
}

export function simpleRetrieve(key, defaultReturn = null, parser = i => i) {
  const stored = JSON.parse(ApplicationSettings.getString(key) || null);
  if (Array.isArray(stored)) {
    return stored.map(parser);
  }
  return parser(stored) || defaultReturn;
}

export function secureRetrieve(key, defaultReturn = null, parser = i => i) {
  const stored = JSON.parse(secureStorage.getSync({ key }));
  if (Array.isArray(stored)) {
    return stored.map(parser);
  }
  return parser(stored) || defaultReturn;
}

export function retrieve(config) {
  const retrieveMode = config.secure ? secureRetrieve : simpleRetrieve;
  return retrieveMode(config.diskKey, config.default, config.parser);
}
