import { attributeFromList, toUtcDate } from '../../clients/code/helper';

import { addDiskKeys, clearKeys, persistAndSet } from '../persistence.js';

const DISK_KEYS = {
  assets: { key: 'assets', diskKey: 'C:Assets', default: [] },
  assetTypes: { key: 'assetTypes', diskKey: 'C:Asset Types', default: [] },
  operators: { key: 'operators', diskKey: 'C:Operators', default: [], secure: true },
  locations: { key: 'locations', diskKey: 'C:Locations', default: [] },
  timeCodes: { key: 'timeCodes', diskKey: 'C:Time Codes', default: [] },
  timeCodeGroups: { key: 'timeCodeGroups', diskKey: 'C:Time Code Groups', default: [] },
  timeCodeElements: { key: 'timeCodeTreeElements', diskKey: 'C:Time Code Elements', default: [] },
  clusters: { key: 'clusters', diskKey: 'C:Clusters', default: {} },
  materialTypes: { key: 'materialTypes', diskKey: 'C:Material Types', default: [] },
  loadStyles: { key: 'loadStyles', diskKey: 'C:Load Styles', default: [] },
  assetRadios: { key: 'assetRadios', diskKey: 'C:Asset Radios', default: [] },
  preStarts: { key: 'preStarts', diskKey: 'C:Pre-Starts', default: [], parser: parseDiskPreStart },
};

function parseDiskPreStart(data) {
  if (!data) {
    return null;
  }
  data.timestamp = toUtcDate(data.timestamp);
  data.serverTimestamp = toUtcDate(data.serverTimestamp);
  return data;
}

export function parseOperatorMessageType(type) {
  return {
    id: type.id,
    name: type.name,
  };
}

function parseOperatorMessageTypeTree(element) {
  return {
    id: element.id,
    assetTypeId: element.asset_type_id,
    messageTypeId: element.message_type_id,
    order: element.order,
  };
}

export function parseAsset(asset) {
  if (!asset) {
    return null;
  }

  return {
    id: asset.id,
    name: asset.name,
    typeId: asset.type_id,
    type: asset.type,
    secondaryType: asset.secondary_type,
  };
}

function parseAssetType(type) {
  return {
    id: type.id,
    type: type.type,
    secondary: type.secondary,
  };
}

export function parseOperator(operator) {
  if (!operator) {
    return null;
  }

  const fullname = getFullName(operator.name, operator.nickname);
  const shortname = operator.nickname || operator.name;

  return {
    id: operator.id,
    employeeId: operator.employee_id,
    name: operator.name,
    nickname: operator.nickname,
    fullname,
    shortname,
  };
}

function getFullName(name, nickname) {
  return nickname ? `${name} (${nickname})` : name;
}

function parseLocation(location) {
  const geofence = location.geofence ? parseGeofence(location.geofence) : null;
  return {
    id: location.location_id,
    name: location.name,
    typeId: location.location_type_id,
    type: location.type,
    historyId: location.history_id,
    timestamp: location.timestamp,
    geofence,
  };
}

function parseGeofence(geofenceString) {
  return geofenceString.split('|').map(coord => {
    const [lat, lng] = coord.split(',');
    return {
      lat: parseFloat(lat),
      lng: parseFloat(lng),
    };
  });
}

function parseTimeCode(timeCode) {
  return {
    id: timeCode.id,
    code: timeCode.code,
    name: timeCode.name,
    groupId: timeCode.group_id,
  };
}

function parseTimeCodeGroup(group) {
  return {
    id: group.id,
    name: group.name,
    alias: group.alias,
    siteName: group.alias || group.name,
  };
}

function parseTimeCodeTreeElement(element) {
  return {
    id: element.id,
    assetTypeId: element.asset_type_id,
    name: element.node_name,
    parentId: element.parent_id,
    timeCodeGroupId: element.time_code_group_id,
    timeCodeId: element.time_code_id,
  };
}

function toFullTimeCode(timeCode, timeCodeGroups) {
  const groupName = attributeFromList(timeCodeGroups, 'id', timeCode.groupId, 'name');
  const isReady = groupName === 'Ready';
  return {
    id: timeCode.id,
    code: timeCode.code,
    name: timeCode.name,
    groupId: timeCode.groupId,
    groupName,
    isReady,
  };
}

function parseMaterialType(type) {
  return {
    id: type.id,
    name: type.name,
    commonName: type.common_name,
  };
}

function parseLoadStyle(style) {
  return {
    id: style.id,
    assetTypeId: style.asset_type_id,
    assetType: style.asset_type,
    style: style.style,
  };
}

function parseAssetRadio(radio) {
  return {
    id: radio.id,
    assetId: radio.asset_id,
    radioNumber: radio.radio_number,
  };
}

function parseCluster(cluster) {
  return {
    id: cluster.id,
    position: {
      lat: cluster.lat,
      lng: cluster.lon,
    },
    locationId: cluster.location_id,
  };
}

function parsePreStart(form) {
  if (!form) {
    return null;
  }
  return {
    id: form.id,
    assetTypeId: form.asset_type_id,
    dispatcherId: form.dispatcher_id,
    sections: form.sections.map(parsePreStartSection),
    timestamp: toUtcDate(form.timestamp),
    serverTimestmap: toUtcDate(form.server_timestamp),
  };
}

function parsePreStartSection(section) {
  return {
    id: section.id,
    formId: section.formId,
    order: section.order,
    title: section.title,
    details: section.details,
    controls: section.controls.map(parsePreStartControl),
  };
}

function parsePreStartControl(control) {
  return {
    id: control.id,
    sectionId: control.sectionId,
    order: control.order,
    label: control.label,
  };
}

