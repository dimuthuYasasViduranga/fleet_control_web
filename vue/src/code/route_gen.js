import { fromRestrictedRoute, fromRoute, getClosestVertex } from './graph';
import { dijkstra, dijkstraToVertices } from './graph_traversal';
import { attributeFromList, Dictionary } from './helpers';
import turf from './turf';
import { coordsObjsToCoordArrays } from './turfHelpers';

export function createRoute(
  startLocationIdOrPosition,
  endLocationIdOrPosition,
  locations,
  activeRoute,
  assetTypeId,
) {
  console.dir('--------- create route');
  // create a graph for the given asset type (no type is taken as free roam)
  const graph = assetTypeId
    ? fromRestrictedRoute(activeRoute, assetTypeId)
    : fromRoute(activeRoute);

  // get a list of vertices for each location
  const locs = locations.map(formatLocations);
  const locToV = createLocationToVerticesLookup(locs, graph.getVerticesList());

  // create a unifor start and end characteristic
  const start = convert(startLocationIdOrPosition, graph, locs, locToV);
  const end = convert(endLocationIdOrPosition, graph, locs, locToV);

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
  });
}

function convert(locationIdOrPosition, graph, locations, locToV) {
  if (typeof locationIdOrPosition === 'number') {
    return convertLocationId(locationIdOrPosition, locToV);
  }
  return convertPosition(locationIdOrPosition, locations, locToV, graph.getVerticesList());
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
  const turfPoint = turf.point([pos.lng, pos.lat]);

  const locationId = locations.find(l => turf.booleanWithin(turfPoint, l.turfPolygon))?.id;

  let vertexId = (locToV[locationId] || [])[0]?.id;

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
  activeRoute,
) {
  const haulTruckTypeId = attributeFromList(assetTypes, 'type', 'Haul Truck', 'id');

  const dict = new Dictionary();
  dispatches
    .filter(d => (d.loadId || d.digUnitId) && d.dumpId)
    .forEach(d => dict.append([d.loadId, d.digUnitId, d.dumpId], d.assetId));

  const routes = dict
    .map(([loadId, digUnitId, dumpId], assetIds) => {
      if (loadId) {
        return createHaulRoute(
          `${loadId}->${dumpId}`,
          loadId,
          dumpId,
          assetIds,
          haulTruckTypeId,
          locations,
          activeRoute,
        );
      }

      // TODO:
      console.error('--- dig unit ids not implemented yet');
      // get the position of the dig unit
      // if no position, get the assigned location
      // else return null
      return;
      // return createHaulRoute
    })
    .filter(r => r);

  console.dir('----- haul routes');
  console.dir(routes);
  return routes;
}

function createHaulRoute(
  name,
  locationIdOrPosition,
  dumpId,
  assetIds,
  assetTypeId,
  locations,
  activeRoute,
) {
  if (!dumpId) {
    return;
  }

  const route = createRoute(locationIdOrPosition, dumpId, locations, activeRoute, assetTypeId);

  return {
    name,
    ...route,
  };
}
