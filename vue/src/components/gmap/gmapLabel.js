import { MapElementFactory } from 'gmap-vue';

const PROPS = {
  position: {
    type: Object,
    twoWay: true,
    required: true,
  },
  text: {
    type: String,
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

      // Label specific
      const span = (this._span = document.createElement('span'));
      span.style.cssText =
        'position: relative; left: -50%; top: -8px; ' +
        'white-space: nowrap; border: 1px solid blue; ' +
        'padding: 2px; background-color: white';

      var div = (this._div = document.createElement('div'));
      div.appendChild(span);
      div.style.cssText = 'position: absolute; display: none';
    }

    onAdd() {
      var pane = this.getPanes().overlayLayer;
      pane.appendChild(this._div);

      // Ensures the label is redrawn if the text or position is changed.
      var me = this;
      this._listeners = [
        google.maps.event.addListener(this, 'position_changed', function () {
          me.draw();
        }),
        google.maps.event.addListener(this, 'text_changed', function () {
          me.draw();
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

      this._span.innerHTML = this.get('text').toString();
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
  };
}

export default MapElementFactory({
  name: 'GMapLabel',
  events: [],
  mappedProps: PROPS,
  ctr: () => createClass(),
});
