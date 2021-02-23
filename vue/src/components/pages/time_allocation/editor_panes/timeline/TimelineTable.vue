<template>
  <div class="timeline-table">
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
      <TimelineTableRow
        v-for="([prevTimeSpan, timeSpan, nextTimeSpan], index) in rows"
        :key="index"
        :class="getRowClass(timeSpan)"
        :style="rowStyle"
        :prevTimeSpan="prevTimeSpan"
        :timeSpan="timeSpan"
        :nextTimeSpan="nextTimeSpan"
        :timeCodes="timeCodes"
        :allowedTimeCodeIds="allowedTimeCodeIds"
        :showAllTimeCodes="showAllTimeCodes"
        :minDatetime="minDatetime"
        :maxDatetime="maxDatetime"
        :timezone="timezone"
        @select="onRowSelect(timeSpan)"
        @changes="onChanges"
        @end="ontimeSpanEnd"
      />
    </scrollable>
    <div class="show-time-codes-check">
      <input v-model="showAllTimeCodes" type="checkbox" />All time codes
    </div>
  </div>
</template>

<script>
import Scrollable from '../../../../Scrollable.vue';
import TimelineTableRow from './TimelineTableRow.vue';
import { chunkEvery } from '../../../../../code/helpers';

function scrollbarProxy(references) {
  return new Proxy(references, {
    get(refs, name, receiver) {
      const scrollbar = refs.scrollable;
      if (scrollbar) {
        return scrollbar[name];
      }
      return () => undefined;
    },
  });
}

export default {
  name: 'TimelineTable',
  components: {
    Scrollable,
    TimelineTableRow,
  },
  props: {
    timeSpans: { type: Array, default: () => [] },
    timeCodes: { type: Array, default: () => [] },
    allowedTimeCodeIds: { type: Array, default: () => [] },
    selectedAllocationId: { type: Number, default: null },
    height: { type: Number, default: 250 },
    maxShown: { type: Number, default: 10 },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
  },
  data: () => {
    return {
      showAllTimeCodes: false,
    };
  },
  computed: {
    paddedHeight() {
      return this.height - 20;
    },
    rowHeight() {
      return this.paddedHeight / this.maxShown;
    },
    rowStyle() {
      return `height: ${this.rowHeight}px`;
    },
    listStyle() {
      return `height: ${this.paddedHeight}px`;
    },
    scrollbar() {
      return scrollbarProxy(this.$refs);
    },
    rows() {
      // timeSpans are padded with nulls to make sure that the start and end elements fill the array
      const timeSpans = [null].concat(this.timeSpans).concat([null]);
      return chunkEvery(timeSpans, 3, 1, 'discard');
    },
  },
  watch: {
    selectedAllocationId: {
      immediate: true,
      handler(id) {
        if (id) {
          const index = this.timeSpans.findIndex(ts => ts.data.id === id);
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
    onChanges(timeSpans) {
      this.$emit('changes', timeSpans);
    },
    onRowSelect(timeSpan) {
      this.$emit('rowSelect', timeSpan);
    },
    onFix(timeSpan) {
      this.$emit('fix', timeSpan);
    },
    onRowSelect(timeSpan) {
      this.$emit('rowSelect', timeSpan);
    },
    onChange(timeSpan) {
      this.$emit('change', timeSpan);
    },
    ontimeSpanEnd(timeSpan) {
      this.$emit('end', timeSpan);
    },
  },
};
</script>


<style>
.timeline-table .table-heading {
  table-layout: fixed;
  width: 100%;
  text-align: center;
  user-select: none;
  padding-right: 1rem;
}

.timeline-table .selector-column {
  width: 1rem;
}

.timeline-table .action-column {
  width: 7rem;
}

.timeline-table .table-body {
  border-top: 1px solid #677e8c;
  border-bottom: 1px solid #677e8c;
}

.timeline-table .table-body table {
  table-layout: fixed;
  width: 100%;
}

.timeline-table .deselected {
  opacity: 0.25;
}

.timeline-table .show-time-codes-check {
  text-align: left;
}
</style>