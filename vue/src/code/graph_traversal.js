import { groupBy } from './helpers';

const UNVISITED = -1;

export function dijkstra(vertexMap, adjacency, sourceId) {
  let queue = [];
  const dist = {};
  const prev = {};

  Object.values(vertexMap).forEach(({ id }) => {
    dist[id] = Infinity;
    queue.push(id);
  });
  dist[sourceId] = 0;

  while (queue.length !== 0) {
    const curId = getNextVertex(queue, dist);

    queue = queue.filter(id => id !== curId);

    const neighbours = getNeighbours(queue, curId, adjacency);

    for (let neighbour of neighbours) {
      const endId = neighbour.endVertexId;
      if (neighbour.data.distance == null) {
        console.error(
          `[GraphTraversal] invalid distance for ${neighbour.startVertexId} -> ${neighbour.endVertexId} `,
        );
      }
      const alternateDist = dist[curId] + neighbour.data.distance;
      if (alternateDist < dist[endId]) {
        dist[endId] = alternateDist;
        prev[endId] = { id: curId, edge: neighbour };
      }
    }
  }

  return Object.entries(dist).reduce((acc, [id, distance]) => {
    id = parseInt(id, 10) ?? id;
    const prevData = prev[id] || {};
    acc[id] = { id, distance, parentVertexId: prevData.id, edge: prevData.edge };
    return acc;
  }, {});
}

export function dijkstraToVertices(djk, targetId) {
  const target = djk[targetId];
  if (target.distance === Infinity) {
    return [];
  }

  const path = [targetId];
  let step = target;
  while (step.parentVertexId != null) {
    path.push(step.parentVertexId);
    step = djk[step.parentVertexId];
  }
  path.reverse();

  return path;
}

function getNextVertex(queue, dist) {
  const available = queue.map(vId => ({ id: vId, dist: dist[vId] }));
  available.sort((a, b) => a.dist - b.dist);
  return available[0].id;
}

function getNeighbours(queue, vertexId, adjacency) {
  return (adjacency[vertexId] || []).filter(edge => queue.includes(edge.endVertexId));
}

// https://www.youtube.com/watch?v=wUgWX0nc4NY&ab_channel=WilliamFiset
export function stronglyConnectedComponents(vertices, adjacency) {
  const nodeCount = Object.keys(vertices).length;

  // create adjacency array instead of map
  const newVIds = Object.values(vertices).reduce((acc, v, index) => {
    acc[v.id] = index;
    return acc;
  }, {});

  const oldVIds = Object.entries(newVIds).reduce((acc, [oldId, index]) => {
    acc[index] = parseInt(oldId, 10);
    return acc;
  }, {});

  const adjArr = [];
  for (let i = 0; i < nodeCount; i++) {
    const oldId = oldVIds[i];
    const adj = adjacency[oldId].map(v => newVIds[v.endVertexId]);
    adjArr.push(adj);
  }

  const props = {
    nodeCount,
    nextId: 0,
    sccCount: 0,
    adjacency: adjArr,
    ids: Array(nodeCount).fill(UNVISITED),
    low: Array(nodeCount).fill(UNVISITED),
    onStack: Array(nodeCount),
    stack: [],
  };

  for (let i = 0; i < nodeCount; i++) {
    if (props.ids[i] === UNVISITED) {
      sccDFS(i, props);
    }
  }

  return props.low.map((group, index) => {
    return {
      id: oldVIds[index],
      group,
    };
  });
}

function sccDFS(at, props) {
  props.stack.push(at);
  props.onStack[at] = true;
  props.ids[at] = props.low[at] = props.nextId++;

  // visit all neighbours & min low-link on callback
  props.adjacency[at].forEach(to => {
    if (props.ids[to] === UNVISITED) {
      sccDFS(to, props);
    }
    if (props.onStack[to]) {
      props.low[at] = Math.min(props.low[at], props.low[to]);
    }
  });

  // Check if we are at the beginning of a SCC
  // ie node ID === low link value
  // pop off all nodes until we find ourself
  if (props.ids[at] === props.low[at]) {
    while (true) {
      const index = props.stack.pop();
      props.onStack[index] = false;
      props.low[index] = props.ids[at];
      if (index === at) {
        break;
      }
    }
    props.sccCount++;
  }
}
