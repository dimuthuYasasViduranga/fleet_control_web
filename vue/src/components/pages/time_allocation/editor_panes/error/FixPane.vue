<template>
  <div class="fix-pane">
    <div class="blueprint deleted-blueprint">
      <TimeSpanChart
        name="deleted-blueprint"
        :timeSpans="deletedTimeSpanBlueprint"
        :layout="chartLayout(deletedTimeSpanBlueprint)"
        :margins="margins"
        :styler="timeSpanStyler"
        :minDatetime="minDatetime"
        :maxDatetime="maxDatetime"
      >
        <template slot-scope="timeSpan">
          <div class="__tooltip-boundary">
            <AllocationTooltip v-if="timeSpan.group === 'allocation'" :timeSpan="timeSpan" />
          </div>
        </template>
      </TimeSpanChart>

      <button class="hx-btn deleted-blueprint-btn" @click="onDeleteAccept">Delete</button>
    </div>

    <div class="blueprint override-blueprint">
      <TimeSpanChart
        name="override-blueprint"
        :timeSpans="overrideTimeSpanBlueprint"
        :layout="chartLayout(overrideTimeSpanBlueprint)"
        :margins="margins"
        :styler="timeSpanStyler"
        :minDatetime="minDatetime"
        :maxDatetime="maxDatetime"
      >
        <template slot-scope="timeSpan">
          <div class="__tooltip-boundary">
            <AllocationTooltip v-if="timeSpan.group === 'allocation'" :timeSpan="timeSpan" />
          </div>
        </template>
      </TimeSpanChart>

      <button class="hx-btn override-blueprint-btn" @click="onOverrideAccept">Override</button>
    </div>

    <div class="blueprint merge-blueprint" v-if="!mergeEqualsOverride">
      <TimeSpanChart
        name="merge-blueprint"
        :timeSpans="mergeTimeSpanBlueprint"
        :layout="chartLayout(mergeTimeSpanBlueprint)"
        :margins="margins"
        :styler="timeSpanStyler"
        :minDatetime="minDatetime"
        :maxDatetime="maxDatetime"
      >
        <template slot-scope="timeSpan">
          <div class="__tooltip-boundary">
            <AllocationTooltip v-if="timeSpan.group === 'allocation'" :timeSpan="timeSpan" />
          </div>
        </template>
      </TimeSpanChart>

      <button class="hx-btn merge-blueprint-btn" @click="onMergeAccept">Merge</button>
    </div>

    <div class="cancel-wrapper">
      <button class="hx-btn cancel" @click="onCancel">Cancel</button>
    </div>
  </div>
</template>

<script>
import TimeSpanChart from '../../chart/TimeSpanChart.vue';
import AllocationTooltip from '../../tooltips/AllocationTimeSpanTooltip.vue';
import { allocationStyle } from '../../timespan_formatters/timeAllocationTimeSpans';
import { uniq } from '../../../../../code/helpers';
import { findOverlapping, addDynamicLevels, overrideAll, mergeAll } from '../../timeSpan';
import { copyDate } from '../../../../../code/time';

function copyTimeSpan(timeSpan) {
  if (!timeSpan) {
    return null;
  }
  return {
    ...timeSpan,
    startTime: copyDate(timeSpan.startTime),
    endTime: copyDate(timeSpan.endTime),
    activeEndTime: copyDate(timeSpan.activeEndTime),
    data: { ...timeSpan.data },
  };
}

function mergerCallback(merger, mergee) {
  // merger "Ready" can only override a mergee of "Ready"
  if (merger.data.timeCodeGroup === 'Ready' && mergee.data.timeCodeGroup !== 'Ready') {
    return [mergee, merger];
  }
  return [merger, mergee];
}

function timeSpansEqual(a, b) {
  const length = a.length;
  if (length !== b.length) {
    return false;
  }

  for (let i = 0; i < length; i++) {
    if (!timeSpanEqual(a[i], b[i])) {
      return false;
    }
  }

  return true;
}

function timeSpanEqual(a, b) {
  return (
    a.data.id === b.data.id &&
    a.deleted === b.deleted &&
    a.startTime.getTime() === b.startTime.getTime() &&
    (a.endTime || a.activeEndTime).getTime() === (b.endTime || b.activeEndTime).getTime()
  );
}

function splitSpanForRange(timeSpan, minDatetime, maxDatetime) {
  const ref = copyTimeSpan(timeSpan);
  let leftSpan = null;
  let rightSpan = null;

  if (minDatetime && timeSpan.startTime.getTime() < minDatetime.getTime()) {
    leftSpan = copyTimeSpan(ref);
    leftSpan.endTime = copyDate(minDatetime);
    leftSpan.data.id = null;
    ref.startTime = copyDate(minDatetime);
  }

  if (maxDatetime && (timeSpan.endTime || timeSpan.activeEndTime).getTime() > maxDatetime.getTime()) {
    rightSpan = copyTimeSpan(ref);
    rightSpan.startTime = copyDate(maxDatetime);
    rightSpan.data.id = null;
    ref.endTime = copyDate(maxDatetime);
  }

  return [ref, [leftSpan, rightSpan].filter(s => s)];
}

