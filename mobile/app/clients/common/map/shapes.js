const GEOFENCE_COLOR = {
  closed: toGeoColor('black', 0.2),
  production: toGeoColor('green', 0.2),
  stockpile: toGeoColor('orange', 0.2),
  waste_stockpile: toGeoColor('chocolate', 0.2),
  waste_dump: toGeoColor('saddlebrown', 0.2),
  crusher: toGeoColor('blue', 0.2),
  fuel_bay: toGeoColor('yellow', 0.2),
  parkup: toGeoColor('red', 0.2),
  changeover_bay: toGeoColor('orangered', 0.2),
  maintenance: toGeoColor('gray', 0.2),
  rehab: toGeoColor('darkgreen', 0.2),
  DEFAULT: toGeoColor('black', 1),
};

function toGeoColor(fillColor, fillOpacity) {
  return {
    fillColor,
    fillOpacity,
  };
}

export function toMarker(marker) {
  const opts = {
    flat: false,
    meta: {
      shapeType: 'custom-marker',
      isCustom: true,
    },
  };

  return {
    position: { ...marker.position },
    opts,
  };
}

export function toCircle(circle) {
  const opts = {
    meta: {
      shapeType: 'custom-circle',
      isCustom: true,
    },
  };

  return {
    center: { ...circle.center },
    radius: circle.radius,
    opts,
  };
}

export function toRectangle(rect) {
  const opts = {
    meta: {
      shapeType: 'custom-rectangle',
      isCustom: true,
    },
  };

  return { bounds: rect.bounds, opts };
}

export function toPolygon(polygon) {
  const opts = {
    meta: {
      shapeType: 'custom-polygon',
      isCustom: true,
    },
  };

  const path = polygon.path.map(({ lat, lng }) => [lat, lng]);

  return { path, opts };
}

export function toPolyline(polyline) {
  const opts = {
    meta: {
      shapeType: 'custom-polyline',
      isCustom: true,
    },
  };

  const path = polyline.path.map(({ lat, lng }) => [lat, lng]);

  return { path, opts };
}

export function toGeofence(location) {
  const shapeId = `geofence-${location.id}`;

  const path = location.geofence.map(({ lat, lng }) => [lat, lng]);

  const { fillColor, fillOpacity } = GEOFENCE_COLOR[location.type] || GEOFENCE_COLOR.DEFAULT;

  const opts = {
    fillColor,
    fillOpacity,
    meta: {
      shapeType: 'geofence',
      typeId: location.typeId,
      type: location.type,
      name: location.name,
      id: location.id,
    },
  };

  return {
    shapeId,
    path,
    opts,
  };
}

export function getShapeBounds(shapes, extra = []) {
  if (shapes.length + extra.length < 2) {
    return null;
  }
  const markerBounds = shapes.filter(s => s.type === 'marker').map(m => m.position);
  const circleBounds = shapes.filter(s => s.type === 'circle').map(c => c.center);
  const rectangleBounds = shapes
    .filter(s => s.type === 'rectangle')
    .map(r => {
      return [
        { lat: r.bounds.north, lng: r.bounds.east },
        { lat: r.bounds.south, lng: r.bounds.west },
      ];
    })
    .flat();

  const polyBounds = shapes
    .filter(s => ['polygon', 'polyline'].includes(s.type))
    .map(p => p.path)
    .flat();

  const allBounds = markerBounds
    .concat(circleBounds)
    .concat(rectangleBounds)
    .concat(polyBounds)
    .concat(extra);

  const lats = allBounds.map(b => b.lat);
  const lngs = allBounds.map(b => b.lng);

  const north = Math.max(...lats);
  const south = Math.min(...lats);
  const east = Math.max(...lngs);
  const west = Math.min(...lngs);

  return [
    { lat: north, lng: east },
    { lat: south, lng: west },
  ];
}
