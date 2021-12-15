import { Dictionary, uniq, hasOrderedSubArray, toLookup } from '@/code/helpers';
import { haversineDistanceM } from '@/code/distance';

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

export function fromRoute(nodes, edges, route) {
  if (!route) {
    return new Graph();
  }

  const edgeLookup = toLookup(edges, 'id');
  const nodeLookup = toLookup(nodes, 'id');
  const nodeToVertexId = {};

  const usedEdges = route.edgeIds.map(id => edgeLookup[id]).filter(e => e);

  const usedNodes = uniq(
    usedEdges.reduce((acc, e) => {
      acc.push(e.nodeStartId);
      acc.push(e.nodeEndId);
      return acc;
    }, []),
  ).map(id => nodeLookup[id]);

  const vertices = usedNodes.reduce((acc, node, index) => {
    const vertex = {
      id: index,
      data: {
        nodeId: node.id,
        lat: node.lat,
        lng: node.lng,
      },
    };
    nodeToVertexId[node.id] = index;
    acc[index] = vertex;
    return acc;
  }, {});

  const adjDict = new Dictionary();
  usedEdges.forEach((edge, index) => {
    const adj = {
      id: index,
      startVertexId: nodeToVertexId[edge.nodeStartId],
      endVertexId: nodeToVertexId[edge.nodeEndId],
      data: {
        edgeId: edge.id,
        distance: edge.distance,
      },
    };
    adjDict.append(adj.startVertexId, adj);
  });

  const adjacency = adjDict.reduce((acc, key, adjacencies) => {
    acc[key] = adjacencies;
    return acc;
  }, {});

  return fromGraph(vertices, adjacency);
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

    Object.keys(this.adjacency).map(id => {
      this.adjacency[id] = this.adjacency[id].filter(edge => edge.endVertexId === id);
    });
  }

  removeOrphanVertices() {
    Object.keys(this.adjacency).forEach(id => {
      if (this.adjacency[id].length === 0) {
        delete this.adjacency[id];
      }
    });

    Object.keys(this.vertices).forEach(id => {
      if ((this.adjacency[id] || []).length === 0) {
        delete this.vertices[id];
      }
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

export function dijkstra(vertexMap, adjacency, source) {
  let queue = [];
  const dist = {};
  const prev = {};

  Object.values(vertexMap).forEach(({ id }) => {
    dist[id] = Infinity;
    queue.push(id);
  });
  dist[source.id] = 0;

  while (queue.length !== 0) {
    const curId = getNextVertex(queue, dist);

    queue = queue.filter(id => id !== curId);

    const neighbours = getNeighbours(queue, curId, adjacency);

    for (let neighbour of neighbours) {
      const endId = neighbour.endVertexId;
      const alternateDist = dist[curId] + (neighbour.data.distance || Infinity);
      if (alternateDist < dist[endId]) {
        dist[endId] = alternateDist;
        prev[endId] = { id: curId, edge: neighbour };
      }
    }
  }

  return Object.entries(dist).reduce((acc, [id, distance]) => {
    const prevData = prev[id] || {};
    acc[id] = { id, distance, parentVertexId: prevData.id, edge: prevData.edge };
    return acc;
  }, {});
}

export function dijkstraToVertices(djk, targetId, path = []) {
  const parentId = djk[targetId].parentVertexId;
  path.push(targetId);

  if (!parentId) {
    return path.reverse();
  }

  return dijkstraToVertices(djk, parentId, path);
}

function getNextVertex(queue, dist) {
  const available = queue.map(vId => ({ id: vId, dist: dist[vId] }));
  available.sort((a, b) => a.dist - b.dist);
  return available[0].id;
}

function getNeighbours(queue, vertexId, adjacency) {
  return (adjacency[vertexId] || []).filter(edge => queue.includes(edge.endVertexId));
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