function splitOverlappedSpans(spans, minDatetime, maxDatetime) {
  return spans
    .map(span => {
      const [croppedSpan, outerSpans] = splitSpanForRange(span, minDatetime, maxDatetime);
      return [croppedSpan].concat(outerSpans);
    })
    .flat();
}

export default {
  name: 'FixPane',
  components: {
    TimeSpanChart,
    AllocationTooltip,
  },
  props: {
    refTimeSpan: { type: Object, required: true },
    timeSpans: { type: Array, default: () => [] },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
  },
  data: () => {
    return {
      margins: {
        focus: {
          top: 15,
          left: 20,
          right: 20,
          bottom: 25,
        },
      },
    };
  },
  computed: {
    deletedTimeSpans() {
      const [ref, outerRefs, overlappedSpans] = this.affectedTimeSpans();
      ref.deleted = true;
      ref.data.deleted = true;

      overlappedSpans.forEach(ts => (ts.data.deleted = ts.deleted));

      return [ref].concat(outerRefs).concat(overlappedSpans);
    },
    deletedTimeSpanBlueprint() {
      const timeSpans = this.deletedTimeSpans.map(copyTimeSpan);
      return addDynamicLevels(timeSpans, true)[0];
    },
    overrideTimeSpans() {
      const [ref, outerRefs, overlappedSpans] = this.affectedTimeSpans();
      const splitOverlapped = splitOverlappedSpans(
        overlappedSpans,
        this.minDatetime,
        this.maxDatetime,
      );
      const overrides = overrideAll(ref, splitOverlapped);
      overrides.forEach(ts => (ts.data.deleted = ts.deleted));
      return overrides.concat(outerRefs);
    },
    overrideTimeSpanBlueprint() {
      const timeSpans = this.overrideTimeSpans.map(copyTimeSpan);
      const merges = addDynamicLevels(timeSpans, false)[0];
      merges.forEach(ts => (ts.data.deleted = ts.deleted));
      return merges;
    },
    mergeTimeSpans() {
      const [ref, outerRefs, overlappedSpans] = this.affectedTimeSpans();
      const splitOverlapped = splitOverlappedSpans(
        overlappedSpans,
        this.minDatetime,
        this.maxDatetime,
      );
      return mergeAll(ref, splitOverlapped, mergerCallback).concat(outerRefs);
    },
    mergeTimeSpanBlueprint() {
      const timeSpans = this.mergeTimeSpans.map(copyTimeSpan);
      return addDynamicLevels(timeSpans, false)[0];
    },
    mergeEqualsOverride() {
      return timeSpansEqual(this.mergeTimeSpans, this.overrideTimeSpans);
    },
  },
  methods: {
    timeSpanStyler(timeSpan, region) {
      const style = allocationStyle(timeSpan, region);
      if (timeSpan.deleted === true) {
        return { ...style, fill: 'hatch' };
      }
      return style;
    },
    chartLayout(timeSpans) {
      const groups = [
        {
          group: 'allocation',
          subgroups: uniq(timeSpans.filter(ts => ts.deleted !== false).map(ts => ts.level || 0)),
        },
      ];

      return {
        groups,
        yAxis: {
          show: false,
        },
      };
    },
    affectedTimeSpans() {
      // find the timespan matching reference
      const ref = copyTimeSpan(this.timeSpans.find(ts => ts.data.id === this.refTimeSpan.data.id));

      if (!ref) {
        return [];
      }
      const [inRangeRef, outerRefs] = splitSpanForRange(ref, this.minDatetime, this.maxDatetime);

      const levelBelow = ref.level - 1;
      const timeSpansBelow = this.timeSpans.map(copyTimeSpan).filter(ts => ts.level === levelBelow);
      const overlappedSpans = findOverlapping(inRangeRef, timeSpansBelow);

      return [inRangeRef, outerRefs, overlappedSpans];
    },
    onCancel() {
      this.$emit('cancel');
    },
    submitChanges(changes) {
      this.$emit('changes', changes);
    },
    onDeleteAccept() {
      this.submitChanges(this.deletedTimeSpans);
    },
    onOverrideAccept() {
      this.submitChanges(this.overrideTimeSpans);
    },
    onMergeAccept() {
      this.submitChanges(this.mergeTimeSpans);
    },
  },
};
</script>

<style>
@import '../../../../../assets/hxInput.css';

.fix-pane .blueprint {
  display: flex;
  height: 75px;
}

.fix-pane .hx-btn {
  width: 6rem;
  min-width: 6rem;
  margin: auto;
}

.fix-pane .cancel-wrapper .cancel {
  margin: 0;
  margin-top: 0.5rem;
}

.fix-pane .cancel-wrapper {
  width: 100%;
  display: flex;
  justify-content: flex-end;
}
</style>