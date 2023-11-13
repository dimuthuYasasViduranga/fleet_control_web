<template>
  <div class="excavator-timeusagetimespan-tooltip">
    <table class="excavator-timeusagetimespan-tooltip-table">
      <thead>
        <tr colspan="2">
          <th colspan="2">{{ timeusage.time_usage_type || 'Unknown type' }}</th>
        </tr>
      </thead>
      <tbody>

        <tr>
          <th>Haul Truck</th>
          <td>{{ timeusage.haul_truck }}</td>
        </tr>

        <tr>
          <th>Cycle</th>
          <td>{{ timeusage.cycle_id }}</td>
        </tr>

        <tr>
          <th>Location</th>
          <td>{{ timeusage.location || '--' }}</td>
        </tr>
        <tr>
          <th>Start</th>
          <td>{{ formatTimestamp(timeSpan.startTime) }}</td>
        </tr>
        <tr>
          <th>End</th>
          <td>{{ formatTimestamp(timeSpan.endTime) }}</td>
        </tr>
        <tr>
          <th>Duration</th>
          <td>
            {{ formatDuration(timeSpan.startTime, timeSpan.endTime) }}
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
  name: 'ExcavatorTimeusageTooltip',
  props: {
    timeSpan: { type: Object, default: () => ({}) },
  },
  computed: {
    timeusage() {
      return this.timeSpan.data || {};
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
.excavator-timeusagetimespan-tooltip {
  z-index: 10000;
}

.excavator-timeusagetimespan-tooltip-table {
  background-color: #ffffffdd;
  width: auto;
  font-family: 'GE Inspira Sans', sans-serif;
  font-size: 12px;
  border-collapse: collapse;
  border: 1px solid white;
}

.excavator-timeusagetimespan-tooltip-table th {
  font-weight: bold;
  text-align: center;
}

.excavator-timeusagetimespan-tooltip-table thead {
  background-color: #444444bb;
}

.excavator-timeusagetimespan-tooltip-table td {
  text-align: center;
}

.excavator-timeusagetimespan-tooltip-table th,
.excavator-timeusagetimespan-tooltip-table td {
  border: 1px solid grey;
  padding-top: 0.2rem;
  padding-bottom: 0.2rem;
  padding-left: 0.25rem;
  padding-right: 0.5rem;
  color: #001111;
}
</style>