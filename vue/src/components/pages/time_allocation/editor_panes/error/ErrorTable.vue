<template>
  <div class="error-table">
    <table class="table-heading">
      <tr>
        <td class="selector-column"></td>
        <td class="time-code-column">Time Code</td>
        <td class="start-time-column">Start Time</td>
        <td class="end-time-column">End Time</td>
        <td class="action-column"></td>
      </tr>
    </table>

    <scrollable class="table-body" ref="scrollable" :style="listStyle">
      <ErrorTableRow
        v-for="(timeSpan, index) in timeSpans"
        :key="index"
        :isMaterialTimeline="isMaterialTimeline"
        :class="getRowClass(timeSpan)"
        :style="rowStyle"
        :timeSpan="timeSpan"
        :allowedTimeCodeIds="allowedTimeCodeIds"
        :minDatetime="minDatetime"
        :maxDatetime="maxDatetime"
        :timezone="timezone"
        @select="onRowSelect(timeSpan)"
        @fix="onFix(timeSpan)"
        @change="onChange"
      />
    </scrollable>
  </div>
</template>

<script>
import Scrollable from '../../../../Scrollable.vue';
import ErrorTableRow from './ErrorTableRow.vue';

function scrollbarProxy(references) {
  return new Proxy(references, {
    get(refs, name, _receiver) {
      const scrollbar = refs.scrollable;
      if (scrollbar) {
        return scrollbar[name];
      }
      return () => undefined;
    },
  });
}

export default {
  name: 'ErrorTable',
  components: {
    Scrollable,
    ErrorTableRow,
  },
  props: {
    isMaterialTimeline: { type: Boolean, default: () => false },
    timeSpans: { type: Array, default: () => [] },
    height: { type: Number, default: 250 },
    maxShown: { type: Number, default: 10 },
    allowedTimeCodeIds: { type: Array, default: () => [] },
    selectedAllocationId: { type: Number, default: null },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
  },
  computed: {
    rowHeight() {
      return this.height / this.maxShown;
    },
    rowStyle() {
      return `height: ${this.rowHeight}px`;
    },
    listStyle() {
      return `height: ${this.height}px`;
    },
    scrollbar() {
      return scrollbarProxy(this.$refs);
    },
  },
  watch: {
    selectedAllocationId: {
      immediate: true,
      handler(id) {
        if (id) {
          const index = this.timeSpans.find(ts => ts.data.id === id);
          if (index > -1) {
            this.scrollInView(index);
          }
        }
      },
    },
  },
  methods: {
    getRowClass(timeSpan) {
      if (!this.selectedAllocationId || timeSpan.data.id === this.selectedAllocationId) {
        return '';
      }

      return 'deselected';
    },
    getScrollLevel() {
      return this.scrollbar.getScrollLevel() || 0;
    },
    scrollTop() {
      this.scrollbar.scrollTop();
    },
    scrollBottom() {
      this.scrollbar.scrollBottom();
    },
    scrollInView(index) {
      // get the indices in view
      const curScroll = this.getScrollLevel();
      const topShownIndex = curScroll / this.rowHeight;
      const bottomShownIndex = topShownIndex + this.maxShown - 1;

      if (index < topShownIndex) {
        this.scrollToElement(index);
      } else if (index > bottomShownIndex) {
        this.scrollToElement(topShownIndex + index - bottomShownIndex);
      }
    },
    scrollToElement(index) {
      this.scrollbar.scrollTo(index * this.rowHeight);
    },
    scrollToCenter(index) {
      const topIndex = index - Math.trunc(this.maxShown / 2);
      this.scrollToElement(topIndex);
    },
    onChange(timeSpan) {
      this.$emit('change', timeSpan);
    },
    onRowSelect(timeSpan) {
      this.$emit('rowSelect', timeSpan);
    },
    onFix(timeSpan) {
      this.$emit('fix', timeSpan);
    },
  },
};
</script>

<style>
.error-table .table-heading {
  table-layout: fixed;
  width: 100%;
  text-align: center;
  user-select: none;
  padding-right: 1rem;
}

.error-table .selector-column {
  width: 1.5rem;
}

.error-table .action-column {
  width: 5rem;
}

.error-table .table-body {
  border-top: 1px solid #677e8c;
  border-bottom: 1px solid #677e8c;
}

.error-table .table-body table {
  table-layout: fixed;
  width: 100%;
}

.error-table .deselected {
  opacity: 0.25;
}
</style>
