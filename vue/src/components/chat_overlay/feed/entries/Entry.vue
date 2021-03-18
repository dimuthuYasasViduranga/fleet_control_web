<template>
  <div class="entry">
    <div class="entry-wrapper">
      <div class="timestamp">{{ time }}</div>
      <div class="entry-content">
        <OperatorMessage v-if="entry.eventType === 'operator-message'" :entry="entry" />
        <DispatchMessage v-else-if="entry.eventType === 'dispatcher-message'" :entry="entry" />
        <DispatchMassMessage
          v-else-if="entry.eventType === 'dispatcher-mass-message'"
          :entry="entry"
        />
        <HaulTruckDispatchEvent
          v-else-if="entry.eventType === 'haul-truck-dispatch'"
          :entry="entry"
        />
        <HaulTruckMassDispatchEvent
          v-else-if="entry.eventType === 'haul-truck-mass-dispatch'"
          :entry="entry"
        />
        <AssignmentEvent
          v-else-if="['device-assigned', 'device-unassigned'].includes(entry.eventType)"
          :entry="entry"
        />
        <LoginEvent v-else-if="['login', 'logout'].includes(entry.eventType)" :entry="entry" />
        <TimeAllocationEvent v-else-if="entry.eventType === 'time-allocation'" :entry="entry" />
        <DateSeparator v-else-if="entry.eventType === 'date-separator'" :entry="entry" />
      </div>
    </div>
  </div>
</template>

<script>
import HaulTruckDispatchEvent from './entry_types/HaulTruckDispatchEvent.vue';
import HaulTruckMassDispatchEvent from './entry_types/HaulTruckMassDispatchEvent.vue';
import TimeAllocationEvent from './entry_types/TimeAllocationEvent.vue';
import DispatchMessage from './entry_types/DispatchMessage.vue';
import DispatchMassMessage from './entry_types/DispatchMassMessage.vue';
import OperatorMessage from './entry_types/OperatorMessage.vue';
import DateSeparator from './entry_types/DateSeparator.vue';
import AssignmentEvent from './entry_types/AssignmentEvent.vue';
import LoginEvent from './entry_types/LoginEvent.vue';

import { formatDateIn } from './../../../../code/time.js';

export default {
  name: 'Entry',
  components: {
    HaulTruckDispatchEvent,
    HaulTruckMassDispatchEvent,
    TimeAllocationEvent,
    DispatchMessage,
    DispatchMassMessage,
    OperatorMessage,
    DateSeparator,
    AssignmentEvent,
    LoginEvent,
  },
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    time() {
      const tz = this.$timely.current.timezone;
      return formatDateIn(this.entry.timestamp, tz, { format: 'HH:mm' });
    },
  },
};
</script>

<style>
.entry {
  margin: 1rem 2rem;
}

.entry-wrapper {
  display: table;
  width: 100%;
}

.entry-content {
  word-break: break-word;
}

.entry .timestamp {
  color: grey;
  display: table-cell;
  padding-right: 1rem;
  width: 2rem;
}
</style>