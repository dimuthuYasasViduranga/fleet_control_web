const GMap = require('nativescript-google-maps-sdk');
const Google = com.google.android.gms.maps;

const R_EARTH = 6371000;
const DEG_TO_RAD = Math.PI / 180;

export function getCameraUpdate(coord) {
  const latLng = toGLatLng(coord.lat, coord.lng);
  const cameraPosition = new Google.model.CameraPosition(
    latLng,
    coord.zoom,
    coord.tilt,
    coord.bearing,
  );
  return Google.CameraUpdateFactory.newCameraPosition(cameraPosition);
}

export function getCameraBounds(coords = [], padding = 100) {
  if (coords.length < 2) {
    return null;
  }
  const builder = new Google.model.LatLngBounds.Builder();
  coords.forEach(c => {
    builder.include(toGLatLng(c.lat, c.lng));
  });
  const bounds = builder.build();
  return Google.CameraUpdateFactory.newLatLngBounds(bounds, padding);
}

export function toGLatLng(lat, lng) {
  return new Google.model.LatLng(lat, lng);
}

export function toLatLng(lat, lng) {
  return GMap.Position.positionFromLatLng(lat, lng);
}

export function moveLatLng(latLng, latDelta, lngDelta) {
  return toLatLng(latLng.latitude + latDelta, latLng.longitude + lngDelta);
}

export function radians(degrees) {
  return DEG_TO_RAD * degrees;
}

export function bearingToRad(bearing) {
  const deg = -((bearing - 90) % 360);
  return radians(deg);
}

export function moveLatLngBy(latLng, meters, bearing) {
  const rad = bearingToRad(bearing);
  const dy = meters * Math.sin(rad);
  const dx = meters * Math.cos(rad);

  const newLat = latLng.latitude + ((dy / R_EARTH) * 180) / Math.PI;
  const newLng =
    latLng.longitude +
    ((dx / R_EARTH) * 180) / Math.PI / Math.cos((latLng.latitude * Math.PI) / 180);

  return toLatLng(newLat, newLng);
}
