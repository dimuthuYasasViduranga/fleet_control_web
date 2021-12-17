import { stronglyConnectedComponents } from '@/code/graph_traversal';
import { copy, uniq } from '@/code/helpers';

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

  if (groupLookup[seg.nodeAId] !== groupLookup[seg.nodeBId]) {
    return '#444444';
  }

  return SCC_COLORS[groupLookup[seg.nodeAId] % SCC_COLORS.length];
}

export function getNodeGroups(graph, segments) {
  const adjacency = copy(graph.adjacency);

  // for each segment that isnt both, remove the other direction
  const directionalSegments = segments
    .filter(s => s.direction !== 'both')
    .map(s => {
      const [a, b] = s.direction === 'positive' ? [s.nodeAId, s.nodeBId] : [s.nodeBId, s.nodeAId];
      return {
        startId: a,
        endId: b,
      };
    });

  directionalSegments.forEach(s => {
    adjacency[s.endId] = adjacency[s.endId].filter(e => e.endVertexId !== s.startId);
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