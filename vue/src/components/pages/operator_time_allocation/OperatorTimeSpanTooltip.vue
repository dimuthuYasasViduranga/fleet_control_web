<template>
  <div class="operator-timespan-tooltip">
    <table class="operator-timespan-tooltip-table">
      <thead>
        <tr>
          <th class="heading-wrapper" colspan="2">
            <div class="heading">
              <span class="title">{{ title }}</span>
            </div>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="overlapping">
          <th colspan="2" style="color: red">{{ overlapping }}</th>
        </tr>
        <tr>
          <th>Asset</th>
          <td>{{ timeSpan.data.assetName || '--' }}</td>
        </tr>
        <tr>
          <th>Start</th>
          <td>{{ formatTimestamp(timeSpan.startTime) }}</td>
        </tr>
        <tr>
          <th>End</th>
          <td>{{ formatTimestamp(timeSpan.endTime || timeSpan.activeEndTime) }}</td>
        </tr>
        <tr>
          <th>Duration</th>
          <td>
            {{ formatDuration(timeSpan.startTime, timeSpan.endTime || timeSpan.activeEndTime) }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';

import { formatSeconds, formatDateIn, formatDateRelativeToIn } from '@/code/time.js';
import { attributeFromList } from '@/code/helpers';

const SECONDS_IN_HOUR = 3600;
const SECONDS_IN_DAY = 24 * 60 * 60;

function toPlural(value, unit, suffix) {
  if (value === 1) {
    return `${value} ${unit}`;
  }
  return `${value} ${unit}${suffix}`;
}

export default {
  name: 'OperatorTimeSpanTooltip',
  components: {
    Icon,
  },
  props: {
    timeSpan: { type: Object, default: null },
  },
  computed: {
    title() {
      const { assetName, timeCodeGroup, timeCode } = this.timeSpan.data;

      if (!assetName) {
        return 'Off Asset';
      }

      if (!timeCodeGroup && !timeCode) {
        return 'Unknown';
      }

      return `${timeCodeGroup} \u2014 ${timeCode}`;
    },
    overlapping() {
      if (!this.timeSpan.isOverlapping) {
        return '';
      }

      if (this.timeSpan.level === 0) {
        return 'Overlapped';
      }

      return 'Overlapping';
    },
  },
  methods: {
    formatTimestamp(timestamp) {
      if (!timestamp) {
        return '--';
      }
      return formatDateRelativeToIn(new Date(timestamp), this.$timely.current.timezone);
    },
    formatDuration(startTime, endTime) {
      if (!startTime || !endTime) {
        return '--';
      }
      const start = new Date(startTime);
      const end = new Date(endTime);
      const totalSeconds = Math.trunc((end.getTime() - start.getTime()) / 1000);
      if (totalSeconds > SECONDS_IN_DAY) {
        const days = Math.trunc(totalSeconds / SECONDS_IN_DAY);
        return toPlural(`> ${days}`, 'day', 's');
      }
      if (totalSeconds < SECONDS_IN_HOUR) {
        return formatSeconds(totalSeconds, '%M:%SS');
      }
      return formatSeconds(totalSeconds, '%H:%MM:%SS');
    },
  },
};
</script>

<style>
.operator-timespan-tooltip {
  z-index: 10000;
}

.operator-timespan-tooltip-table {
  background-color: #ffffffdd;
  width: auto;
  font-family: 'GE Inspira Sans', sans-serif;
  font-size: 12px;
  border-collapse: collapse;
  border: 1px solid white;
}

.operator-timespan-tooltip-table th {
  font-weight: bold;
  text-align: center;
}

.operator-timespan-tooltip-table .heading-wrapper {
  background-color: #444444bb;
  padding-right: 0.25rem;
}

.operator-timespan-tooltip .heading {
  display: flex;
  width: 100%;
  height: 100%;
}

.operator-timespan-tooltip .heading .title {
  text-align: center;
  line-height: 1.5rem;
  width: 100%;
}

.operator-timespan-tooltip-table td {
  text-align: center;
}

.operator-timespan-tooltip-table th,
.operator-timespan-tooltip-table td {
  border: 1px solid grey;
  padding-top: 0.2rem;
  padding-bottom: 0.2rem;
  padding-left: 0.25rem;
  padding-right: 0.5rem;
  color: #001111;
}
</style>