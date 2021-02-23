function toRad(x) {
  return (x * Math.PI) / 180;
}

export function haversineDistanceM(posA, posB) {
  const R = 6371000;

  const latA = posA.lat;
  const lngA = posA.lng;

  const latB = posB.lat;
  const lngB = posB.lng;

  const dLat = toRad(latB - latA);
  const dLng = toRad(lngB - lngA);

  const halfDLat = dLat / 2;
  const halfDLng = dLng / 2;

  const a =
    Math.sin(halfDLat) * Math.sin(halfDLat) +
    Math.cos(toRad(latA)) * Math.cos(toRad(latB)) * Math.sin(halfDLng) * Math.sin(halfDLng);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

export function pixelsToMeters(pixels, zoom) {
  const metersPerPx = 156543 / Math.pow(2, zoom);
  return pixels * metersPerPx;
}
