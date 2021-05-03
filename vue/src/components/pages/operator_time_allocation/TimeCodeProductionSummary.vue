<template>
  <div class="time-code-production-summary">
    <table>
      <tr v-for="(tc, index) in productionTimeSummary" :key="index">
        <th>{{ tc.timeCode }}</th>
        <td>{{ formatDuration(tc.duration) }}</td>
      </tr>
    </table>
  </div>
</template>

<script>
import { Dictionary } from '@/code/helpers';
import { copyDate, formatSeconds } from '@/code/time';
function createProductionTimeSummary(allocations) {
  const validAllocs = allocations
    .filter(a => a.timeCodeGroup)
    .map(a => {
      return {
        startTime: copyDate(a.startTime),
        endTime: copyDate(a.endTime),
        timeCode: a.timeCode,
        timeCodeGroup: a.timeCodeGroup,
        duration: a.duration,
      };
    })
    .sort((a, b) => a.startTime.getTime() - b.startTime.getTime());

  const productionAllocs = extendByProcessWherePossible(validAllocs).filter(
    a => a.timeCodeGroup === 'Ready',
  );

  const dict = new Dictionary();

  productionAllocs.forEach(alloc => dict.append(alloc.timeCode, alloc.duration));

  return dict
    .reduce((acc, timeCode, durations) => {
      const totalDuration = durations.reduce((acc, duration) => acc + duration, 0);
      acc.push({ timeCode: timeCode || '', duration: totalDuration });
      return acc;
    }, [])
    .sort((a, b) => a.timeCode.localeCompare(b.timeCode));
}

function extendByProcessWherePossible(allocations) {
  return allocations.reduce(
    (acc, alloc) => {
      const prev = acc.prev;
      // if current is process, and previous is not process, take type
      if (prev && alloc.timeCodeGroup === 'Process' && prev.timeCodeGroup !== 'Process') {
        alloc.timeCode = prev.timeCode;
        alloc.timeCodeGroup = prev.timeCodeGroup;
      }

      acc.prev = alloc;
      acc.completed.push(alloc);
      return acc;
    },
    { prev: null, completed: [] },
  ).completed;
}

export default {
  name: 'TimeCodeProductionSummary',
  props: {
    data: { type: Array, default: () => [] },
  },
  computed: {
    allocs() {
      return this.data.map(ts => {
        const duration = ts.endTime.getTime() - ts.startTime.getTime();
        return {
          startTime: ts.startTime,
          endTime: ts.endTime,
          duration,
          timeCode: ts.data.timeCode,
          timeCodeGroup: ts.data.timeCodeGroup,
        };
      });
    },
    productionTimeSummary() {
      return createProductionTimeSummary(this.allocs);
    },
  },
  methods: {
    formatDuration(ms) {
      const seconds = Math.trunc(ms / 1000);

      if (!seconds) {
        return '--';
      }
      return formatSeconds(seconds);
    },
  },
};
</script>

<style>
.time-code-production-summary table {
  width: 100%;
  table-layout: fixed;
  text-align: left;
  border-collapse: collapse;
}

.time-code-production-summary table tr {
  height: 2.5rem;
  border-bottom: 0.05em solid #2c404c;
  background-color: #232d3363;
}

.time-code-production-summary table th {
  padding-left: 1rem;
}
</style>