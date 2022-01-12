<template>
  <div ref="container" style="display: none">
    <div class="gmap-legend-control" ref="legend" :class="positionClass" :g-position="position">
      <div class="legend-element" v-for="(item, index) in value" :key="index">
        <div class="checkbox" @click="onSelect(item)">
          <input type="checkbox" :checked="item.selected" />
        </div>
        <div class="square" :style="`background-color: ${item.color}`"></div>
        {{ item.label }}
      </div>
    </div>
  </div>
</template>

<script>
import { MapElementFactory } from 'gmap-vue';

class Capture {
  constructor(map, google) {
    this.map = map;
    this.google = google;
  }
}

export default MapElementFactory({
  name: 'GMapLegend',
  mappedProps: {},
  events: [],
  ctr: () => Capture,
  ctrArgs: (opts, _props) => [opts.map, google],
  afterCreate({ map, google }) {
    this.init(map, google);
  },
  // normal vue data
  props: {
    value: { type: Array, default: () => [] },
    position: { type: String, default: 'LEFT' },
    selectable: { type: Boolean, default: false },
  },
  data: () => {
    return {
      map: null,
      google: null,
      legend: null,
    };
  },
  computed: {
    positionClass() {
      const value = this.position.toLowerCase().split('_');
      const primary = value[0];
      const secondary = value[1];

      return [`primary-${primary}`, `secondary-${secondary}`];
    },
  },
  beforeDestroy() {
    this.resetLegend();
  },
  methods: {
    init(map, google) {
      this.map = map;
      this.google = google;
      this.setLegend();
    },
    resetLegend() {
      // moves the legend out of the googleControl pane and back into component
      if (this.legend) {
        const googlePane = this.google.maps.ControlPosition[this.position];
        const googleControls = this.map.controls[googlePane];
        const index = googleControls.getArray().indexOf(this.legend);
        if (index !== -1) {
          googleControls.removeAt(index);
          const parent = this.$refs['container'];
          if (parent) {
            parent.appendChild(this.legend);
          } else {
            this.legend = null;
          }
        }
      }
    },
    setLegend() {
      this.resetLegend();
      // mount legend
      const legend = this.$refs['legend'];

      const googlePane = this.google.maps.ControlPosition[this.position];
      this.map.controls[googlePane].push(legend);
      this.legend = legend;
    },
    onSelect(item) {
      this.$emit('select', item);
    },
  },
});
</script>

<style>
.gmap-legend-control {
  color: white;
  font-family: Roboto, Arial, sans-serif;
  background-color: rgba(0, 0, 0, 0.8);
  padding: 0.5rem;
  display: flex;
  flex-wrap: wrap;
  width: auto;
  height: auto;
}

.gmap-legend-control .legend-element {
  font-size: 0.9rem;
  line-height: 1rem;
  display: flex;
  padding: 0 0.25rem;
}

.gmap-legend-control .legend-element .square {
  margin: auto 0.2rem;
  margin-right: 0.3rem;
  height: 0.75rem;
  width: 0.75rem;
  border: 1px solid gray;
}

.gmap-legend-control .legend-element .checkbox {
  cursor: pointer;
}

.gmap-legend-control .legend-element .checkbox input[type='checkbox'] {
  pointer-events: none;
}

/* position specific attributes */
.gmap-legend-control.primary-top {
  margin-top: 10px;
}

.gmap-legend-control.primary-bottom {
  margin-bottom: 10px;
}

.gmap-legend-control.primary-left {
  margin-left: 10px;
  flex-direction: column;
}

.gmap-legend-control.primary-right {
  margin-right: 10px;
  flex-direction: column;
}

.gmap-legend-control.secondary-left {
  margin-right: 4rem;
}

.gmap-legend-control.secondary-right {
  margin-left: 4rem;
}
</style>