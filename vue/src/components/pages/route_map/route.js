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

  return graph.addEdge(v1.id, v2.id, { ...v1.data, edgeId: EdgeDbIds.next() });
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
  console.dir('---- edit graph');
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

  // get new vertices
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

  console.dir('--- vertices');
  console.dir(oldVertices);
  console.dir(newVertices);

  // get all old edges
  const oldEdges = chunkEvery(oldVertices, 2, 1, 'discard')
    .map(([v1, v2]) => {
      return [graph.getEdge(v1.id, v2.id), graph.getEdge(v2.id, v1.id)];
    })
    .flat();

  const newEdges = chunkEvery(newVertices, 2, 1, 'discard')
    .map(([v1, v2], index) => {
      const e1TempId = (index + 1) * -2;
      const e2TempId = e1TempId - 1;
      const e1 = graph.getEdge(v1.id, v2.id) || getTempEdge(e1TempId, v1, v2);
      const e2 = graph.getEdge(v2.id, v1.id) || getTempEdge(e2TempId, v2, v1);

      return [e1, e2];
    })
    .flat();

  console.dir('--- edges');
  console.dir(oldEdges);
  console.dir(newEdges);

  // added vertices
  console.dir('---- added vertices');
  const addedVertices = newVertices.filter(v => v.id < 0);
  console.dir(addedVertices);

  // added edges
  console.dir('---- added edges');
  const addedEdges = newEdges.filter(e => e.startVertexId < 0 || e.endVertexId < 0);
  console.dir(addedEdges);

  // removed vertices
  console.dir('---- removed vertices');
  const newVerticesLookup = toLookup(newVertices, 'id');
  const removedVertices = oldVertices.filter(v => !newVerticesLookup[v.id]);
  console.dir(removedVertices);

  // removed edges
  console.dir('---- removed edges');
  const newEdgeLookup = toLookup(newEdges, 'id');
  const removedEdges = oldEdges.filter(e => !newEdgeLookup[e.id]);
  console.dir(removedEdges);

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

export function removePolylineFromGraph(graph, vertices) {
  chunkEvery(vertices, 2, 1, 'discard').map(([v1, v2]) => {
    graph.removeEdge(v1, v2);
    graph.removeEdge(v2, v1);
  });
  graph.removeOrphanVertices();

  return graph.copy();
}
