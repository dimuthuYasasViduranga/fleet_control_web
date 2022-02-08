<template>
  <div class="new-pane">
    <div class="error">{{ error }}</div>

    <table class="new-pane-table">
      <tr class="row time-code">
        <td class="key">Time Code</td>
        <td class="value">
          <div class="time-code-wrapper">
            <TimeAllocationDropDown
              v-model="timeCodeId"
              :allowedTimeCodeIds="allowedTimeCodeIds"
              :showAll="showAllTimeCodes"
              direction="down"
            />
            <div class="show-all-checked">
              <input v-model="showAllTimeCodes" type="checkbox" /> All
            </div>
          </div>
        </td>
      </tr>
      <tr class="row start-time">
        <td class="key">Start Time</td>
        <td class="value">
          <Dately
            v-model="startTime"
            :minDatetime="minStart"
            :maxDatetime="maxStart"
            :timezone="timezone"
          />
        </td>
      </tr>
      <tr class="row end-time">
        <td class="key">End Time</td>
        <td class="value">
          <Dately
            v-model="endTime"
            :minDatetime="minEnd"
            :maxDatetime="maxEnd"
            :timezone="timezone"
          />
        </td>
      </tr>
    </table>

    <div class="action-buttons">
      <button class="hx-btn create" @click="onCreate">Create</button>
      <button class="hx-btn override" @click="onCreateOverride">Override</button>
      <button class="hx-btn clear" @click="onClear">Clear</button>
    </div>
  </div>
</template>

<script>
import Dately from '@/components/dately/Dately.vue';
import TimeAllocationDropDown from '@/components/TimeAllocationDropDown.vue';
import { copyDate } from '@/code/time';

function getError({ timeCodeId, startTime, endTime }) {
  const errors = [];
  if (!timeCodeId) {
    errors.push('Time Code');
  }

  if (!startTime) {
    errors.push('Start Time');
  }

  if (!endTime) {
    errors.push('End Time');
  }

  if (errors.length === 0) {
    return '';
  }

  return `${errors.join(', ')} must be set`;
}

export default {
  name: 'NewPane',
  components: {
    Dately,
    TimeAllocationDropDown,
  },
  props: {
    value: { type: Object, default: () => ({}) },
    allowedTimeCodeIds: { type: Array, default: () => [] },
    paneHeight: { type: Number, default: null },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
  },
  data: () => {
    return {
      error: '',
      showAllTimeCodes: false,
    };
  },
  computed: {
    timeCodeId: {
      get() {
        return this.value.timeCodeId;
      },
      set(value) {
        this.emitValue({ timeCodeId: value });
      },
    },
    startTime: {
      get() {
        return this.value.startTime;
      },
      set(value) {
        this.emitValue({ startTime: copyDate(value) });
      },
    },
    endTime: {
      get() {
        return this.value.endTime;
      },
      set(value) {
        this.emitValue({ endTime: copyDate(value) });
      },
    },
    minStart() {
      return this.minDatetime;
    },
    maxStart() {
      return this.endTime || this.maxDatetime;
    },
    minEnd() {
      return this.startTime || this.minDatetime;
    },
    maxEnd() {
      return this.maxDatetime;
    },
    isInvalid() {
      return !this.timeCodeId || !this.startTime || !this.endTime;
    },
  },
  methods: {
    emitValue(change) {
      this.$emit('input', { ...this.value, ...change });
    },
    setError(error) {
      this.error = error;
    },
    clearError() {
      this.error = null;
    },
    onCreate() {
      this.clearError();
      const error = getError(this.value);
      this.setError(error);

      if (!error) {
        const payload = {
          timeCodeId: this.timeCodeId,
          startTime: copyDate(this.startTime),
          endTime: copyDate(this.endTime),
        };

        this.onClear();
        this.$emit('create', payload);
      }
    },
    onCreateOverride() {
      this.clearError();
      const error = getError(this.value);
      this.setError(error);

      if (!error) {
        const payload = {
          timeCodeId: this.timeCodeId,
          startTime: copyDate(this.startTime),
          endTime: copyDate(this.endTime),
        };

        this.onClear();
        this.$emit('override', payload);
      }
    },
    onClear() {
      this.clearError();
      this.emitValue({
        timeCodeId: null,
        startTime: null,
        endTime: null,
      });
    },
  },
};
</script>

<style>
.new-pane {
  margin: auto;
  padding-top: 2rem;
  width: 25rem;
  height: 100%;
}

.new-pane .error {
  height: 1rem;
  text-align: center;
}

.new-pane .new-pane-table {
  width: 100%;
}

.new-pane .new-pane-table .row {
  height: 3rem;
}

.new-pane .new-pane-table .key {
  width: 6rem;
  text-align: center;
}

.new-pane .new-pane-table .value {
  padding-left: 2rem;
  text-align: left;
}

.new-pane .new-pane-table .value .time-code-wrapper {
  display: flex;
  text-align: left;
}

.new-pane .new-pane-table .value .show-all-checked {
  line-height: 2.1rem;
  margin-left: 0.5rem;
}

.new-pane .new-pane-table .value .drop-down {
  width: 13.5rem;
  height: 2rem;
}

.new-pane .new-pane-table .value .datetime-input {
  width: 16.5rem;
}

.new-pane .action-buttons {
  display: flex;
}

.new-pane .action-buttons .hx-btn {
  flex: 1;
  margin: 0.1rem;
}
</style>