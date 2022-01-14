<template>
  <div class="gmap-drag-region">
    <gmap-rectangle
      ref="bounds"
      :bounds="mapBounds"
      :options="{
        strokeWeight: 0,
        fillOpacity: 0,
        zIndex,
      }"
      :editable="false"
      :draggable="false"
      @mousemove="onMouseMove"
      @hook:mounted="onMounted"
    />

    <gmap-rectangle
      v-if="dragBounds"
      :bounds="dragBounds"
      :editable="false"
      :draggable="false"
      :options="{ ...(options || {}), zIndex: zIndex - 1 }"
    />
  </div>
</template>

<script>
import { MapElementFactory } from 'gmap-vue';

const MAP_BOUNDS = {
  north: 90,
  south: -90,
  west: -180,
  east: 180,
};

function eventToPos({ latLng }) {
  return {
    lat: latLng.lat(),
    lng: latLng.lng(),
  };
}

function toBounds(a, b) {
  const [latMin, latMax] = [a.lat, b.lat].sort((a, b) => a - b);
  const [lngMin, lngMax] = [a.lng, b.lng].sort((a, b) => a - b);

  return {
    north: latMax,
    south: latMin,
    west: lngMin,
    east: lngMax,
  };
}

export default MapElementFactory({
  name: 'GMapDragRegion',
  mappedProps: {},
  props: {
    on: { type: String, default: 'click' },
    options: { type: Object },
    zIndex: { type: Number, default: 1000 },
  },
  events: [],
  ctr: () => class Capture {},
  data: () => {
    return {
      mapBounds: MAP_BOUNDS,
      start: null,
      end: null,
      listner: null,
    };
  },
  computed: {
    dragBounds() {
      if (!this.start || !this.end) {
        return;
      }

      return toBounds(this.start, this.end);
    },
  },
  beforeDestroy() {
    this.removeListener();
  },
  methods: {
    onMounted() {
      const ref = this.$refs.bounds;
      ref.$rectanglePromise.then(r => {
        this.listener = google.maps.event.addListener(r, this.on, this.onTrigger);
      });
    },
    removeListener() {
      google.maps.event.removeListener(this.listener);
      this.start = null;
      this.end = null;
    },
    onTrigger(event) {
      const pos = eventToPos(event);

      if (!this.start) {
        this.start = pos;
      } else {
        this.$emit('select', toBounds(this.start, pos));
        this.start = null;
        this.end = null;
      }
    },
    onMouseMove(event) {
      if (this.start) {
        this.end = eventToPos(event);
      }
    },
  },
});
</script>