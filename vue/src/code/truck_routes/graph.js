import { hasOrderedSubArray } from '../helpers';
import { haversineDistanceM } from '../distance';

export function fromGraph(vertices, adjacency) {
  vertices = vertices || {};
  adjacency = adjacency || {};
  const vertexIds = Object.values(vertices).map(v => v.id);

  const adjacencyIds = Object.values(adjacency)
    .map(edges => edges.map(e => e.id))
    .flat();
  const allIds = vertexIds.concat(adjacencyIds);
  const nextId = Math.max(...allIds, 1);

  const graph = new Graph();
  graph.vertices = vertices;
  graph.adjacency = adjacency;
  graph._nextId = nextId;
  return graph;
}

export function fromRoute(route) {
  const graph = new Graph();

  if (!route) {
    return graph;
  }

  const graphVId = {};

  route.elementIds.forEach(edgeId => {
    const edge = route.edgeMap[edgeId];
    const { vertexStartId, vertexEndId } = edge;

    if (route.vertexMap[vertexStartId] && route.vertexMap[vertexEndId]) {
      const vertices = [route.vertexMap[vertexStartId], route.vertexMap[vertexEndId]];

      vertices.forEach(v => {
        if (graphVId[v.id] == null) {
          const insertedV = graph.addVertex({ vertexId: v.id, lat: v.lat, lng: v.lng });
          graphVId[v.id] = insertedV.id;
        }
      });

      graph.addEdge(graphVId[vertexStartId], graphVId[vertexEndId], {
        edgeId,
        distance: edge.distance,
      });
    }
  });

  return graph;
}

export function fromRestrictedRoute(route, assetTypeId) {
  const graph = new Graph();

  if (!route) {
    return graph;
  }

  const graphVId = {};

  const restrictionGroup = route.restrictionGroups.find(r => r.assetTypeIds.includes(assetTypeId));

  if (!restrictionGroup) {
    return graph;
  }

  restrictionGroup.edgeIds.forEach(edgeId => {
    const edge = route.edgeMap[edgeId];
    const { vertexStartId, vertexEndId } = edge;

    if (route.vertexMap[vertexStartId] && route.vertexMap[vertexEndId]) {
      const vertices = [route.vertexMap[vertexStartId], route.vertexMap[vertexEndId]];

      vertices.forEach(v => {
        if (graphVId[v.id] == null) {
          const insertedV = graph.addVertex({ vertexId: v.id, lat: v.lat, lng: v.lng });
          graphVId[v.id] = insertedV.id;
        }
      });

      graph.addEdge(graphVId[vertexStartId], graphVId[vertexEndId], {
        edgeId,
        distance: edge.distance,
      });
    }
  });

  return graph;
}

export class Graph {
  constructor() {
    this.vertices = {};
    this.adjacency = {};
    this._nextId = 1;
  }

  getId() {
    const id = this._nextId;
    this._nextId += 1;
    return id;
  }

  copy() {
    return fromGraph(this.vertices, this.adjacency);
  }

  addVertex(data) {
    const vertexId = this.getId();
    const vertex = { id: vertexId, data: { ...(data || {}) } };
    this.vertices[vertexId] = vertex;
    return vertex;
  }

  removeVertex(id) {
    const vertex = this.vertices[id];
    if (!vertex) {
      return;
    }

    delete this.vertices[id];
    delete this.adjacency[id];

    Object.keys(this.adjacency).map(id => {
      this.adjacency[id] = this.adjacency[id].filter(edge => edge.endVertexId !== id);
    });
  }

  removeOrphanVertices() {
    const edges = Object.values(this.adjacency).flat();
    Object.keys(this.vertices).forEach(vId => {
      // if there are connections from the vertex
      if (this.adjacency[vId].length) {
        return;
      }

      // if there are any connections to the vertex
      if (edges.some(e => e.endVertexId === vId)) {
        return;
      }

      delete this.adjacency[vId];
      delete this.vertices[vId];
    });
  }

  getVertex(id) {
    return this.vertices[id];
  }

  getVerticesList() {
    return Object.values(this.vertices);
  }

  addEdge(startVertexId, endVertexId, data) {
    const edges = (this.adjacency[startVertexId] || []).filter(
      edge => edge.endVertexId !== endVertexId,
    );

    const edge = { id: this.getId(), startVertexId, endVertexId, data: { ...(data || {}) } };

    edges.push(edge);

    this.adjacency[startVertexId] = edges;

    return edge;
  }

  getEdge(vertex1Id, vertex2Id) {
    const edges = this.adjacency[vertex1Id] || [];
    return edges.find(e => e.endVertexId === vertex2Id);
  }

  removeEdge(vertex1Id, vertex2Id) {
    const edges = this.adjacency[vertex1Id] || [];
    const newEdges = edges.filter(edge => edge.endVertexId !== vertex2Id);
    this.adjacency[vertex1Id] = newEdges;
  }
}

export function getUniqPaths(adjacency) {
  const paths = Object.keys(adjacency)
    .map(startVertexId => {
      const paths = createAllPathsFrom(adjacency, parseInt(startVertexId, 10));

      return paths;
    })
    .flat();

  // descending order
  paths.sort((a, b) => b.length - a.length);

  const circles = paths.filter(p => p[0] === p[p.length - 1]);
  const straights = paths.filter(p => p[0] !== p[p.length - 1]);

  const uniqCircles = circles.reduce((acc, path) => {
    // doubling the length allows for overflow checking
    const circularPaths = acc.map(p => p.slice(0, p.length - 1).concat(p));
    const notUniq =
      circularPaths.some(p => hasOrderedSubArray(p, path)) ||
      circularPaths.some(p => hasOrderedSubArray(p, path.reverse()));

    if (!notUniq) {
      acc.push(path);
    }

    return acc;
  }, []);

  const allUniqs = uniqCircles.concat(straights).reduce((acc, path) => {
    const notUniq =
      acc.some(p => hasOrderedSubArray(p, path)) ||
      acc.some(p => hasOrderedSubArray(p, path.slice().reverse()));
    if (!notUniq) {
      acc.push(path);
    }
    return acc;
  }, []);

  return allUniqs;
}

function createAllPathsFrom(adjacency, startVId) {
  const neighbours = adjacency[startVId] || [];
  return neighbours.map(edge => createPathUntil(adjacency, edge.endVertexId, startVId, [startVId]));
}

function createPathUntil(adjacency, currentVId, prevVId, visited) {
  const neighbours = adjacency[currentVId] || [];

  const firstNotPrev = neighbours.filter(
    edge => edge.endVertexId !== prevVId && edge.startVertexId !== prevVId,
  )[0];

  // if no-where to go
  if (!firstNotPrev) {
    visited.push(currentVId);
    return visited;
  }

  // if circular
  if (visited.includes(currentVId)) {
    visited.push(currentVId);
    return visited;
  }

  // an intersection node
  if (neighbours.length > 2) {
    visited.push(currentVId);
    return visited;
  }

  visited.push(currentVId);
  return createPathUntil(adjacency, firstNotPrev.endVertexId, currentVId, visited);
}

export function getClosestVertex(point, vertList) {
  if (vertList.length === 0) {
    return null;
  }

  let bestVertex = null;
  let bestDistance = Infinity;

  for (let vertex of vertList) {
    const vertPoint = { lat: vertex.data.lat, lng: vertex.data.lng };
    const distance = haversineDistanceM(point, vertPoint);

    if (distance < bestDistance) {
      bestVertex = vertex;
      bestDistance = distance;
    }
  }

  return bestVertex;
}
