<template>
  <transition :name="modalName" @after-leave="onFullClose" @after-enter="loaded = true">
    <div
      v-show="show"
      class="modal-mask"
      :class="[wrapperClass, component.wrapperClass]"
      @click="onOuterClick()"
    >
      <div
        ref="modal-container-wrapper"
        class="modal-container-wrapper"
        @keyup.esc="onEsc()"
        tabindex="0"
      >
        <div
          class="modal-container"
          @mousedown="setInsideClick()"
          @click.stop="clearInsideClick()"
        >
          <component ref="modal" :is="component" v-bind="componentProps" @close="triggerClose" />
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
import ClickOutside from 'vue-click-outside';
export default {
  name: 'Modal',
  directives: {
    ClickOutside,
  },
  props: {
    component: { type: Object, required: true },
    componentProps: { type: Object, required: true },
    wrapperClass: { type: String, default: '' },
    modalName: { type: String, default: 'modal' },
    allowScrollLock: { type: Boolean, default: false },
    escToClose: { type: Boolean, default: true },
    clickOutsideClose: { type: Boolean, default: true },
  },
  data: () => {
    return {
      loaded: false,
      show: false,
      originalPos: { x: 0, y: 0 },
      pendingAnswer: undefined,
      hasClickedInside: false,
    };
  },
  mounted() {
    this.show = true;
    this.$nextTick(() => {
      this.$refs['modal-container-wrapper'].focus();
    });
    if (this.allowScrollLock) {
      this.enableScrollLock();
    }
  },
  beforeDestroy() {
    this.disableScrollLock();
  },
  methods: {
    triggerClose(answer) {
      this.pendingAnswer = answer;
      this.show = false;
    },
    onFullClose() {
      this.$emit('close', this.pendingAnswer);
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
      if (this.escToClose) {
        this.triggerClose();
      }
    },
    setInsideClick() {
      this.hasClickedInside = true;
    },
    clearInsideClick() {
      this.hasClickedInside = false;
    },
    onOuterClick() {
      if (this.loaded && this.clickOutsideClose && !this.hasClickedInside) {
        const onOuterClick = this.$refs.modal.outerClickIntercept;

        const answer = onOuterClick ? onOuterClick() : undefined;
        this.triggerClose(answer);
      }
      this.clearInsideClick();
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