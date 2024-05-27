import { stronglyConnectedComponents } from '@/code/truck_routes/graph_traversal';
import { copy, Dictionary, uniq } from '@/code/helpers';

const DIRECTIONS = ['both', 'positive', 'negative'];
const SCC_COLORS = ['#007300', '#005a00', '#004000', '#339933', '#66b366', '#99cc99', '#cce6cc'];

const POLYLINE_SYMBOLS = {
  diamond: {
    path: 'M 0,1 1,0 -1,0 z',
    strokeColor: '#F00',
    fillColor: '#F00',
    fillOpacity: 1,
    scale: 1,
  },
  arrow: {
    path: 'M -2,0 0,-4 2,0 z',
    strokeColor: 'black',
    fillColor: null,
    fillOpacity: 1,
    scale: 1,
    // anchor units are based off path space
    anchor: { x: 0, y: -1.5 },
  },
};

export function segmentsToPolylines(segments, groupLookup) {
  return segments.map(s => {
    const opts = getSegmentOpts(s, groupLookup);

    return {
      segment: s,
      path: s.path,
      ...opts,
    };
  });
}

function getSegmentOpts(seg, groupLookup) {
  const icons = getSegmentIcons(seg.direction);
  const color = getSegmentColor(seg, groupLookup);

  return {
    color,
    icons,
  };
}

function getSegmentIcons(direction) {
  const arrowOpts = {
    strokeOpacity: 1,
    strokeColor: 'black',
    strokeWeight: 2,
    fillOpacity: 1,
    fillColor: 'green',
    scale: 4,
  };
  switch (direction) {
    case 'positive':
      return [
        {
          icon: getSymbol('arrow', arrowOpts),
          offset: '50%',
        },
      ];
    case 'negative':
      return [
        {
          icon: getSymbol('arrow', { ...arrowOpts, rotation: 180 }),
          offset: '50%',
        },
      ];
    default:
      return [];
  }
}

function getSegmentColor(seg, groupLookup) {
  if (!groupLookup) {
    return 'darkgreen';
  }

  if (groupLookup[seg.vertexAId] !== groupLookup[seg.vertexBId]) {
    return '#444444';
  }

  return SCC_COLORS[groupLookup[seg.vertexAId] % SCC_COLORS.length];
}

export function getNodeGroups(graph, segments) {
  const adjacency = copy(graph.adjacency);

  // for each segment that isnt both, remove the other direction
  const directionalSegments = segments
    .filter(s => s.direction !== 'both')
    .map(s => {
      const [a, b] =
        s.direction === 'positive' ? [s.vertexAId, s.vertexBId] : [s.vertexBId, s.vertexAId];
      return {
        startId: a,
        endId: b,
      };
    });

  directionalSegments.forEach(s => {
    adjacency[s.endId] =
      adjacency[s.endId] && adjacency[s.endId].filter(e => e.endVertexId !== s.startId);
  });

  const sccVertices = stronglyConnectedComponents(graph.vertices, adjacency);

  const normaliseGroups = uniq(sccVertices.map(v => v.group)).reduce((acc, group, index) => {
    acc[group] = index;
    return acc;
  }, {});

  return sccVertices.reduce((acc, v) => {
    acc[graph.vertices[v.id].id] = normaliseGroups[v.group];
    return acc;
  }, {});
}

function getSymbol(name, opts) {
  return { ...POLYLINE_SYMBOLS[name], ...(opts || {}) };
}

export function nextDirection(dir) {
  const index = DIRECTIONS.indexOf(dir);
  return DIRECTIONS[index + 1] || DIRECTIONS[0];
}

export function graphToSegments(graph, existingSegments = []) {
  const existingDirections = new Dictionary();
  existingSegments.forEach(seg => {
    existingDirections.add([seg.vertexAId, seg.vertexBId], seg.direction);
  });

  // need to handle existing segments so that data is not lost
  const vertices = graph.vertices;

  // group edges into segment (a segment contains both directions if avialable)
  const dict = new Dictionary();
  Object.values(graph.adjacency).forEach(edges => {
    edges.forEach(edge => {
      const orderedIndex = [edge.startVertexId, edge.endVertexId].sort();
      dict.append(orderedIndex, edge);
    });
  });

  const segments = dict.map(([vertexAId, vertexBId], edges, index) => {
    const nodeStartPosition = vertices[vertexAId].data;
    const nodeEndPosition = vertices[vertexBId].data;
    const path = [nodeStartPosition, nodeEndPosition];

    const direction =
      existingDirections.get([vertexAId, vertexBId]) ||
      getEdgeDirection(graph, vertexAId, vertexBId);

    return {
      id: index,
      edges: edges,
      direction,
      vertexAId,
      vertexBId,
      path,
    };
  });

  return segments;
}

function getEdgeDirection(graph, v1, v2) {
  const e1 = graph.getEdge(v1, v2);
  const e2 = graph.getEdge(v2, v1);

  if (e1 && e2) {
    return 'both';
  }

  if (e1 && !e2) {
    return 'positive';
  }

  if (!e1 && e2) {
    return 'negative';
  }

  return 'none';
}
