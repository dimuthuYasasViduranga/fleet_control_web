import { chunkEvery, copy, IdGen, toLookup } from '@/code/helpers';

const { pixelsToMeters, haversineDistanceM } = require('@/code/distance');

const NodeDbIds = new IdGen(-1, -1);
const EdgeDbIds = new IdGen(-1, -1);

export function addPolylineToGraph(graph, path, zoom, snapDistancePx) {
  const snapDistance = pixelsToMeters(snapDistancePx, zoom);
  const existingVertices = graph.getVerticesList();

  const usedVertices = path.map(point =>
    addOrGetVertex(graph, existingVertices, point, snapDistance),
  );

  chunkEvery(usedVertices, 2, 1, 'discard').forEach(([v1, v2]) => {
    addOrGetEdge(graph, v1, v2);
    addOrGetEdge(graph, v2, v1);
  });

  return graph.copy();
}

function addOrGetVertex(graph, vertices, point, snapDistance) {
  const existingV = vertices.find(v => haversineDistanceM(point, v.data) < snapDistance);
  return existingV || graph.addVertex({ lat: point.lat, lng: point.lng, nodeId: NodeDbIds.next() });
}

function addOrGetEdge(graph, v1, v2) {
  const edge = graph.getEdge(v1.id, v2.id);
  if (edge) {
    return edge;
  }

  const distance = haversineDistanceM(v1.data, v2.data);

  const data = {
    ...v1.data,
    edgeId: EdgeDbIds.next(),
    distance,
  };

  return graph.addEdge(v1.id, v2.id, data);
}

function findVertexInRange(vertices, point, threshold) {
  const orderedByDistance = vertices
    .map(v => {
      return {
        vertex: v,
        distance: haversineDistanceM(point, v.data),
      };
    })
    .sort((a, b) => a.distance - b.distance);

  const first = orderedByDistance[0] || { distance: Infinity };
  if (first.distance < threshold) {
    return first.vertex;
  }
  return;
}

export function editGraph(graph, newPath, oldPath, zoom, snapDistancePx) {
  const snapDistance = pixelsToMeters(snapDistancePx, zoom);

  const existingVertices = graph.getVerticesList();

  // convert paths into vertices
  const oldVertices = oldPath.map(p => {
    return {
      id: p.id,
      data: {
        ...p.data,
        lat: p.lat,
        lng: p.lng,
      },
    };
  });

  // get new/existing vertices
  const newVertices = newPath.map((p, index) => {
    const existingVertex = findVertexInRange(existingVertices, p, snapDistance);

    if (existingVertex) {
      return copy(existingVertex);
    }

    return {
      id: -index - 1,
      data: {
        nodeId: null,
        lat: p.lat,
        lng: p.lng,
      },
    };
  });

  // get all old edges
  const oldEdges = chunkEvery(oldVertices, 2, 1, 'discard')
    .map(([v1, v2]) => {
      return [graph.getEdge(v1.id, v2.id), graph.getEdge(v2.id, v1.id)];
    })
    .flat()
    .filter(e => e);

  // get new/existing edges
  const newEdges = chunkEvery(newVertices, 2, 1, 'discard')
    .map(([v1, v2], index) => {
      const e1TempId = (index + 1) * -2;
      const e2TempId = e1TempId - 1;
      const e1 = graph.getEdge(v1.id, v2.id) || getTempEdge(e1TempId, v1, v2);
      const e2 = graph.getEdge(v2.id, v1.id) || getTempEdge(e2TempId, v2, v1);

      return [e1, e2];
    })
    .flat();

  // added vertices
  const addedVertices = newVertices.filter(v => v.id < 0);

  // added edges
  const addedEdges = newEdges.filter(e => e.id < 0);

  // removed vertices (if they are a termination for another segment, they cannot be removed)
  const newVerticesLookup = toLookup(newVertices, e => e.id);
  const maybeRemovedVertices = oldVertices.filter(v => !newVerticesLookup[v.id]);

  // removed edges
  const newEdgeLookup = toLookup(newEdges, e => e.id);
  const removedEdges = oldEdges.filter(e => !newEdgeLookup[e.id]);

  return applyChanges(graph, addedVertices, addedEdges, maybeRemovedVertices, removedEdges);
}

function applyChanges(sourceGraph, addedVertices, addedEdges, maybeRemovedVertices, removedEdges) {
  const graph = sourceGraph.copy();

  // removal first
  removedEdges.forEach(e => {
    graph.removeEdge(e.startVertexId, e.endVertexId);
    graph.removeEdge(e.endVertexId, e.startVertexId);
  });

  // only remove orphaned vertices
  maybeRemovedVertices.forEach(v => {
    if (graph.adjacency[v.id].length === 0) {
      graph.removeVertex(v.id);
    }
  });

  // need a id map lookup for edges
  const idMap = addedVertices.reduce((acc, v) => {
    const data = {
      nodeId: NodeDbIds.next(),
      lat: v.data.lat,
      lng: v.data.lng,
    };
    const vInst = graph.addVertex(data);
    acc[v.id] = vInst.id;
    return acc;
  }, {});

  addedEdges.forEach(e => {
    // map the ids if possible
    const a = idMap[e.startVertexId] || e.startVertexId;
    const b = idMap[e.endVertexId] || e.endVertexId;
    graph.addEdge(a, b, { edgeId: EdgeDbIds.next(), distance: e.distance });
    graph.addEdge(b, a, { edgeId: EdgeDbIds.next(), distance: e.distance });
  });

  return graph;
}

function getTempEdge(id, v1, v2) {
  const distance = haversineDistanceM(v1.data, v2.data);
  return {
    id,
    startVertexId: v1.id,
    endVertexId: v2.id,
    data: {
      edgeId: null,
      distance,
    },
  };
}
