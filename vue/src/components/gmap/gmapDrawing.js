const VALID_MODES = [undefined, null, 'marker', 'circle', 'rectangle', 'polygon', 'polyline'];

function createMarker(overlay) {
  const position = overlay.position;
  return {
    type: 'marker',
    props: {
      position: {
        lat: position.lat(),
        lng: position.lng(),
      },
    },
  };
}

function createCircle(overlay) {
  const center = overlay.center;
  const radius = overlay.radius;
  return {
    type: 'circle',
    props: {
      radius,
      center: {
        lat: center.lat(),
        lng: center.lng(),
      },
    },
  };
}

function createRectangle(overlay) {
  const bounds = overlay.getBounds();
  const northEast = bounds.getNorthEast();
  const southWest = bounds.getSouthWest();
  return {
    type: 'rectangle',
    props: {
      bounds: {
        north: northEast.lat(),
        south: southWest.lat(),
        east: northEast.lng(),
        west: southWest.lng(),
      },
    },
  };
}

function createPolygon(overlay) {
  const path = overlay
    .getPath()
    .getArray()
    .map(e => {
      return {
        lat: e.lat(),
        lng: e.lng(),
      };
    });

  return {
    type: 'polygon',
    props: { path },
  };
}

function createPolyline(overlay) {
  const path = overlay
    .getPath()
    .getArray()
    .map(e => {
      return {
        lat: e.lat(),
        lng: e.lng(),
      };
    });

  return {
    type: 'polyline',
    props: { path },
  };
}

function deleteShape(shape) {
  shape.setMap(null);
}

export class DrawingManager {
  constructor(map, google) {
    this.map = map;
    this.google = google;
    this._onOverlayComplete = () => null;
    this._gdm = null;

    const gdm = new google.maps.drawing.DrawingManager({
      drawingMode: null,
      drawingControl: false,
      drawingControlOptions: {
        drawingModes: VALID_MODES,
      },
    });

    // bind overlay complete event
    google.maps.event.addListener(gdm, 'overlaycomplete', event => {
      this._addOverlay(event);
    });

    // bind to a map
    gdm.setMap(map);

    this._gdm = gdm;
  }

  setOnOverlayComplete(callback) {
    this._onOverlayComplete = callback;
  }

  setDrawingMode(mode) {
    if (VALID_MODES.includes(mode)) {
      this._gdm.setDrawingMode(mode);
    } else {
      console.error(`[GMapDrawing] Invalid mode '${mode}'`);
    }
  }

  getDrawingMode() {
    return this._gdm.getDrawingMode();
  }

  _addOverlay({ type, overlay }) {
    switch (type) {
      case 'marker':
        const marker = createMarker(overlay);
        this._onOverlayComplete(marker);
        break;

      case 'circle':
        const circle = createCircle(overlay);
        this._onOverlayComplete(circle);
        break;

      case 'rectangle':
        const rectangle = createRectangle(overlay);
        this._onOverlayComplete(rectangle);
        break;

      case 'polygon':
        const polygon = createPolygon(overlay);
        this._onOverlayComplete(polygon);
        break;

      case 'polyline':
        const polyline = createPolyline(overlay);
        this._onOverlayComplete(polyline);
        break;

      default:
        console.error(`[GMapDrawing] Unknown overlay type ${type}`);
    }

    deleteShape(overlay);
  }
}
