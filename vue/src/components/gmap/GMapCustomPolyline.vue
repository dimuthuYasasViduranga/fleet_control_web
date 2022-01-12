<template>
  <div class="g-map-custom-polyline">
    <GMapLabel :position="labelCoord"><slot></slot></GMapLabel>
    <gmap-polyline
      :path="path"
      :options="{
        ...options,
        strokeWeight: borderTotalWeight,
        strokeColor: borderColor,
        zIndex: (this.options.zIndex || 0) - 1,
      }"
    />
  </div>
</template>

<script>
import { haversineDistanceM } from '@/code/distance';
import { chunkEvery } from '@/code/helpers';
import { MapElementFactory } from 'gmap-vue';
import GMapLabel from './GMapLabel.vue';

function toRad(deg) {
  return (deg * Math.PI) / 180;
}

function toDeg(rad) {
  return (rad * 180) / Math.PI;
}

function pointFrom(point, radBearing, distance) {
  const R = 6378100;

  const latA = toRad(point.lat);
  const lngA = toRad(point.lng);
  const AD = distance / R;

  const latB = Math.asin(
    Math.sin(latA) * Math.cos(AD) + Math.cos(latA) * Math.sin(AD) * Math.cos(radBearing),
  );

  const lngB =
    lngA +
    Math.atan2(
      Math.sin(radBearing) * Math.sin(AD) * Math.cos(latA),
      Math.cos(AD) - Math.sin(latA) * Math.sin(latB),
    );

  return {
    lat: toDeg(latB),
    lng: toDeg(lngB),
  };
}

function pointAlong(points, percent = 0) {
  if (percent <= 0) {
    return { ...points[0] };
  }

  if (percent >= 1) {
    return { ...points[points.length - 1] };
  }

  // chunk every
  const { segments, total } = chunkEvery(points, 2, 1, 'discard').reduce(
    (acc, [a, b]) => {
      const distance = haversineDistanceM(a, b);
      const seg = {
        distance,
        positionStart: a,
        positionEnd: b,
        start: acc.total,
        end: acc.total + distance,
      };

      acc.total += distance;
      acc.segments.push(seg);
      return acc;
    },
    { total: 0, segments: [] },
  );

  const target = total * percent;

  const segWithin =
    segments.find(s => target >= s.start && target < s.end) || segments[segments.length - 1];

  const radBearing = bearingBetweenRad(segWithin.positionStart, segWithin.positionEnd);
  const posAlong = pointFrom(segWithin.positionStart, radBearing, target - segWithin.start);
  return posAlong;
}

function bearingBetweenRad(a, b) {
  const latA = toRad(a.lat);
  const lngA = toRad(a.lng);
  const latB = toRad(b.lat);
  const lngB = toRad(b.lng);

  const deltaLng = lngB - lngA;
  const x = Math.cos(latA) * Math.sin(deltaLng);
  const y = Math.cos(latA) * Math.sin(latB) - Math.sin(latA) * Math.cos(latB) * Math.cos(deltaLng);

  return Math.atan2(x, y);
}

const mappedProps = {
  draggable: {
    type: Boolean,
  },
  editable: {
    type: Boolean,
  },
  options: {
    twoWay: false,
    type: Object,
  },
  path: {
    type: Array,
    twoWay: true,
  },
};

const events = [
  'click',
  'dblclick',
  'drag',
  'dragend',
  'dragstart',
  'mousedown',
  'mousemove',
  'mouseout',
  'mouseover',
  'mouseup',
  'rightclick',
];

export default MapElementFactory({
  name: 'GMapCustomPolyline',
  mappedProps,
  props: {
    deepWatch: {
      type: Boolean,
      default: false,
    },
    labelPosition: {
      type: Number,
      default: 0,
    },
  },
  components: {
    GMapLabel,
  },
  events,
  ctr: () => google.maps.Polyline,
  afterCreate() {
    let clearEvents = () => {};

    this.$watch(
      'path',
      path => {
        if (path) {
          clearEvents();

          this.$GMapCustomPolylineObject.setPath(path);

          const mvcPath = this.$GMapCustomPolylineObject.getPath();
          const eventListeners = [];

          const updatePaths = () => {
            this.$emit('path_changed', this.$GMapCustomPolylineObject.getPath());
          };

          eventListeners.push([mvcPath, mvcPath.addListener('insert_at', updatePaths)]);
          eventListeners.push([mvcPath, mvcPath.addListener('remove_at', updatePaths)]);
          eventListeners.push([mvcPath, mvcPath.addListener('set_at', updatePaths)]);

          clearEvents = () => {
            eventListeners.map(([_obj, listenerHandle]) =>
              google.maps.event.removeListener(listenerHandle),
            );
          };
        }
      },
      {
        deep: this.deepWatch,
        immediate: true,
      },
    );
  },
  computed: {
    labelCoord() {
      return pointAlong(this.path, this.labelPosition);
    },
    borderTotalWeight() {
      const borderWeight = this.options.borderWeight;
      if (!borderWeight) {
        return;
      }

      return borderWeight + (this.options.strokeWeight || 5);
    },
    drawBorder() {
      return this.borderTotalWeight > 0;
    },
    borderColor() {
      return this.options.borderColor || 'black';
    },
  },
});
</script>

<style>
</style>