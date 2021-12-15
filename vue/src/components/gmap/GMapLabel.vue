<template>
  <div class="g-map-label">
    <div ref="container" class="g-map-label-container">
      <div class="wrapper" :style="`transform: ${transform}`">
        <slot></slot>
      </div>
    </div>
  </div>
</template>

<script>
import { MapElementFactory } from 'gmap-vue';

const PROPS = {
  position: {
    type: Object,
    twoWay: true,
    required: true,
  },
  zIndex: {
    type: Number,
    default: 500,
  },
};

function createClass() {
  return class Label extends google.maps.OverlayView {
    constructor(opts) {
      super();
      this.setValues(opts);

      const div = document.createElement('div');
      div.style.cssText = 'position: absolute; display: none';

      this._div = div;
    }

    onAdd() {
      const pane = this.getPanes().overlayLayer;
      pane.appendChild(this._div);

      const that = this;
      this._listeners = [
        google.maps.event.addListener(this, 'position_changed', function () {
          that.draw();
        }),
      ];
    }

    onRemove() {
      this._div.parentNode.removeChild(this._div);

      // Label is removed from the map, stop updating its position/text.
      for (var i = 0, I = this._listeners.length; i < I; ++i) {
        google.maps.event.removeListener(this._listeners[i]);
      }
    }

    draw() {
      var projection = this.getProjection();
      var position = projection.fromLatLngToDivPixel(this.get('position'));

      var div = this._div;
      div.style.left = position.x + 'px';
      div.style.top = position.y + 'px';
      div.style.display = 'block';
    }

    setPosition(pos) {
      this.set('position', pos);
    }

    setText(text) {
      this.set('text', text);
    }

    setZIndex(val) {
      if (this._div) {
        this._div.style.zIndex = val;
      }
      this.set('zIndex', val);
    }

    setSlot(val) {
      this._div.appendChild(val);
    }
  };
}

export default MapElementFactory({
  name: 'GMapLabel',
  events: [],
  mappedProps: PROPS,
  props: {
    anchor: { type: Number, default: 0.5 },
  },
  ctr: () => createClass(),
  afterCreate(label) {
    label.setSlot(this.$refs.container);
  },
  computed: {
    transform() {
      const yOffset = this.anchor * 100;
      return `translate(-${yOffset.toFixed(1)}%, 0)`;
    },
  },
});
</script>

<style>
.g-map-label-container > .wrapper {
  position: absolute;
}
</style>