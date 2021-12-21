import { approx } from './helpers';

export function coordsObjsToCoordArrays(gCoords) {
  const coords = gCoords.map(coordObjToCoordArray);

  const firstCoord = [...coords[0]];

  if (!coordsEqual(firstCoord, coords[coords.length - 1])) {
    coords.push(firstCoord);
  } else {
    coords[coords.length - 1] = firstCoord;
  }

  return coords;
}

function coordObjToCoordArray(p) {
  return [p.lng, p.lat];
}

export function coordsEqual([lngA, latA], [lngB, latB], epsilon) {
  epsilon = epsilon || 0.000001;
  return approx(latA, latB, epsilon) && approx(lngA, lngB, epsilon);
}
