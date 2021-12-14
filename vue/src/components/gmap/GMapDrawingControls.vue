<template>
  <div style="display: none">
    <div ref="drawing-controls" class="drawing-controls" v-show="show">
      <svg
        class="drawing-mode hand-mode"
        v-tooltip="{
          classes: ['google-tooltip'],
          trigger: 'hover',
          content: 'Pan',
          placement: 'bottom',
        }"
        :class="{ selected: !mode }"
        viewBox="0 0 128 128"
        @click="setMode(null)"
      >
        <path
          d="M 49.214467,117.63173 43.557613,94.532486 19.5,67.999999 v -9.25 l 5.625,-5.625 20.750001,15.375 L 30,34.624999 l 0.75,-6.125 8.875,-4.125 5.625001,3.125 c 0,0 8.5,23.75 8.5,22.5 l -1.767767,-32.75 3.15901,-2.924175 9.110597,-0.126301 3.582645,3.149588 3.665515,32.650888 3.375,-28.25 3.46875,-3.28125 8.46875,0.71875 2.9375,3.4375 2.5,33.125 3.499999,-21.5 10.29289,4.664214 0.70711,22.835786 -15.941384,34.442121 -4.265722,21.77539"
        />
      </svg>
      <svg
        v-if="showMode.marker"
        v-tooltip="{
          classes: ['google-tooltip'],
          trigger: 'hover',
          content: 'Marker',
          placement: 'bottom',
        }"
        class="drawing-mode marker-mode"
        :class="{ selected: mode === 'marker', 'hard-selected': hardMode === 'marker' }"
        viewBox="0 0 128 128"
        @click="setMode('marker')"
      >
        <path
          d="M 63.82644,119.11176 C 63.148602,113.12028 60.287241,104.66101 56.213881,96.60597 52.968949,90.189138 51.027129,86.865948 43.735946,75.251495 38.341763,66.65886 36.495377,63.484338 34.302186,59.031876 29.748764,49.787839 28.499364,43.723593 29.593955,36.179383 c 0.627999,-4.328338 1.951525,-8.117864 4.278894,-12.251355 2.680983,-4.761521 7.270378,-9.475903 12.089762,-12.419009 3.823673,-2.3350451 8.225453,-3.9361696 12.877888,-4.6842637 2.370698,-0.3811995 8.062023,-0.3811995 10.43272,0 4.606076,0.7406398 9.117159,2.380884 12.87789,4.6824397 4.472627,2.737236 8.97173,7.207746 11.538093,11.46477 3.198782,5.306062 4.828696,10.576008 5.178376,16.743079 0.430824,7.598138 -2.554861,15.976587 -10.194714,28.608474 -0.867595,1.434498 -3.41182,5.542383 -5.653835,9.12863 -7.25707,11.608157 -10.369957,17.160695 -13.326753,23.771282 -2.54719,5.69482 -4.650517,12.58104 -5.323763,17.42981 -0.108923,0.78449 -0.250811,1.42635 -0.315301,1.42635 -0.06449,0 -0.166536,-0.43561 -0.226772,-0.96803 z"
        />
      </svg>
      <svg
        v-if="showMode.circle"
        v-tooltip="{
          classes: ['google-tooltip'],
          trigger: 'hover',
          content: 'Circle',
          placement: 'bottom',
        }"
        class="drawing-mode circle-mode"
        :class="{ selected: mode === 'circle', 'hard-selected': hardMode === 'circle' }"
        viewBox="0 0 128 128"
        @click="setMode('circle')"
      >
        <circle cx="64" cy="64" r="56" />
      </svg>
      <svg
        v-if="showMode.rectangle"
        v-tooltip="{
          classes: ['google-tooltip'],
          trigger: 'hover',
          content: 'Rectangle',
          placement: 'bottom',
        }"
        class="drawing-mode rectangle-mode"
        :class="{ selected: mode === 'rectangle', 'hard-selected': hardMode === 'rectangle' }"
        viewBox="0 0 128 128"
        @click="setMode('rectangle')"
      >
        <rect width="96" height="96" x="16" y="16" />
      </svg>
      <svg
        v-if="showMode.polygon"
        v-tooltip="{
          classes: ['google-tooltip'],
          trigger: 'hover',
          content: 'Polygon',
          placement: 'bottom',
        }"
        class="drawing-mode polygon-mode"
        :class="{ selected: mode === 'polygon', 'hard-selected': hardMode === 'polygon' }"
        viewBox="0 0 128 128"
        @click="setMode('polygon')"
      >
        <path d="m 32.000001,96 -16,-72.000001 L 64.000001,64 112,47.999999 V 112 Z" />
      </svg>
      <svg
        v-if="showMode.polyline"
        v-tooltip="{
          classes: ['google-tooltip'],
          trigger: 'hover',
          content: 'Polyline',
          placement: 'bottom',
        }"
        class="drawing-mode polyline-mode"
        :class="{ selected: mode === 'polyline', 'hard-selected': hardMode === 'polyline' }"
        viewBox="0 0 128 128"
        @click="setMode('polyline')"
      >
        <path d="M 16,112 48,32 80,88 112,16" />
      </svg>
    </div>
  </div>
