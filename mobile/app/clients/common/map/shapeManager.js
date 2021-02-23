const GMap = require('nativescript-google-maps-sdk');
const Google = com.google.android.gms.maps;
import { toLatLng, moveLatLngBy } from './map.js';
import { createBitmapDescriptor, toColor } from './bitmap.js';

export class ShapeManager {
  constructor(mapView) {
    this._nextId = 0;
    this._shapes = [];
    this._mapView = mapView;
  }

  _getId() {
    const id = this._nextId;
    this._nextId += 1;
    return `auto-id-${id}`;
  }

  get() {
    return this._shapes.slice();
  }

  getBy(filter) {
    return this._shapes.filter(filter);
  }

  clearAll() {
    this._mapView.clear();
    this._shapes.forEach(s => (s.removed = true));
    this._shapes = [];
  }

  clearAllType(type) {
    this.clearBy(shape => shape.type == type);
  }

  clearBy(filter) {
    const toKeep = [];
    const toRemove = [];

    this._shapes.forEach(shape => {
      filter(shape) === true ? toRemove.push(shape) : toKeep.push(shape);
    });

    toRemove.map(shape => {
      if (!shape.removed) {
        this._mapView.removeShape(shape);
      }
      shape.removed = true;
    });

    this._shapes = toKeep;
  }

  clearShape(toRemove) {
    if (!toRemove) {
      return;
    }
    this.clearBy(shape => shape.shapeId === toRemove.shapeId);
  }

  setVisibility(shape, bool) {
    shape.visible = bool;
  }

  setVisibilityBy(mapper, bool) {
    this._shapes.filter(mapper).forEach(s => (s.visible = bool));
  }

  drawArrow(shapeId, pos, bearing, size, opts) {
    const arrow = createArrow(shapeId || this._getId(), pos, bearing, size, opts);
    return this._drawShape(arrow);
  }

  drawMarker(shapeId, position, opts) {
    const marker = createMarker(shapeId || this._getId(), position, opts);
    return this._drawShape(marker);
  }

  drawCircle(shapeId, center, radius, opts) {
    const circle = createCircle(shapeId || this._getId(), center, radius, opts);
    return this._drawShape(circle);
  }

  drawRectangle(shapeId, bounds, opts) {
    const rect = createRectangle(shapeId || this._getId(), bounds, opts);
    return this._drawShape(rect);
  }

  drawPolygon(shapeId, path, opts) {
    const polygon = createPolygon(shapeId || this._getId(), path, opts);
    return this._drawShape(polygon);
  }

  drawPolyline(shapeId, path, opts) {
    const polyline = createPolyline(shapeId || this._getId(), path, opts);
    return this._drawShape(polyline);
  }

  _drawShape(shape) {
    this.clearBy(s => s.shapeId === shape.shapeId);
    shape.removed = false;

    switch (shape.type) {
      case 'arrow':
        this._mapView.addPolygon(shape);
        this._shapes.push(shape);
        return shape;

      case 'marker':
        this._mapView.addMarker(shape);
        this._shapes.push(shape);
        return shape;

      case 'polygon':
        this._mapView.addPolygon(shape);
        this._shapes.push(shape);
        return shape;

      case 'polyline':
        this._mapView.addPolyline(shape);
        this._shapes.push(shape);
        return shape;

      case 'rectangle':
        this._mapView.addPolygon(shape);
        this._shapes.push(shape);
        return shape;

      case 'circle':
        this._mapView.addCircle(shape);
        this._shapes.push(shape);
        return shape;

      default:
        return null;
    }
  }
}

export function defaultArrowOpts() {
  return {
    fillColor: toColor('black', 0.5),
    fillOpacity: 0.5,
    strokeColor: toColor('black'),
    strokeOpacity: 1,
    strokeWidth: 1,
    visible: true,
    clickable: false,
    zIndex: 0,
    scaleFunction: null,
  };
}

export function defaultMarkerOpts() {
  return {
    title: '',
    snippet: '',
    clickable: false,
    color: null,
    hue: null,
    rotation: 0,
    imgRotation: 0,
    opacity: 1,
    visible: true,
    flat: false,
    icon: null,
    anchor: [0.5, 1],
  };
}

export function defaultPolygonOpts() {
  return {
    fillColor: 'black',
    fillOpacity: 0.5,
    strokeColor: 'black',
    strokeOpacity: 1,
    strokeWidth: 1,
    clickable: false,
    visible: true,
    zIndex: 0,
  };
}

export function defaultPolylineOpts() {
  return {
    visible: true,
    geodesic: true,
    color: 'black',
    opacity: 1,
    width: 5,
    clickable: false,
    zIndex: 0,
    cap: null,
    startCap: null,
    endCap: null,
  };
}

export function defaultCircleOpts() {
  return {
    fillColor: 'black',
    fillOpacity: 0.5,
    strokeColor: 'black',
    strokeOpacity: 1,
    strokeWidth: 1,
    visible: true,
    clickable: false,
    zIndex: 0,
  };
}

function setIfValid(obj, key, val) {
  if (val) {
    obj[key] = val;
  }
}

