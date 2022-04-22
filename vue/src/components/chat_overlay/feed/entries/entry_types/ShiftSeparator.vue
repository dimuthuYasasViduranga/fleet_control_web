<template>
  <div class="shift-separator">
    [{{ entry.shift.shiftType }}] {{ timestamp }} {{ isToday ? ' -- Current' : '' }}
  </div>
</template>

<script>
import { formatDateIn } from '@/code/time';
export default {
  name: 'DateSeparator',
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    timestamp() {
      const timezone = this.$timely.current.timezone;
      return formatDateIn(this.entry.shift.startTime, timezone, { format: 'yyyy LLL-dd hh:mm' });
    },
    isToday() {
      const now = Date.now();

      return now >= this.entry.shift.startEpoch && now <= this.entry.shift.endEpoch;
    },
  },
};
</script>

<style>
.shift-separator {
  padding: 0.1rem;
  background-color: #4c4127;
  color: #b6c3cc;
  text-align: center;
}
</style>