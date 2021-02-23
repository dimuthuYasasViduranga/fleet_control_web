import { uniq } from '@/code/helpers';
export function structureFromHaulTrucks(haulTrucks) {
  const structure = {};

  haulTrucks.map(h => {
    const digUnitId = h.dispatch.digUnitId;
    const dumpId = h.dispatch.dumpId;

    if (!digUnitId || !dumpId) {
      return;
    }

    (structure[digUnitId] = structure[digUnitId] || []).push(dumpId);
  });

  return structure;
}

function parseKey(key) {
  if (key === 'null') {
    return null;
  }
  const asInt = parseInt(key, 10);
  return isNaN(asInt) ? key : asInt;
}

export function listifyStructure(structure) {
  return Object.entries(structure).map(([keyStr, dumpIds]) => {
    const key = parseKey(keyStr);
    return { assetId: key, dumpIds };
  });
}

export function mergeStructure(oldStructure, newStructure) {
  const structure = { ...oldStructure };
  Object.entries(newStructure).map(([keyStr, dumpIds]) => {
    const key = parseKey(keyStr);
    structure[key] = uniq((structure[key] || []).concat(dumpIds));
  });
  return structure;
}

export function addDigUnit(structure, digUnitId) {
  const newStruct = { ...structure };
  newStruct[digUnitId] = newStruct[digUnitId] || [];
  return newStruct;
}

export function addDump(structure, digUnitId, dumpId) {
  const newStruct = { ...structure };
  let dumpIds = newStruct[digUnitId] || [];

  dumpIds = uniq(dumpIds.concat(dumpId));
  newStruct[digUnitId] = dumpIds;
  return newStruct;
}

export function removeDigUnit(structure, digUnitId) {
  const newStruct = { ...structure };
  delete newStruct[digUnitId];
  return newStruct;
}

export function removeDump(structure, digUnitId, dumpId) {
  const newStruct = { ...structure };
  const dumpIds = newStruct[digUnitId];

  if (!dumpIds) {
    return newStruct;
  }

  newStruct[digUnitId] = dumpIds.filter(id => id !== dumpId);
  return newStruct;
}
