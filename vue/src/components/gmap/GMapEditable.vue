<template>
  <div class="gmap-editable">
    <div id="__g_edit_hidden" style="display: none">
      <div class="g-edit-controls">
        <svg
          v-if="showIcon"
          class="item edit-icon"
          :class="{ editing: edit }"
          viewBox="0 0 128 128"
          @click="setEdit(!edit)"
        >
          <path
            d="M 18.790107,31.442234 30.823932,19.533409 49.474951,30.949593 29.764349,50.748583 Z"
            id="eraser"
          />
          <path
            id="body"
            d="M 49.474951,30.949593 100.75,81.625 80.000001,102.375 29.764349,50.748583"
          />
          <path id="tip" d="M 80.000001,102.375 109.875,112 100.75,81.625 Z" />
        </svg>
        <svg v-if="edit" class="item accept-icon" viewBox="0 0 128 128" @click="onAction('accept')">
          <path d="M 17.044969,76.907624 46.139158,105.35527 108.8533,19.365784" />
        </svg>
        <svg v-if="edit" class="item reject-icon" viewBox="0 0 128 128" @click="onAction('reject')">
          <path d="M 17.132589,15.318591 114.03571,114.46226" />
          <path d="M 114.03571,15.878725 17.132589,114.46226" />
        </svg>
      </div>
    </div>
    <div v-if="edit" class="shapes">
      <gmap-marker
        v-for="(marker, index) in lMarkers"
        :key="`marker-${index}`"
        :position="marker.position"
        :options="{
          clickable: true,
          visible: !marker.deleted,
          zIndex,
        }"
        :draggable="true"
        @dragend="onUpdateMarker(marker, $event)"
        @rightclick="marker.deleted = true"
      />
      <gmap-circle
        v-for="(circle, index) in lCircles"
        :key="`circle-${index}`"
        :center="circle.center"
        :radius="circle.radius"
        :options="{
          clickable: true,
          visible: !circle.deleted,
          zIndex,
        }"
        :editable="!clickToEdit || circle.editable"
        :draggable="true"
        @dragstart="onDragStart(circle, $event)"
        @dragend="onCircleDragEnd(circle, $event)"
        @radius_changed="e => (circle.radius = e)"
        @click="circle.editable = !circle.editable"
        @rightclick="circle.deleted = true"
        @center_changed="onCircleCenterChanged(circle, $event)"
      />
      <gmap-rectangle
        v-for="(rect, index) in lRectangles"
        :key="`rectangle-${index}`"
        :bounds="rect.bounds"
        :options="{
          clickable: true,
          visible: !rect.deleted,
          zIndex,
        }"
        :editable="true"
        :draggable="true"
        @dragstart="onDragStart(rect, $event)"
        @dragend="onRectDragEnd(rect, $event)"
        @bounds_changed="onRectBoundsChange(rect, $event)"
        @rightclick="rect.deleted = true"
      />
      <gmap-polygon
        v-for="(poly, index) in lPolygons"
        :key="`polygon-${index}`"
        :path="poly.path"
        :options="{
          clickable: true,
          visible: !poly.deleted,
          zIndex,
        }"
        :editable="true"
        :draggable="true"
        @dragstart="onDragStart(poly, $event)"
        @dragend="onPolyDragEnd(poly, $event)"
        @path_changed="onPolyPathChanged(poly, $event)"
        @rightclick="onPolyRightClick(poly, lPolygons, $event, 3)"
      />
      <gmap-polyline
        v-for="(poly, index) in lPolylines"
        :key="`polyline-${index}`"
        :path="poly.path"
        :options="{
          clickable: true,
          visible: !poly.deleted,
          strokeWeight: poly.width,
          strokeColor: poly.color,
          zIndex,
        }"
        :draggable="true"
        :editable="true"
        @dragstart="onDragStart(poly, $event)"
        @dragend="onPolyDragEnd(poly, $event)"
        @path_changed="onPolyPathChanged(poly, $event)"
        @rightclick="onPolyRightClick(poly, lPolylines, $event, 2)"
      />
    </div>
  </div>
</template> 
 
<script>
import { MapElementFactory } from 'gmap-vue';

function copyMarker(marker) {
  return {
    id: marker.id,
    position: {
      lat: marker.position.lat,
      lng: marker.position.lng,
    },
    deleted: marker.deleted || false,
    editable: false,
  };
}

function copyCircle(circle) {
  return {
    id: circle.id,
    radius: circle.radius,
    center: {
      lat: circle.center.lat,
      lng: circle.center.lng,
    },
    deleted: circle.deleted || false,
    editable: false,
  };
}