</template> 
 
<script>
import { MapElementFactory } from 'gmap-vue';
import { DrawingManager } from './gmapDrawing.js';

function defaultModes() {
  return ['marker', 'circle', 'rectangle', 'polygon', 'polyline'];
}

export default MapElementFactory({
  name: 'GMapDrawingControls',
  // map element factory data
  events: [],
  mappedProps: {},
  ctr: () => DrawingManager,
  ctrArgs: (opts, _props) => [opts.map, google],
  afterCreate(drawingManager) {
    this.init(drawingManager.map, drawingManager.google, drawingManager);
  },
  // normal vue data
  props: {
    show: { type: Boolean, default: true },
    modes: { type: Array, default: () => defaultModes() },
    position: { type: String, default: 'TOP_CENTER' },
  },
  data: () => {
    return {
      mode: null,
      hardMode: null,
      localShapes: [],
      drawingManager: null,
      controls: null,
    };
  },
  computed: {
    showMode() {
      const lookup = {};
      this.modes.forEach(m => (lookup[m] = true));
      return lookup;
    },
    circles() {
      return this.localShapes.filter(s => s.type === 'circle');
    },
    polygons() {
      return this.localShapes.filter(s => s.type === 'polygon');
    },
  },
  methods: {
    init(map, google, drawingManager) {
      drawingManager.setOnOverlayComplete(this.onOverlayCreate);
      this.drawingManager = drawingManager;

      // mount controls
      const controls = this.$refs['drawing-controls'];

      map.controls[google.maps.ControlPosition[this.position]].push(controls);
      this.controls = controls;
    },
    onOverlayCreate(shape) {
      this.$emit('create', shape);
      if (!this.hardMode) {
        this.setMode(null);
      }
    },
    setMode(mode) {
      if (!mode) {
        this.drawingManager.setDrawingMode(mode);
        this.mode = null;
        this.hardMode = null;
        return;
      }

      if (mode === this.mode) {
        if (mode === this.hardMode) {
          this.hardMode = null;
        } else {
          this.hardMode = mode;
        }
      }

      this.drawingManager.setDrawingMode(mode);
      this.mode = mode;
    },
  },
});
</script> 
 
<style>
.drawing-controls {
  display: flex;
  margin: 10px;
  height: 40px;
}

.drawing-controls .drawing-mode {
  cursor: pointer;
  stroke: gray;
  stroke-width: 15;
  fill: rgb(192, 192, 192);
  background-color: white;
  border-radius: 2px;
  padding: 8px;
  height: 40px;
  width: 40px;
}

.drawing-controls .drawing-mode.selected {
  stroke: black;
}

.drawing-controls .drawing-mode.hard-selected {
  background-color: rgb(192, 192, 192);
}

.drawing-controls .polyline-mode,
.drawing-controls .polyline-mode.selected {
  fill: none;
}

.drawing-controls .hand-mode {
  stroke-width: 6;
  fill: none;
}
</style>