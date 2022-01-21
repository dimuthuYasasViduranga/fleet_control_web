import { haversineDistanceM } from './distance';
import { fromGraph, getClosestVertex, Graph } from './graph';
import { dijkstra, dijkstraToVertices } from './graph_traversal';
import { chunkEvery } from './helpers';
import turf from './turf';
import { coordsObjsToCoordArrays } from './turfHelpers';

export class JourneySelector {
  constructor(graph, locations) {
    let g = graph || new Graph();
    this._graph = fromGraph(g.vertices, g.adjacency);
    this._locations = locations.map(formatLocations);
    this._locToV = createLocationToVerticesLookup(this._locations, this._graph.getVerticesList());
  }

  markerFromLocation(value) {
    const source = { type: 'locationId', value };
    return convertMarker(source, this._graph, this._locations, this._locToV);
  }

  markerFromPosition(value) {
    const source = { type: 'position', value };
    return convertMarker(source, this._graph, this._locations, this._locToV);
  }

  markerFrom(raw) {
    return convertMarker(raw, this._graph, this._locations, this._locToV);
    // return convertMarker(this._graph)
  }

  between(rawSource, rawDestination, opts) {
    const source = convertMarker(rawSource, this._graph, this._locations, this._locToV);
    const destination = convertMarker(rawDestination, this._graph, this._locations, this._locToV);

    if (!source || !destination) {
      return;
    }

    return createJourney(source, destination, this._graph, this._locations, this._locToV, opts);
  }
}

function convertMarker(source, graph, locations, locToV) {
  const type = source?.type;

  if (type === 'locationId') {
    return locationIdToMarker(source.value, locToV);
  }

  if (type === 'position') {
    return positionToMarker(source.value, locations, locToV, graph.getVerticesList());
  }
}

function locationIdToMarker(locationId, locToV) {
  const vertexId = (locToV[locationId] || [])[0]?.id;

  return {
    position: null,
    locationId,
    vertexId,
  };
}

function positionToMarker(pos, locations, locToV, vertices) {
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

function formatLocations(loc) {
  const coordArray = coordsObjsToCoordArrays(loc.geofence);

  return {
    id: loc.id,
    name: loc.name,
    turfPolygon: turf.polygon([coordArray]),
    polygonGraph: graphFromPolygon(loc.geofence),
  };
}

function graphFromPolygon(polygon) {
  const graph = new Graph();

  const vertices = polygon.map(coord => graph.addVertex(coord));

  chunkEvery(vertices, 2, 1, 'discard').map(([a, b]) => {
    const distance = haversineDistanceM(a.data, b.data);
    graph.addEdge(a.id, b.id, { distance });
    graph.addEdge(b.id, a.id, { distance });
  });

  return graph;
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

function distanceFromPath(path) {
  return chunkEvery(path, 2, 1, 'discard').reduce((acc, [a, b]) => {
    return acc + haversineDistanceM(a, b);
  }, 0);
}

function createJourney(source, dest, graph, locations) {
  if (source.locationId != null && source.locationId === dest.locationId) {
    return createJourneyWithinLocation(source, dest, graph, locations);
  }

  const vertexPath = findVertexPath(graph, source, dest);

  const spatialPath = vertexPathToSpatial(graph, source, dest, vertexPath);

  const routedDistance = distanceFromPath(spatialPath);

  const noLocationRoute = createJourneyForNoLocations(source, dest, routedDistance, locations);

  if (noLocationRoute) {
    return noLocationRoute;
  }

  return {
    source,
    dest,
    vertexPath,
    spatialPath,
    totalDistance: routedDistance,
  };
}

function createJourneyWithinLocation(source, dest, graph, locations) {
  let vertexPath = findVertexPath(graph, source, dest);

  let spatialPath = vertexPathToSpatial(graph, source, dest, vertexPath);

  const routedDistance = distanceFromPath(spatialPath);

  const shortcutDistance = haversineDistanceM(source.position, dest.position);
  const noLocationsBetween = !areThereLocationsBetween(locations, source.position, dest.position);

  let totalDistance = routedDistance;

  if (noLocationsBetween && shortcutDistance < routedDistance) {
    vertexPath = [];
    spatialPath = [source.position, dest.position];
    totalDistance = shortcutDistance;
  }

  return {
    source,
    dest,
    vertexPath,
    spatialPath,
    totalDistance,
  };
}

function createJourneyForNoLocations(source, dest, routedDistance, locations) {
  if (source.locationId != null || dest.locationId != null) {
    return;
  }

  const shortcutDistance = haversineDistanceM(source.position, dest.position);

  const locationsBetween = areThereLocationsBetween(locations, source.position, dest.position);

  if (shortcutDistance > routedDistance || locationsBetween) {
    return;
  }

  return {
    source,
    dest,
    vertexPath: [],
    spatialPath: [source.position, dest.position],
    totalDistance: shortcutDistance,
  };
}

function areThereLocationsBetween(locations, a, b) {
  const line = turf.lineString([
    [a.lng, a.lat],
    [b.lng, b.lat],
  ]);
  return locations.some(l => {
    return turf.lineIntersect(line, l.turfPolygon).features.length;
  });
}

function findVertexPath(graph, source, dest) {
  const result = dijkstra(graph.vertices, graph.adjacency, source.vertexId);
  return dijkstraToVertices(result, dest.vertexId);
}

function vertexPathToSpatial(graph, source, dest, vertexPath) {
  const vertexMap = graph.vertices;
  const path = vertexPath.map(id => {
    const data = vertexMap[id].data;
    return { lat: data.lat, lng: data.lng };
  });

  if (source.position) {
    path.unshift({ ...source.position });
  }

  if (dest.position) {
    path.push({ ...dest.position });
  }

  return path;
}
