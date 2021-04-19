<template>
  <transition
    name="modal"
    @leave="emit('tran-close-start')"
    @after-leave="emit('tran-close-end')"
    @enter="emit('tran-open-start')"
    @after-enter="emit('tran-open-end')"
  >
    <div class="modal-mask" v-show="show" @mousedown="emitClose">
      <div
        ref="modal-container-wrapper"
        class="modal-container-wrapper"
        @keyup.esc="onEsc"
        tabindex="0"
      >
        <div class="modal-container" @mousedown.stop @click.stop>
          <slot></slot>
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'Modal',
  props: {
    show: { type: Boolean, default: false },
    allowScrollLock: { type: Boolean, default: true },
    escToClose: { type: Boolean, default: true },
  },
  data: () => {
    return {
      originalPos: { x: 0, y: 0 },
    };
  },
  watch: {
    show: {
      immediate: true,
      handler(doShow) {
        // focus the modal (to allow for esc closure)
        if (doShow === true) {
          this.$nextTick(() => {
            this.$refs['modal-container-wrapper'].focus();
          });
        }

        if (this.allowScrollLock === true) {
          if (doShow === true) {
            this.enableScrollLock();
          } else {
            this.disableScrollLock();
          }
        }
      },
    },
  },
  beforeDestroy() {
    this.disableScrollLock();
  },
  methods: {
    emit(topic) {
      this.$emit(topic);
    },
    emitClose() {
      this.emit('close');
    },
    enableScrollLock() {
      const scrollBarWidth = window.innerWidth - document.documentElement.clientWidth;
      document.body.style.marginRight = `${scrollBarWidth}px`;
      document.body.classList.add('hx-modal-scroll-lock');
    },
    disableScrollLock() {
      document.body.style.marginRight = 0;
      document.body.classList.remove('hx-modal-scroll-lock');
    },
    onEsc() {
      this.emitClose();
    },
  },
};
</script>

<style>
.hx-modal-scroll-lock {
  overflow: hidden;
}

/* --------------------- modal structure classes --------------------- */
.modal-mask {
  position: fixed;
  z-index: 9998;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  transition: opacity 0.3s ease;
  overflow: auto;
  color: #b6c3cc;
  font-family: 'GE Inspira Sans', sans-serif;
}

.modal-container-wrapper {
  outline: none;
  vertical-align: middle;
  padding: 4% 10%;
}

.modal-container {
  width: 100%;
  /* this prevents scroll bars flashing */
  height: 98%;
  margin: 0px auto;
  padding: 2rem 2rem;
  background-color: #23343f;
  border-radius: 0px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.33);
  transition: all 0.3s ease;
}

/* ---------------------- modal transitions -----------------------*/
.modal-enter {
  opacity: 0;
}

.modal-leave-active {
  opacity: 0;
}

.modal-enter .modal-container,
.modal-leave-active .modal-container {
  -webkit-transform: scale(1.1);
  transform: scale(1.1);
}
</style>