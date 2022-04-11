import { toUtcDate } from '@/code/time.js';
import { attributeFromList, uniq } from '@/code/helpers.js';

import UnknownIcon from '@/components/icons/asset_icons/Unknown.vue';
import HaulTruckIcon from '@/components/icons/asset_icons/HaulTruck.vue';
import WaterTruckIcon from '@/components/icons/asset_icons/WaterTruck.vue';
import ExcavatorIcon from '@/components/icons/asset_icons/Excavator.vue';
import LoaderIcon from '@/components/icons/asset_icons/Loader.vue';
import DozerIcon from '@/components/icons/asset_icons/Dozer.vue';
import ScraperIcon from '@/components/icons/asset_icons/Scraper.vue';
import DrillIcon from '@/components/icons/asset_icons/Drill.vue';
import GraderIcon from '@/components/icons/asset_icons/Grader.vue';
import FloatIcon from '@/components/icons/asset_icons/Float.vue';
import ServiceVehicleIcon from '@/components/icons/asset_icons/ServiceVehicle.vue';
import LightVehicleIcon from '@/components/icons/asset_icons/LightVehicle.vue';
import LightingPlantIcon from '@/components/icons/asset_icons/LightingPlant.vue';
import Timely from '@/code/timely';

const DEFAULT_ZOOM = 16;
const LOAD_TYPES = ['load', 'load|dump'];
const DUMP_TYPES = ['dump', 'load|dump'];

function getIcons() {
  return {
    Unknown: UnknownIcon,
    'Haul Truck': HaulTruckIcon,
    Watercart: WaterTruckIcon,
    Excavator: ExcavatorIcon,
    Loader: LoaderIcon,
    Dozer: DozerIcon,
    Scraper: ScraperIcon,
    Drill: DrillIcon,
    Grader: GraderIcon,
    Scratchy: ExcavatorIcon,
    Float: FloatIcon,
    'Service Vehicle': ServiceVehicleIcon,
    'Light Vehicle': LightVehicleIcon,
    'Lighting Plant': LightingPlantIcon,
  };
}

function defaultCenter() {
  return {
    latitude: -32.847896,
    longitude: 116.0596581,
  };
}

function parseManifest(manifest) {
  if (!manifest || !manifest.endpoint) {
    return {};
  }

  const endpoint = manifest.endpoint;
  return Object.entries(manifest).reduce((acc, [coord, shortUrl]) => {
    if (coord === 'endpoint') {
      acc.endpoint = shortUrl;
      return acc;
    }

    acc[coord] = `${endpoint}/${shortUrl}`;
    return acc;
  }, {});
}