function copyRectangle(rectangle) {
  return {
    id: rectangle.id,
    bounds: {
      north: rectangle.bounds.north,
      south: rectangle.bounds.south,
      east: rectangle.bounds.east,
      west: rectangle.bounds.west,
    },
    deleted: rectangle.deleted || false,
    editable: false,
  };
}

function copyPolygon(polygon) {
  const path = polygon.path.map(e => {
    return { lat: e.lat, lng: e.lng };
  });
  return {
    id: polygon.id,
    path,
    editable: false,
    deleted: polygon.deleted || false,
  };
}

function copyPolyline(polyline) {
  const path = polyline.path.map(e => {
    return { lat: e.lat, lng: e.lng };
  });
  return {
    id: polyline.id,
    path,
    color: polyline.color,
    width: polyline.width,
    editable: false,
    deleted: polyline.deleted || false,
  };
}

function convertBounds(bounds) {
  const northEast = bounds.getNorthEast();
  const southWest = bounds.getSouthWest();
  return {
    north: northEast.lat(),
    south: southWest.lat(),
    east: northEast.lng(),
    west: southWest.lng(),
  };
}

function convertLatLng(latLng) {
  return {
    lat: latLng.lat(),
    lng: latLng.lng(),
  };
}

class Capture {
  constructor(map, google) {
    this.map = map;
    this.google = google;
  }
}

