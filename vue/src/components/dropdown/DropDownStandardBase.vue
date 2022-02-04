<script>
import VSelect from 'vue-select';
import 'vue-select/dist/vue-select.css';

const appendToFullscreenOrBody = {
  inserted(el, bindings, { context }) {
    if (context.appendToBody) {
      const { height, top, left, width } = context.$refs.toggle.getBoundingClientRect();
      let scrollX = window.scrollX || window.pageXOffset;
      let scrollY = window.scrollY || window.pageYOffset;
      el.unbindPosition = context.calculatePosition(el, context, {
        width: width + 'px',
        left: scrollX + left + 'px',
        top: scrollY + top + height + 'px',
      });

      const mountOnto =
        document.fullscreenElement || document.webkitCurrentFullScreenElement || document.body;

      if (context.classAnchor) {
        // create a wrapper component to allow class tracking
        const wrapper = document.createElement('div');
        el._wrapper = wrapper;
        wrapper.appendChild(el);

        wrapper.className = context.classAnchor;

        mountOnto.appendChild(wrapper);
      } else {
        mountOnto.appendChild(el);
      }
    }
  },

  unbind(el, bindings, { context }) {
    if (context.appendToBody) {
      if (el.unbindPosition && typeof el.unbindPosition === 'function') {
        el.unbindPosition();
      }

      if (el._wrapper) {
        el._wrapper.parentNode.removeChild(el._wrapper);
        return;
      }

      if (el.parentNode) {
        el.parentNode.removeChild(el);
      }
    }
  },
};

export default {
  name: 'DropDownBase',
  directives: {
    appendToBody: appendToFullscreenOrBody,
  },
  extends: VSelect,
  props: {
    classAnchor: { type: String },
    ignoreMobileComposition: { type: Boolean, default: true },
  },
  methods: {
    onSearchKeyDown(e) {
      const preventAndSelect = e => {
        e.preventDefault();
        return (this.ignoreMobileComposition || !this.isComposing) && this.typeAheadSelect();
      };
      const defaults = {
        //  backspace
        8: () => this.maybeDeleteValue(),
        //  tab
        9: () => this.onTab(),
        //  esc
        27: () => this.onEscape(),
        //  up.prevent
        38: e => {
          e.preventDefault();
          return this.typeAheadUp();
        },
        //  down.prevent
        40: e => {
          e.preventDefault();
          return this.typeAheadDown();
        },
      };
      this.selectOnKeyCodes.forEach(keyCode => (defaults[keyCode] = preventAndSelect));
      const handlers = this.mapKeydown(defaults, this);
      if (typeof handlers[e.keyCode] === 'function') {
        return handlers[e.keyCode](e);
      }
    },
  },
};
</script>

<style>
</style>