<template>
  <div class="shift-timespan-tooltip">
    <table class="shift-timespan-tooltip-table">
      <thead>
        <tr>
          <th class="heading-wrapper" colspan="2">{{ title }}</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>Start</th>
          <td>{{ formatTimestamp(timeSpan.startTime) }}</td>
        </tr>
        <tr>
          <th>End</th>
          <td>{{ formatTimestamp(timeSpan.endTime) }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import { formatDateRelativeToIn } from '@/code/time.js';

export default {
  name: 'ShiftTimeSpanTooltip',
  props: {
    timeSpan: { type: Object, default: null },
  },
  computed: {
    title() {
      return this.timeSpan.data.shiftType;
    },
  },
  methods: {
    formatTimestamp(timestamp) {
      if (!timestamp) {
        return '--';
      }
      return formatDateRelativeToIn(new Date(timestamp), this.$timely.current.timezone);
    },
  },
};
</script>

<style>
.shift-timespan-tooltip {
  z-index: 10000;
}

.shift-timespan-tooltip-table {
  background-color: #ffffffdd;
  width: auto;
  font-family: 'GE Inspira Sans', sans-serif;
  font-size: 12px;
  border-collapse: collapse;
  border: 1px solid white;
}

.shift-timespan-tooltip-table th {
  font-weight: bold;
  text-align: center;
}

.shift-timespan-tooltip-table .heading-wrapper {
  background-color: #444444bb;
  padding-right: 0.25rem;
}

.shift-timespan-tooltip .heading {
  display: flex;
  width: 100%;
  height: 100%;
}

.shift-timespan-tooltip .heading .title {
  text-align: center;
  line-height: 1.5rem;
  width: 100%;
}

.shift-timespan-tooltip .heading .lock-icon {
  margin: 0 0.25rem;
  height: 1.4rem;
  width: 1.2rem;
  stroke: black;
}

.shift-timespan-tooltip-table td {
  text-align: center;
}

.shift-timespan-tooltip-table th,
.shift-timespan-tooltip-table td {
  border: 1px solid grey;
  padding-top: 0.2rem;
  padding-bottom: 0.2rem;
  padding-left: 0.25rem;
  padding-right: 0.5rem;
  color: #001111;
}
</style>