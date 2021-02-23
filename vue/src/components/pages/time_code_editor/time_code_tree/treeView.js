export function toTree(nodes) {
  const sortedNodes = sortNodes(nodes);

  const lookup = {};
  const roots = [];

  sortedNodes.forEach(node => {
    lookup[node.id] = node;
    node.children = [];
  });

  sortedNodes.forEach(node => {
    if (node.parentId) {
      lookup[node.parentId].children.push(node);
    } else {
      roots.push(node);
    }
  });
  return roots;
}

export function flattenTree(roots) {
  return roots.map(getNodes).flat();
}

export function getNodes(node) {
  const thisNode = {
    id: node.id,
    isLeaf: node.isLeaf,
    parentId: node.parentId,
    data: node.data,
  };

  if (node.children.length === 0) {
    return [thisNode];
  } else {
    return [thisNode].concat(node.children.map(getNodes).flat());
  }
}

function copy(element) {
  return JSON.parse(JSON.stringify(element));
}

function sortNodes(nodes) {
  return nodes.map(n => copy(n)).sort(function(a, b) {
    return (b.parent_id === null) - (a.parent_id === null) || a.parent_id - b.parent_id;
  });
}

export function locateChild(roots, id, path = []) {
  const node = roots.find(r => r.id === id);
  if (!node) {
    return path;
  }

  path.push(node);

  return locateChild(roots, node.parentId, path);
}
