import { fromRestrictedRoute, fromRoute, getClosestVertex } from './graph';
import { dijkstra, dijkstraToVertices } from './graph_traversal';
import { attributeFromList, Dictionary } from './helpers';
import turf from './turf';
import { coordsObjsToCoordArrays } from './turfHelpers';

const COLORS = [
  '#0B84A5',
  '#F6C85F',
  '#6F4E7C',
  '#9DD866',
  '#CA472F',
  '#FFA056',
  '#8DDDD0',
  '#47E6D7',
];

export function createRoute(startSource, endSource, locations, activeRoute, assetTypeId) {
  // create a graph for the given asset type (no type is taken as free roam)
  const graph = assetTypeId
    ? fromRestrictedRoute(activeRoute, assetTypeId)
    : fromRoute(activeRoute);

  // get a list of vertices for each location
  const locs = locations.map(formatLocations);
  const locToV = createLocationToVerticesLookup(locs, graph.getVerticesList());

  // create a unifor start and end characteristic
  const start = convert(startSource, graph, locs, locToV);
  const end = convert(endSource, graph, locs, locToV);

  if (!start?.vertexId || !end?.vertexId) {
    return;
  }

  const path = createPath(graph, start, end);

  return {
    path,
  };
}

function createPath(graph, start, end) {
  const vertexMap = graph.vertices;
  const adjacency = graph.adjacency;

  const result = dijkstra(vertexMap, adjacency, start.vertexId);
  const vertices = dijkstraToVertices(result, end.vertexId);

  const path = vertices.map(id => {
    const data = vertexMap[id].data;
    return { lat: data.lat, lng: data.lng };
  });

  if (start.position) {
    path.unshift(start.position);
  }

  if (end.position) {
    path.push(end.position);
  }

  return path;
}

function formatLocations(loc) {
  return {
    id: loc.id,
    name: loc.name,
    turfPolygon: turf.polygon([coordsObjsToCoordArrays(loc.geofence)]),
  };
}

function createLocationToVerticesLookup(locations, vertices) {
  if (vertices.length === 0 || locations.length === 0) {
    return {};
  }

  const turfVertices = vertices.map(v => {
    return {
      id: v.id,
      ...v.data,
      turfPoint: turf.point([v.data.lng, v.data.lat]),
    };
  });

  return locations.reduce((acc, l) => {
    acc[l.id] = turfVertices.filter(v => turf.booleanWithin(v.turfPoint, l.turfPolygon));
    return acc;
  }, {});
}

function convert(source, graph, locations, locToV) {
  const type = source?.type;

  if (type === 'locationId') {
    return convertLocationId(source.value, locToV);
  }

  if (type === 'position') {
    return convertPosition(source.value, locations, locToV, graph.getVerticesList());
  }
}

function convertLocationId(locationId, locToV) {
  const vertexId = (locToV[locationId] || [])[0]?.id;

  return {
    position: null,
    locationId,
    vertexId,
  };
}

function convertPosition(pos, locations, locToV, vertices) {
  if (!pos || !pos.lat || !pos.lng) {
    return;
  }

  const turfPoint = turf.point([pos.lng, pos.lat]);

  const locationId = locations.find(l => turf.booleanWithin(turfPoint, l.turfPolygon))?.id;

  const locationVertices = (locToV[locationId] || []).map(v => {
    return {
      id: v.id,
      data: {
        lat: v.lat,
        lng: v.lng,
      },
    };
  });
  let vertexId = getClosestVertex(pos, locationVertices)?.id;

  if (!vertexId) {
    vertexId = getClosestVertex(pos, vertices)?.id;
  }

  return {
    position: pos,
    locationId,
    vertexId,
  };
}

export function createHaulRoutes(
  dispatches,
  digUnitActivities,
  tracks,
  assetTypes,
  locations,
  assets,
  activeRoute,
) {
  if (!activeRoute) {
    return [];
  }
  const haulTruckTypeId = attributeFromList(assetTypes, 'type', 'Haul Truck', 'id');

  const dict = new Dictionary();
  dispatches
    .filter(d => (d.loadId || d.digUnitId) && d.dumpId)
    .forEach(d => dict.append([d.loadId, d.digUnitId, d.dumpId], d.assetId));

  const routes = dict
    .map(([loadId, digUnitId, dumpId], assetIds) => {
      if (loadId) {
        return createHaulRouteFromLocation(
          loadId,
          dumpId,
          assetIds,
          haulTruckTypeId,
          locations,
          activeRoute,
        );
      }

      return createHaulRouteFromDigUnit(
        digUnitId,
        dumpId,
        assetIds,
        haulTruckTypeId,
        locations,
        assets,
        digUnitActivities,
        tracks,
        activeRoute,
      );
    })
    .filter(r => r);

  routes.forEach((r, index) => {
    r.color = COLORS[index % COLORS.length];
  });

  return routes;
}

function createHaulRouteFromLocation(
  loadId,
  dumpId,
  assetIds,
  haulTruckTypeId,
  locations,
  activeRoute,
) {
  const loadName = attributeFromList(locations, 'id', loadId, 'extendedName');
  return createHaulRoute(
    { loadId: loadId, digUnitId: null, dumpId },
    { type: 'locationId', value: loadId, name: loadName },
    dumpId,
    assetIds,
    haulTruckTypeId,
    locations,
    activeRoute,
  );
}

function createHaulRouteFromDigUnit(
  digUnitId,
  dumpId,
  assetIds,
  haulTruckTypeId,
  locations,
  assets,
  digUnitActivities,
  tracks,
  activeRoute,
) {
  const locationId = attributeFromList(digUnitActivities, 'assetId', digUnitId, 'locationId');
  const digUnitName = attributeFromList(assets, 'id', digUnitId, 'name');
  const digUnitPos = attributeFromList(tracks, 'assetId', digUnitId, 'position');
  const loadName = attributeFromList(locations, 'id', locationId, 'name');
  const dumpName = attributeFromList(locations, 'id', dumpId, 'extendedName');

  let source;
  if (locationId) {
    source = { type: 'locationId', value: locationId, name: `${digUnitName} [${loadName}]` };
  } else {
    source = { type: 'position', value: digUnitPos, name: digUnitName };
  }

  const route = createHaulRoute(
    { loadId: null, digUnitId, dumpId },
    source,
    { type: 'locationId', value: dumpId, name: dumpName },
    assetIds,
    haulTruckTypeId,
    locations,
    activeRoute,
  );

  if (route.path && digUnitPos) {
    route.path.unshift(digUnitPos);
  }

  return route;
}

function createHaulRoute(
  info,
  loadSource,
  dumpSource,
  assetIds,
  assetTypeId,
  locations,
  activeRoute,
) {
  if (!loadSource || !dumpSource) {
    return;
  }

  const route = createRoute(loadSource, dumpSource, locations, activeRoute, assetTypeId);

  const name = `${loadSource.name} -> ${dumpSource.name}`;

  return {
    name,
    info,
    ...route,
    assetIds,
  };
}