/* --------------------- module -----------------*/
const state = {
  assets: Array(),
  assetTypes: Array(),
  operators: Array(),
  locations: Array(),
  timeCodes: Array(),
  timeCodeGroups: Array(),
  timeCodeTreeElements: Array(),
  operatorMessageTypes: Array(),
  operatorMessageTypeTree: Array(),
  clusters: Object(),
  materialTypes: Array(),
  loadStyles: Array(),
  assetRadios: Array(),
  preStarts: Array(),
};

addDiskKeys(state, DISK_KEYS);

const getters = {
  fullTimeCodes: state => state.timeCodes.map(tc => toFullTimeCode(tc, state.timeCodeGroups)),
};

const actions = {
  setAssets({ commit }, assets = []) {
    const formattedAssets = assets.map(parseAsset);
    commit('setAssets', formattedAssets);
  },
  setAssetTypes({ commit }, assetTypes = []) {
    const formattedAssetTypes = assetTypes.map(parseAssetType);
    commit('setAssetTypes', formattedAssetTypes);
  },
  setOperators({ commit }, operators = []) {
    const formattedOperators = operators.map(parseOperator);
    commit('setOperators', formattedOperators);
  },
  setLocations({ commit }, locations = []) {
    const formattedLocations = locations.map(parseLocation);
    formattedLocations.sort((a, b) => a.name.localeCompare(b.name));
    commit('setLocations', formattedLocations);
  },
  setTimeCodes({ commit }, timeCodes = []) {
    const formattedTimeCodes = timeCodes.map(parseTimeCode);
    commit('setTimeCodes', formattedTimeCodes);
  },
  setTimeCodeGroups({ commit }, timeCodeGroups = []) {
    const formattedTimeCodeGroups = timeCodeGroups.map(parseTimeCodeGroup);
    commit('setTimeCodeGroups', formattedTimeCodeGroups);
  },
  setTimeCodeTreeElements({ commit }, elements = []) {
    const formattedElements = elements.map(parseTimeCodeTreeElement);
    commit('setTimeCodeTreeElements', formattedElements);
  },
  setOperatorMessageTypes({ commit }, messageTypes = []) {
    const formattedMessageTypes = messageTypes.map(parseOperatorMessageType);
    commit('setOperatorMessageTypes', formattedMessageTypes);
  },
  setOperatorMessageTypeTree({ commit }, elements = []) {
    const formattedElements = elements.map(parseOperatorMessageTypeTree);
    commit('setOperatorMessageTypeTree', formattedElements);
  },
  setClusters({ commit }, clusters = []) {
    const formattedClusters = clusters.map(parseCluster);
    commit('setClusters', formattedClusters);
  },
  setMaterialTypes({ commit }, types = []) {
    const materialTypes = types.map(parseMaterialType);
    commit('setMaterialTypes', materialTypes);
  },
  setLoadStyles({ commit }, styles = []) {
    const loadStyles = styles.map(parseLoadStyle);
    commit('setLoadStyles', loadStyles);
  },
  setAssetRadios({ commit }, radios = []) {
    const assetRadios = radios.map(parseAssetRadio);
    commit('setAssetRadios', assetRadios);
  },
  setPreStarts({ commit }, preStarts = []) {
    const formattedPreStarts = preStarts.map(parsePreStart);
    commit('setPreStarts', formattedPreStarts);
  },
};

const mutations = {
  clear(state) {
    console.log('[Constants] Clearing data from disk');
    clearKeys(state, Object.values(DISK_KEYS));
  },
  setAssets(state, assets = []) {
    persistAndSet(state, DISK_KEYS.assets, assets);
  },
  setAssetTypes(state, assetTypes = []) {
    persistAndSet(state, DISK_KEYS.assetTypes, assetTypes);
  },
  setOperators(state, operators = []) {
    persistAndSet(state, DISK_KEYS.operators, operators);
  },
  setLocations(state, locations = []) {
    const hasGeofences = locations.some(l => l.geofence);

    // if locations have geofences, accept them
    if (hasGeofences) {
      persistAndSet(state, DISK_KEYS.locations, locations);
    }
  },
  setTimeCodes(state, timeCodes = []) {
    persistAndSet(state, DISK_KEYS.timeCodes, timeCodes);
  },
  setTimeCodeGroups(state, timeCodeGroups = []) {
    persistAndSet(state, DISK_KEYS.timeCodeGroups, timeCodeGroups);
  },
  setTimeCodeTreeElements(state, timeCodeTreeElements = []) {
    persistAndSet(state, DISK_KEYS.timeCodeElements, timeCodeTreeElements);
  },
  setOperatorMessageTypes(state, operatorMessageTypes = []) {
    state.operatorMessageTypes = operatorMessageTypes;
  },
  setOperatorMessageTypeTree(state, elements = []) {
    const sortedElements = elements.slice();
    sortedElements.sort((a, b) => a.order - b.order);
    state.operatorMessageTypeTree = sortedElements;
  },
  setClusters(state, clusters = []) {
    const lookup = {};
    clusters.forEach(c => {
      lookup[c.id] = c;
    });

    persistAndSet(state, DISK_KEYS.clusters, lookup);
  },
  setMaterialTypes(state, types = []) {
    persistAndSet(state, DISK_KEYS.materialTypes, types);
  },
  setLoadStyles(state, styles = []) {
    persistAndSet(state, DISK_KEYS.loadStyles, styles);
  },
  setAssetRadios(state, radios = []) {
    persistAndSet(state, DISK_KEYS.assetRadios, radios);
  },
  setPreStarts(state, preStarts = []) {
    persistAndSet(state, DISK_KEYS.preStarts, preStarts);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