export default MapElementFactory({
  name: 'GMapEditable',
  // map element facotry data
  mappedProps: {},
  events: [],
  ctr: () => Capture,
  ctrArgs: (opts, _props) => [opts.map, google],
  afterCreate({ map, google }) {
    this.init(map, google);
  },
  // normal vue data
  props: {
    edit: { type: Boolean, default: () => [] },
    clickToEdit: { type: Boolean, default: false },
    showIcon: { type: Boolean, default: true },
    closeOnAction: { type: Boolean, default: true },
    zIndex: { type: Number, default: 0 },
    position: { type: String, default: 'LEFT' },
    direction: { type: String, default: 'horizontal' },
    markers: { type: Array, default: () => [] },
    circles: { type: Array, default: () => [] },
    rectangles: { type: Array, default: () => [] },
    polygons: { type: Array, default: () => [] },
    polylines: { type: Array, default: () => [] },
  },
  components: {
    // GMapCircle,
  },
  data: () => {
    return {
      lMarkers: [],
      lCircles: [],
      lRectangles: [],
      lPolygons: [],
      lPolylines: [],
      google: null,
      map: null,
      controls: null,
    };
  },
  watch: {
    edit: {
      immediate: true,
      handler(value) {
        if (value) {
          this.loadInputs();
        }
      },
    },
    position() {
      this.setControls();
    },
    direction() {
      this.setControls();
    },
    markers(markers) {
      this.lMarkers = markers.map(copyMarker);
    },
    circles(circles) {
      this.lCircles = circles.map(copyCircle);
    },
    rectangles(rectangles) {
      this.lRectangles = rectangles.map(copyRectangle);
    },
    polygons(polygons) {
      this.lPolygons = polygons.map(copyPolygon);
    },
    polylines(polylines) {
      this.lPolylines = polylines.map(copyPolyline);
    },
  },
  beforeDestroy() {
    this.resetControls();
  },
  methods: {
    init(map, google) {
      this.map = map;
      this.google = google;

      this.setControls();
    },
    resetControls() {
      // moves the controls out of the googleControl pane and back into component
      if (this.controls) {
        const googlePane = this.google.maps.ControlPosition[this.position];
        const googleControls = this.map.controls[googlePane];
        const index = googleControls.getArray().indexOf(this.controls);
        if (index !== -1) {
          googleControls.removeAt(index);
          const parent = document.getElementById('__g_edit_hidden');
          if (parent) {
            parent.appendChild(this.controls);
          } else {
            this.controls = null;
          }
        }
      }
    },
    setControls() {
      this.resetControls();
      // mount controls
      const controls = document.querySelector('.g-edit-controls');
      controls.classList.remove(['vertical', 'horizontal']);
      controls.classList.add(this.direction);

      const googlePane = this.google.maps.ControlPosition[this.position];
      this.map.controls[googlePane].push(controls);
      this.controls = controls;
    },
    loadInputs() {
      this.lMarkers = this.markers.map(copyMarker);
      this.lCircles = this.circles.map(copyCircle);
      this.lRectangles = this.rectangles.map(copyRectangle);
      this.lPolygons = this.polygons.map(copyPolygon);
      this.lPolylines = this.polylines.map(copyPolyline);
    },
    setEdit(state) {
      this.$emit('update:edit', state);
    },
    onAction(action) {
      if (this.closeOnAction) {
        this.setEdit(false);
      }

      const payload = {
        markers: this.lMarkers.map(copyMarker),
        circles: this.lCircles.map(copyCircle),
        rectangles: this.lRectangles.map(copyRectangle),
        polygons: this.lPolygons.map(copyPolygon),
        polylines: this.lPolylines.map(copyPolyline),
      };

      this.$emit(action, payload);
    },
    onDelete(shape) {
      shape.deleted = true;
    },
    onUpdateMarker(marker, event) {
      marker.position = convertLatLng(event.latLng);
    },
    onDragStart(shape, event) {
      shape.mouseStart = convertLatLng(event.latLng);
    },
    onCircleCenterChanged(circle, latLng) {
      if (circle.centerChanged) {
        delete circle.centerChanged;
      } else if (circle.moveComplete) {
        delete circle.moveComplete;
      } else if (!circle.mouseStart) {
        const mouseEnd = convertLatLng(latLng);
        circle.center = { ...mouseEnd };
        circle.centerChanged = true;
      }
    },
    onCircleDragEnd(circle, event) {
      const mouseEnd = convertLatLng(event.latLng);

      if (circle.mouseStart) {
        const deltaLat = mouseEnd.lat - circle.mouseStart.lat;
        const deltaLng = mouseEnd.lng - circle.mouseStart.lng;

        circle.center = {
          lat: circle.center.lat + deltaLat,
          lng: circle.center.lng + deltaLng,
        };
      }

      circle.moveComplete = true;
      delete circle.mouseStart;
    },
    onRectDragEnd(rect, event) {
      const mouseEnd = convertLatLng(event.latLng);

      if (rect.mouseStart) {
        const deltaLat = mouseEnd.lat - rect.mouseStart.lat;
        const deltaLng = mouseEnd.lng - rect.mouseStart.lng;

        rect.bounds = {
          north: rect.bounds.north + deltaLat,
          south: rect.bounds.south + deltaLat,
          east: rect.bounds.east + deltaLng,
          west: rect.bounds.west + deltaLng,
        };
      }

      delete rect.mouseStart;
    },
    onRectBoundsChange(rect, event) {
      if (rect.mouseStart) {
        return;
      }

      if (rect.justUpdated) {
        delete rect.justUpdated;
        return;
      }

      const bounds = convertBounds(event);
      rect.bounds = bounds;
      rect.justUpdated = true;
    },
    onPolyDragEnd(polygon, event) {
      const mouseEnd = convertLatLng(event.latLng);

      if (polygon.mouseStart) {
        const deltaLat = mouseEnd.lat - polygon.mouseStart.lat;
        const deltaLng = mouseEnd.lng - polygon.mouseStart.lng;

        const path = polygon.path.map(i => {
          return {
            lat: i.lat + deltaLat,
            lng: i.lng + deltaLng,
          };
        });

        polygon.path = path;
        delete polygon.mouseStart;
      }
    },
    onPolyPathChanged(polygon, event) {
      if (polygon.mouseStart) {
        return;
      }

      const path = event.getArray().map(convertLatLng);

      polygon.path = path;
      polygon.justUpdated = true;
    },
    onPolyRightClick(poly, polyList, event, minVertices) {
      if (event.vertex !== undefined) {
        if (poly.path.length > minVertices) {
          poly.path.splice(event.vertex, 1);
        } else {
          poly.deleted = true;
        }
      }
    },
  },
});
</script> 
 
<style>
.g-edit-controls {
  display: flex;
  margin: 10px;
  height: 40px;
  width: auto;
}

.g-edit-controls.vertical {
  flex-direction: column;
  height: auto;
  width: 40px;
}

.g-edit-controls .item {
  cursor: pointer;
  stroke: gray;
  fill: none;
  stroke-width: 6;
  background-color: white;
  border-radius: 2px;
  padding: 8px;
  height: 40px;
  width: 40px;
}

.g-edit-controls .edit-icon {
  fill: rgb(192, 192, 192);
}

.g-edit-controls .edit-icon.editing {
  stroke: black;
}

.g-edit-controls .accept-icon:hover {
  stroke: green;
}

.g-edit-controls .reject-icon:hover {
  stroke: red;
}
</style>