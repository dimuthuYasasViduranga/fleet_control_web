<template>
  <div
    class="chat-button-floating"
    :style="`${transform}`"
    @mousedown="onMouseDown"
    @mouseup="onMouseUp"
  >
    <div class="outer-circle-wrapper">
      <div class="outer-circle">
        <ChatButton :clickable="false" />
      </div>
    </div>
  </div>
</template>

<script>
import ChatButton from './ChatButton.vue';

const OFFSET = 37;
const LONG_PRESS_PERIOD = 500;

function getPosition(event, width, height) {
  const position = {
    top: null,
    bottom: null,
    left: null,
    right: null,
  };
  const { x, y } = event;

  if (x < width / 2) {
    position.left = x;
  } else {
    position.right = width - x - OFFSET;
  }

  if (y < height / 2) {
    position.top = y;
  } else {
    position.bottom = height - y - OFFSET;
  }

  return position;
}

export default {
  name: 'ChatButtonFloating',
  components: {
    ChatButton,
  },
  data: () => {
    return {
      mouseDownTimeout: null,
      moved: false,
      width: 0,
      height: 0,
      top: null,
      left: null,
      right: 50,
      bottom: 75,
    };
  },
  computed: {
    transform() {
      const vertical = this.top == null ? `bottom: ${this.bottom}px` : `top: ${this.top}px`;
      const horizontal = this.left == null ? `right: ${this.right}px` : `left: ${this.left}px`;
      return `${vertical}; ${horizontal};`;
    },
  },
  beforeDestroy() {
    this.clearMouseDownTimeout();
    this.clearListeners();
  },
  methods: {
    open() {
      const options = {
        scroll: 'bottom',
        assetId: 'all',
      };
      this.$eventBus.$emit('chat-open', options);
    },
    onMouseDown() {
      this.moved = false;
      this.setMouseDownTimeout();
    },
    setMouseDownTimeout() {
      this.clearMouseDownTimeout();
      this.mouseDownTimeout = setTimeout(() => {
        this.height = window.innerHeight;
        this.width = window.innerWidth;
        this.setListeners();
      }, LONG_PRESS_PERIOD);
    },
    setListeners() {
      document.addEventListener('mouseup', this.onMouseUp, false);
      document.addEventListener('mousemove', this.onMouseMove, false);
    },
    clearListeners() {
      document.removeEventListener('mousemove', this.onMouseMove);
      document.removeEventListener('mouseup', this.onMouseUp);
    },
    clearMouseDownTimeout() {
      clearTimeout(this.mouseDownTimeout);
    },
    onMouseMove(event) {
      this.moved = true;
      const { top, bottom, left, right } = getPosition(event, this.width, this.height);
      this.top = top;
      this.bottom = bottom;
      this.left = left;
      this.right = right;
    },
    onMouseUp() {
      this.clearMouseDownTimeout();
      this.clearListeners();

      if (!this.moved) {
        this.open();
      }

      this.moved = false;
    },
  },
};
</script>

<style>
.chat-button-floating {
  position: fixed;
  height: 75px;
  width: 75px;
  z-index: 10;
}

.chat-button-floating .outer-circle-wrapper {
  height: 100%;
  width: 100%;
  cursor: pointer;
}

.chat-button-floating .outer-circle {
  padding-top: 0.1rem;
  display: flex;
  text-align: center;
  vertical-align: middle;

  border-radius: 50%;
  border: 1px solid #1b2a33;
  width: 100%;
  height: 100%;
  padding-right: 0.1rem;

  background-color: #0c1419;
  color: black;
  font-weight: bold;
}

@media screen and (max-width: 820px) {
  .chat-button-floating {
    height: 50px;
    width: 50px;
    bottom: 25px;
    right: 25px;
  }

  .chat-button-floating .hx-icon {
    height: 1rem;
    width: 1rem;
  }
}
</style>