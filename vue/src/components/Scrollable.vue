<template>
  <div class="scrollable">
    <PerfectScrollbar
      ref="scroll"
      @ps-scroll-y="$emit('scroll-y', $event)"
      @ps-scroll-up="$emit('up', $event)"
      @ps-scroll-down="$emit('down', $event)"
      @ps-y-reach-start="$emit('top', $event)"
      @ps-y-reach-end="$emit('bottom', $event)"
      :options="options"
    >
      <slot></slot>
    </PerfectScrollbar>
  </div>
</template>

<script>
import { PerfectScrollbar } from 'vue2-perfect-scrollbar';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';

export default {
  name: 'ScrollBar',
  components: {
    PerfectScrollbar,
  },
  props: {
    options: Object,
  },
  methods: {
    scrollbar() {
      return this.$refs.scroll.$el;
    },
    getScrollLevel() {
      return this.scrollbar().scrollTop;
    },
    scrollTop() {
      this.$nextTick(() => (this.scrollbar().scrollTop = 0));
    },
    scrollBottom() {
      this.$nextTick(() => (this.scrollbar().scrollTop = 100000));
    },
    scrollTo(offset) {
      this.$nextTick(() => (this.scrollbar().scrollTop = offset));
    },
  },
};
</script>

<style>
.scrollable,
.scrollable .ps {
  height: 100%;
}

.scrollable .ps .ps__rail-y,
.scrollable .ps .ps__rail-x {
  background-color: #121f26;
}
</style>