function parseLocation(location) {
  const extendedName = location.material_type
    ? `${location.name} (${location.material_type})`
    : location.name;

  return {
    id: location.location_id,
    name: location.name,
    extendedName,
    typeId: location.location_type_id,
    type: location.type,
    locationGroupId: location.location_group_id,
    locationGroup: location.location_group,
    materialTypeId: location.material_type_id,
    materialType: location.material_type,
    historyId: location.history_id,
    startTime: toUtcDate(location.start_time),
    endTime: toUtcDate(location.end_time),
    geofence: parseGeofence(location.geofence),
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

function parseDimLocation(raw) {
  return {
    id: raw.id,
    name: raw.name,
  };
}

function separateLocations(locations) {
  const separation = {
    load: [],
    dump: [],
  };

  locations.forEach(loc => {
    const type = loc.type;
    if (LOAD_TYPES.includes(type)) {
      separation.load.push(loc);
    }

    if (DUMP_TYPES.includes(type)) {
      separation.dump.push(loc);
    }
  });

  return separation;
}

function parseShift(shift) {
  return {
    id: shift.id,
    startTime: toUtcDate(shift.shift_start),
    endTime: toUtcDate(shift.shift_end),
    site: {
      year: shift.site_year,
      month: shift.site_month,
      day: shift.site_day,
    },
    shiftTypeId: shift.shift_type_id,
  };
}

function parseShiftType(shiftType) {
  return {
    id: shiftType.id,
    name: shiftType.name,
  };
}

function parseRadioNumber(radioNumber) {
  return {
    id: radioNumber.id,
    assetId: radioNumber.asset_id,
    number: radioNumber.radio_number,
  };
}

export function parseOperator(operator) {
  const fullname = getFullName(operator.name, operator.nickname);
  const shortname = operator.nickname || operator.name;
  return {
    id: operator.id,
    name: operator.name,
    nickname: operator.nickname,
    fullname,
    shortname,
    employeeId: operator.employee_id,
    deleted: operator.deleted,
  };
}

function parseDispatcher(dispatcher) {
  return {
    id: dispatcher.id,
    userId: dispatcher.user_id,
    name: dispatcher.name,
  };
}

function getFullName(name, nickname) {
  if (!nickname) {
    return name;
  }
  return `${name} (${nickname})`;
}

export function parseAsset(asset) {
  return {
    id: asset.id,
    name: asset.name,
    type: asset.type,
    typeId: asset.type_id,
    secondaryType: asset.secondary_type,
    enabled: asset.enabled,
  };
}

function parseAssetType(assetType) {
  return {
    id: assetType.id,
    type: assetType.type,
    secondary: assetType.secondary,
  };
}

function parseTimeCategory(category) {
  return {
    id: category.id,
    name: category.name,
  };
}

function parseTimeCode(timeCode) {
  return {
    id: timeCode.id,
    code: timeCode.code,
    name: timeCode.name,
    groupId: timeCode.group_id,
    categoryId: timeCode.category_id,
  };
}

function parseTimeCodeGroup(timeCodeGroup) {
  return {
    id: timeCodeGroup.id,
    name: timeCodeGroup.name,
    alias: timeCodeGroup.alias,
    siteName: timeCodeGroup.alias || timeCodeGroup.name,
  };
}

function parseTimeCodeTreeElement(element) {
  return {
    id: element.id,
    assetTypeId: element.asset_type_id,
    nodeName: element.node_name,
    parentId: element.parent_id,
    timeCodeGroupId: element.time_code_group_id,
    timeCodeId: element.time_code_id,
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

function parseOperatorMessageType(messageType) {
  return {
    id: messageType.id,
    type: messageType.name,
    deleted: messageType.deleted,
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

function parseMaterialType(type) {
  return {
    id: type.id,
    name: type.name,
    alias: type.alias,
    commonName: type.alias || type.name,
    tonnesToBCMFactor: type.tonnes_to_bcm_factor,
  };
}

export function parsePreStartForm(form) {
  return {
    id: form.id,
    assetTypeId: form.asset_type_id,
    dispatcherId: form.dispatcher_id,
    sections: form.sections.map(parsePreStartSection).sort((a, b) => a.order - b.order),
    timestamp: toUtcDate(form.timestamp),
    serverTimestmap: toUtcDate(form.server_timestamp),
  };
}

function parsePreStartSection(section) {
  return {
    id: section.id,
    formId: section.form_id,
    order: section.order || 0,
    title: section.title,
    details: section.details,
    controls: section.controls.map(parsePreStartControl).sort((a, b) => a.order - b.order),
  };
}

function parsePreStartControl(control) {
  return {
    id: control.id,
    sectionId: control.section_id,
    order: control.order || 0,
    label: control.label,
    requiresComment: control.requires_comment,
    categoryId: control.category_id,
  };
}

function parsePreStartTicketStatusType(type) {
  return {
    id: type.id,
    name: type.name,
    alias: type.alias | type.name,
  };
}

function parsePreStartControlCategory(cat) {
  return {
    id: cat.id,
    name: cat.name,
    order: cat.order,
    action: cat.action,
  };
}

function toFullTimeCode(timeCode, timeCodeGroups, assetTypes, treeElements) {
  const assetTypeIds = uniq(
    treeElements.filter(e => e.timeCodeId === timeCode.id).map(e => e.assetTypeId),
  );
  const assetTypeNames = assetTypes.filter(at => assetTypeIds.includes(at.id)).map(at => at.type);
  const [groupName, groupAlias] = attributeFromList(timeCodeGroups, 'id', timeCode.groupId, [
    'name',
    'alias',
  ]);
  const isReady = groupName === 'Ready';
  return {
    id: timeCode.id,
    code: timeCode.code,
    name: timeCode.name,
    groupId: timeCode.groupId,
    groupName,
    groupAlias,
    assetTypeIds,
    assetTypeNames,
    isReady,
  };
}

function parseQuickMessage(message) {
  if (message.answers) {
    return {
      message: message.message,
      answers: message.answers.slice(0, 2),
    };
  }

  return {
    message: message.message,
    answers: null,
  };
}

function parseRouteVertex(v) {
  return {
    id: v.id,
    lat: v.lat,
    lng: v.lng,
    alt: v.alt,
  };
}

function parseRouteEdge(edge) {
  return {
    id: edge.id,
    vertexStartId: edge.vertex_start_id,
    vertexEndId: edge.vertex_end_id,
    distance: edge.distance,
  };
}

function parseRoute(route) {
  const vertexMap = route.vertex_map;
  Object.keys(route.vertex_map).forEach(key => {
    vertexMap[key] = parseRouteVertex(vertexMap[key]);
  });

  const edgeMap = route.edge_map;
  Object.keys(route.edge_map).forEach(key => {
    edgeMap[key] = parseRouteEdge(edgeMap[key]);
  });

  return {
    id: route.id,
    startTime: toUtcDate(route.start_time),
    endTime: toUtcDate(route.endTime),
    vertexMap,
    edgeMap,
    elementIds: route.element_ids,
    restrictionGroups: route.restriction_groups.map(parseRouteRestrictionGroup),
  };
}

function parseRouteRestrictionGroup(g) {
  return {
    id: g.id,
    name: g.name,
    edgeIds: g.edge_ids,
    assetTypeIds: g.asset_type_ids,
  };
}

/* ---------------------- module --------------------- */

const state = {
  permissions: Object(),
  user: Object(),
  mapKey: String(),
  assets: Array(),
  allAssets: Array(),
  assetTypes: Array(),
  operators: Array(),
  shifts: Array(),
  shiftTypes: Array(),
  dimLocations: Array(),
  locations: Array(),
  loadLocations: Array(),
  dumpLocations: Array(),
  deviceAssignments: Array(),
  timeCodes: Array(),
  timeCodeGroups: Array(),
  timeCodeTreeElements: Array(),
  timeCodeCategories: Array(),
  operatorMessageTypeTree: Array(),
  operatorMessageTypes: Array(),
  radioNumbers: Array(),
  loadStyles: Array(),
  materialTypes: Array(),
  icons: getIcons(),
  mapCenter: Object(),
  mapZoom: null,
  mapManifest: Object(),
  quickMessages: Array(),
  preStartForms: Array(),
  preStartTicketStatusTypes: Array(),
  preStartControlCategories: Array(),
  activeRoute: null,
};

const getters = {
  timeCodeTreeElements: state => assetTypeId => {
    const elements = state.timeCodeTreeElements;
    if (!assetTypeId) {
      return elements;
    }
    return elements.filter(t => t.assetTypeId === assetTypeId);
  },
  operatorMessageTypeTreeElements: state => assetTypeId => {
    const elements = state.operatorMessageTypeTree;
    if (!assetTypeId) {
      return elements;
    }
    return elements.filter(e => e.assetTypeId === assetTypeId);
  },
  fullTimeCodes: state => {
    return state.timeCodes.map(tc =>
      toFullTimeCode(tc, state.timeCodeGroups, state.assetTypes, state.timeCodeTreeElements),
    );
  },
};

const actions = {
  setStaticData({ dispatch }, staticData) {
    const data = staticData.data;

    // all in constants
    [
      ['setUser', staticData.user],
      ['setLocationData', { locations: data.locations, dimLocations: data.dim_locations }],
      ['setQuickMessages', data.quick_messages],
      ['setMapConfig', data.map_config],
      ['setAssets', data.assets],
      ['setAssetTypes', data.asset_types],
      ['setShifts', data.shifts],
      ['setShiftTypes', data.shift_types],
      ['setTimeCodes', data.time_codes],
      ['setTimeCodeGroups', data.time_code_groups],
      ['setTimeCodeCategories', data.time_code_categories],
      ['setOperatorMessageTypes', data.operator_message_types],
      ['setLoadStyles', data.load_styles],
      ['setMaterialTypes', data.material_types],
    ].forEach(([path, value]) => dispatch(path, value));

    dispatch('connection/setUserToken', staticData.user_token, { root: true });
    Timely.setSiteZone(data.timezone);
  },
  setPermissions({ commit }, permissions) {
    commit('setPermissions', permissions);
    if (!permissions.authorized) {
      console.error('You are no longer authorized');
      window.location.reload();
    }
  },
  setUser({ commit }, user) {
    user = user || {};
    const formattedUser = {
      id: user.id,
      name: user.name,
      userId: user.user_id,
    };
    commit('setUser', formattedUser);
  },
  setShifts({ commit }, shifts = []) {
    const formattedShifts = shifts.map(parseShift);
    commit('setShifts', formattedShifts);
  },
  setShiftTypes({ commit }, shiftTypes = []) {
    const formattedShiftTypes = shiftTypes.map(parseShiftType);
    commit('setShiftTypes', formattedShiftTypes);
  },
  setLocationData({ commit }, data = {}) {
    const locations = (data.locations || []).map(parseLocation);
    const dimLocations = (data.dimLocations || []).map(parseDimLocation);
    commit('setLocationData', { locations, dimLocations });
  },
  setRadioNumbers({ commit }, radioNumbers = []) {
    const formattedRadioNumbers = radioNumbers.map(parseRadioNumber);
    commit('setRadioNumbers', formattedRadioNumbers);
  },
  setOperators({ commit }, operators = []) {
    const formattedOperators = operators.map(parseOperator);
    commit('setOperators', formattedOperators);
  },
  setDispatchers({ commit }, dispatchers = []) {
    const formattedDispatchers = dispatchers.map(parseDispatcher);
    commit('setDispatchers', formattedDispatchers);
  },
  setTimeCodeTreeElements({ commit }, elements = []) {
    const formattedTimeCodeTreeElements = elements.map(parseTimeCodeTreeElement);
    commit('setTimeCodeTreeElements', formattedTimeCodeTreeElements);
  },
  setOperatorMessageTypeTree({ commit }, elements = []) {
    const formattedElements = elements.map(parseOperatorMessageTypeTree);
    commit('setOperatorMessageTypeTree', formattedElements);
  },
  setMapConfig({ commit }, { key, center, manifest }) {
    commit('setMapKey', key);
    commit('setMapCenter', center);
    commit('setMapManifest', manifest);
  },
  setAssets({ commit }, assets = []) {
    const formattedAssets = assets.map(parseAsset);
    commit('setAssets', formattedAssets);
  },
  setAssetTypes({ commit }, assetTypes = []) {
    const formattedAssetTypes = assetTypes.map(parseAssetType);
    commit('setAssetTypes', formattedAssetTypes);
  },
  setTimeCodes({ commit }, timeCodes = []) {
    const formattedTimeCodes = timeCodes.map(parseTimeCode);
    commit('setTimeCodes', formattedTimeCodes);
  },
  setTimeCodeGroups({ commit }, timeCodeGroups = []) {
    const formattedTimeCodeGroups = timeCodeGroups.map(parseTimeCodeGroup);
    formattedTimeCodeGroups.sort((a, b) => a.id - b.id);
    commit('setTimeCodeGroups', formattedTimeCodeGroups);
  },
  setOperatorMessageTypes({ commit }, types = []) {
    const formattedTypes = types.map(parseOperatorMessageType);
    commit('setOperatorMessageTypes', formattedTypes);
  },
  setLoadStyles({ commit }, styles = []) {
    const loadStyles = styles.map(parseLoadStyle);
    commit('setLoadStyles', loadStyles);
  },
  setMaterialTypes({ commit }, types = []) {
    const materialTypes = types.map(parseMaterialType);
    commit('setMaterialTypes', materialTypes);
  },
  setPreStartForms({ commit }, forms = []) {
    const formattedForms = forms.map(parsePreStartForm);
    commit('setPreStartForms', formattedForms);
  },
  setTimeCodeCategories({ commit }, categories = []) {
    const formattedCategories = categories.map(parseTimeCategory);
    commit('setTimeCodeCategories', formattedCategories);
  },
  setQuickMessages({ commit }, messages = []) {
    const formattedMessage = messages.map(parseQuickMessage);
    commit('setQuickMessages', formattedMessage);
  },
  setPreStartTicketStatusTypes({ commit }, types = []) {
    const formattedTypes = types.map(parsePreStartTicketStatusType);
    commit('setPreStartTicketStatusTypes', formattedTypes);
  },
  setPreStartControlCategories({ commit }, types = []) {
    const formattedTypes = types.map(parsePreStartControlCategory);
    commit('setPreStartControlCategories', formattedTypes);
  },
  setRoutingData({ commit }, data) {
    const activeRoute = data?.active_route ? parseRoute(data.active_route) : null;
    commit('setRoutingData', activeRoute);
  },
};

const mutations = {
  setPermissions(state, permissions) {
    state.permissions = permissions || {};
  },
  setUser(state, user) {
    state.user = user;
  },
  setShifts(state, shifts = []) {
    state.shifts = shifts;
  },
  setShiftTypes(state, shiftTypes = []) {
    state.shiftTypes = shiftTypes;
  },
  setLocationData(state, { locations, dimLocations }) {
    const sortedLocations = (locations || []).slice();
    sortedLocations.sort((a, b) => a.name.localeCompare(b.name));
    const { load, dump } = separateLocations(sortedLocations);

    state.dimLocations = dimLocations || [];
    state.locations = sortedLocations;
    state.loadLocations = load;
    state.dumpLocations = dump;
  },
  setRadioNumbers(state, radioNumbers = []) {
    state.radioNumbers = radioNumbers;
  },
  setOperators(state, operators = []) {
    state.operators = operators.sort((a, b) => a.name.localeCompare(b.name));
  },
  setDispatchers(state, dispatchers = []) {
    state.dispatchers = dispatchers;
  },
  setTimeCodeTreeElements(state, elements = []) {
    state.timeCodeTreeElements = elements;
  },
  setOperatorMessageTypeTree(state, elements = []) {
    state.operatorMessageTypeTree = elements;
  },
  setAssets(state, assets = []) {
    assets.sort((a, b) => a.name.localeCompare(b.name));
    state.assets = assets.filter(a => a.enabled);
    state.allAssets = assets;
  },
  setAssetTypes(state, assetTypes = []) {
    state.assetTypes = assetTypes;
  },
  setMapKey(state, mapKey = '') {
    state.mapKey = mapKey;
  },
  setMapCenter(state, center) {
    state.mapCenter = { ...defaultCenter(), ...(center || {}) };
    state.mapZoom = (center || {}).zoom || DEFAULT_ZOOM;
  },
  setMapManifest(state, manifest) {
    state.mapManifest = parseManifest(manifest);
  },
  setTimeCodes(state, timeCodes = []) {
    state.timeCodes = timeCodes;
  },
  setTimeCodeGroups(state, timeCodeGroups = []) {
    state.timeCodeGroups = timeCodeGroups;
  },
  setOperatorMessageTypes(state, types = []) {
    state.operatorMessageTypes = types;
  },
  setLoadStyles(state, styles = []) {
    state.loadStyles = styles;
  },
  setMaterialTypes(state, types = []) {
    state.materialTypes = types;
  },
  setPreStartForms(state, forms = []) {
    state.preStartForms = forms;
  },
  setTimeCodeCategories(state, categories = []) {
    state.timeCodeCategories = categories;
  },
  setQuickMessages(state, messages = []) {
    state.quickMessages = messages;
  },
  setPreStartTicketStatusTypes(state, types = []) {
    state.preStartTicketStatusTypes = types;
  },
  setPreStartControlCategories(state, types = []) {
    state.preStartControlCategories = types;
  },
  setRoutingData(state, activeRoute) {
    state.activeRoute = activeRoute;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