function createArrow(shapeId, position, bearing, size, options) {
  const opts = { ...defaultArrowOpts(), ...options };

  const pos = toLatLng(position.lat, position.lng);
  const north = moveLatLngBy(pos, size * 0.6, bearing);
  const eastSide = moveLatLngBy(pos, size / 3, 135 + bearing);
  const westSide = moveLatLngBy(pos, size / 3, 225 + bearing);

  const path = [
    [north.latitude, north.longitude],
    [eastSide.latitude, eastSide.longitude],
    [pos.latitude, pos.longitude],
    [westSide.latitude, westSide.longitude],
    [north.latitude, north.longitude],
  ];

  const arrow = createPolygon(shapeId, path, opts);
  arrow.meta = opts.meta || {};
  arrow.type = 'arrow';
  return arrow;
}

function createMarker(shapeId, position, options) {
  const opts = { ...defaultMarkerOpts(), ...options };
  const hue = opts.hue;

  const marker = new GMap.Marker();
  marker.position = toLatLng(position.lat, position.lng);
  marker.zIndex = opts.zIndex;
  marker.title = opts.title;
  marker.snippet = opts.snippet;
  marker.anchor = opts.anchor;
  marker.rotation = opts.rotation;
  marker.alpha = opts.opacity;
  marker.flat = opts.flat;
  marker.visible = opts.visible;

  if (opts.icon) {
    marker._android.icon(createBitmapDescriptor(options.icon, options));
  } else if (hue) {
    if (hue >= 0 && hue < 360) {
      marker._android.icon(Google.model.BitmapDescriptorFactory.defaultMarker(hue));
    } else {
      console.error(`[ShapeManager] Invalid marker hue '${hue}' not within [0, 360)`);
    }
  }

  marker.meta = opts.meta || {};
  marker.shapeId = shapeId;
  marker.type = 'marker';

  return marker;
}

function createCircle(shapeId, center, radius, options) {
  const opts = { ...defaultCircleOpts(), ...options };

  const circle = new GMap.Circle();

  circle.center = toLatLng(center.lat, center.lng);
  circle.radius = radius;
  circle.strokeWidth = opts.strokeWidth;
  setIfValid(circle, 'strokeColor', toColor(opts.strokeColor, opts.strokeOpacity));
  setIfValid(circle, 'fillColor', toColor(opts.fillColor, opts.fillOpacity));
  circle.zIndex = opts.zIndex;
  circle.clickable = opts.clickable || false;
  circle.visible = opts.visible;

  circle.meta = opts.meta || {};
  (circle.shapeId = shapeId), (circle.type = 'circle');

  return circle;
}

function createRectangle(shapeId, bounds, options) {
  const path = [
    // lat, lng
    [bounds.north, bounds.west],
    [bounds.north, bounds.east],
    [bounds.south, bounds.east],
    [bounds.south, bounds.west],
    [bounds.north, bounds.west],
  ];

  const rect = createPolygon(shapeId, path, options);
  rect.type = 'rectangle';
  return rect;
}

function createPolygon(shapeId, path, options) {
  const opts = { ...defaultPolygonOpts(), ...options };

  const polygon = new GMap.Polygon();
  path.forEach(([lat, lng]) => {
    polygon.addPoint(toLatLng(lat, lng));
  });

  setIfValid(polygon, 'strokeColor', toColor(opts.strokeColor, opts.strokeOpacity));
  setIfValid(polygon, 'fillColor', toColor(opts.fillColor, opts.fillOpacity));
  polygon.strokeWidth = opts.strokeWidth;
  polygon.clickable = opts.clickable || false;
  polygon.zIndex = opts.zIndex || 0;
  polygon.visible = opts.visible;

  polygon.meta = opts.meta || {};
  polygon.shapeId = shapeId;
  polygon.type = 'polygon';

  return polygon;
}

function createPolyline(shapeId, path, options) {
  const opts = { ...defaultPolylineOpts(), ...options };

  const polyline = new GMap.Polyline();

  path.forEach(([lat, lng]) => {
    polyline.addPoint(toLatLng(lat, lng));
  });

  polyline.visible = opts.visible || true;
  polyline.geodesic = opts.geodesic || true;

  setCap(polyline, 'startCap', opts.startCap || opts.cap);
  setCap(polyline, 'endCap', opts.endCap || opts.cap);

  setIfValid(polyline, 'color', toColor(opts.color, opts.opacity));

  polyline.width = opts.width;
  polyline.clickable = opts.clickable || false;
  polyline.zIndex = opts.zIndex || 0;

  polyline.meta = opts.meta || {};
  polyline.shapeId = shapeId;
  polyline.type = 'polyline';

  return polyline;
}

function setCap(polyline, position, capOpts) {
  const cap = getCap(capOpts);
  if (!cap) {
    return;
  }

  polyline.android[position](cap);
}

function getCap(opts) {
  if (!opts) {
    return null;
  }

  if (typeof opts === 'object') {
    const descriptor = createBitmapDescriptor(opts.path, opts);
    return new Google.model.CustomCap(descriptor, opts.width || 10);
  }

  switch (opts) {
    case 'butt':
      return new Google.model.ButtCap();
    case 'round':
      return new Google.model.RoundCap();
    case 'square':
      return new Google.model.SquareCap();
  }

  return null;
}
