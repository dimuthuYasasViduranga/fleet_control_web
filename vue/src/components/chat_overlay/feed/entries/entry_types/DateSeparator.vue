<template>
  <div class="date-separator">{{ entry.date }} {{ todayIndicator }}</div>
</template>

<script>
import { formatDateIn } from '@/code/time';
export default {
  name: 'DateSeparator',
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    isToday() {
      const format = 'yyyy-MM-dd';
      const nowString = formatDateIn(new Date(), { format });
      const timestampString = formatDateIn(this.entry.timestamp, { format });
      return timestampString === nowString;
    },
    todayIndicator() {
      if (this.isToday) {
        return '(Today)';
      }
      return;
    },
  },
};
</script>

<style>
.date-separator {
  padding: 0.1rem;
  background-color: #4c4127;
  color: #b6c3cc;
  text-align: center;
}
</style>