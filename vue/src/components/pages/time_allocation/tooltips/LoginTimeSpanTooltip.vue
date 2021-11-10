<template>
  <div class="login-timespan-tooltip">
    <table class="login-timespan-tooltip-table">
      <thead>
        <tr colspan="2">
          <th colspan="2">{{ title }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="timeSpan.activeEndTime">
          <th colspan="2" style="color: green">Active</th>
        </tr>
        <tr v-if="timeSpan.data.operatorId">
          <th>Operator</th>
          <td>{{ timeSpan.data.operatorFullname || '--' }}</td>
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
import { formatSeconds, formatDateRelativeToIn } from '@/code/time.js';

const SECONDS_IN_HOUR = 3600;
const SECONDS_IN_DAY = 24 * 60 * 60;

function toPlural(value, unit, suffix) {
  if (value === 1) {
    return `${value} ${unit}`;
  }
  return `${value} ${unit}${suffix}`;
}

export default {
  name: 'LoginTimeSpanTooltip',
  props: {
    timeSpan: { type: Object, default: null },
  },
  computed: {
    title() {
      switch (this.timeSpan.data.type) {
        case 'logged-in':
          return 'Logged-In';

        case 'logged-out':
          return 'No Operator';

        default:
          return 'No Device';
      }
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
.login-timespan-tooltip {
  z-index: 10000;
}

.login-timespan-tooltip-table {
  background-color: #ffffffdd;
  width: auto;
  font-family: 'GE Inspira Sans', sans-serif;
  font-size: 12px;
  border-collapse: collapse;
  border: 1px solid white;
}

.login-timespan-tooltip-table th {
  font-weight: bold;
  text-align: center;
}

.login-timespan-tooltip-table thead {
  background-color: #444444bb;
}

.login-timespan-tooltip-table td {
  text-align: center;
}

.login-timespan-tooltip-table th,
.login-timespan-tooltip-table td {
  border: 1px solid grey;
  padding-top: 0.2rem;
  padding-bottom: 0.2rem;
  padding-left: 0.25rem;
  padding-right: 0.5rem;
  color: #001111;
}
</style>