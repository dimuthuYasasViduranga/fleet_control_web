<template>
  <div class="shift-selector">
    <Icon v-if="showIcon" class="calendar-icon" :icon="calendarIcon" />
    <div class="shift-selector-button-wrapper">
      <div class="shift-type-selector">
        <button @click="toggleShift" class="shift-button shift-type-toggle" :disabled="disabled">
          {{ shiftTypeName || '--' }}
        </button>
      </div>
      <div class="gap"></div>
      <div class="date-selector">
        <Datetime
          placeholder="--"
          :input-id="dateSelectorId"
          :value="shiftDateStr"
          type="datetime"
          zone="local"
          format="dd MMM yyyy"
          :flow="['date']"
          :min-datetime="minDatetimeStr"
          :max-datetime="maxDatetimeStr"
          :disabled="disabled"
          @input="onDateChange"
        />
      </div>
      <div class="gap"></div>
      <div class="today-selector">
        <button @click="onToday" class="shift-button shift-today" :disabled="disabled">
          Today
        </button>
      </div>
      <div class="gap"></div>

      <div class="arrow left-arrow">
        <button class="shift-inc-toggle" @click="setNextShift(-1)" :disabled="!canPrev || disabled">
          {{ prevIcon }}
        </button>
      </div>
      <div class="gap"></div>

      <div class="arrow right-arrow">
        <button class="shift-inc-toggle" @click="setNextShift(1)" :disabled="!canNext || disabled">
          {{ nextIcon }}
        </button>
      </div>
      <div class="gap"></div>

      <icon v-if="showRefresh" class="refresh-icon" :icon="refreshIcon" @click="onRefresh" />
      <span v-if="!isUsingSiteTimezone" class="timezone-different">(Site time only)</span>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import CalendarIcon from './icons/Calendar.vue';
import RefreshIcon from './icons/Refresh.vue';
import { Datetime } from 'vue-datetime';
import { chunkEvery } from '../code/helpers.js';
import { formatDate } from '../code/time';

function pad(num) {
  if (num < 10) {
    return `0${num}`;
  }
  return `${num}`;
}

function getShiftDateString(shift) {
  if (!shift) {
    return null;
  }

  const { year, month, day } = shift.site;

  return `${year}-${pad(month)}-${pad(day)}T00:00:00.000Z`;
}

function getLocalDatetimeString(datetime) {
  return formatDate(datetime, '%Y-%m-%dT%HH:%MM:%SSZ');
}

function shiftEncompassing(shifts, datetime) {
  let timestamp = datetime;
  if (isNaN(datetime)) {
    timestamp = datetime.getTime();
  }
  return shifts.find(s => s.endTime.getTime() > timestamp && s.startTime.getTime() < timestamp);
}

function randomDateSelectorId() {
  const id = Math.trunc(Math.random() * 1000);
  return `shift-date-selector-${id}`;
}

export default {
  name: 'ShiftSelector',
  components: {
    Icon,
    Datetime,
  },
  props: {
    value: { type: Object, default: null },
    shifts: { type: Array, default: () => [] },
    shiftTypes: { type: Array, deafult: () => [] },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    showRefresh: { type: Boolean, default: true },
    showIcon: { type: Boolean, default: true },
    disabled: { type: Boolean, default: false },
    dateSelectorId: { type: String, default: () => randomDateSelectorId() },
  },
  data: () => {
    return {
      calendarIcon: CalendarIcon,
      refreshIcon: RefreshIcon,
      prevIcon: '<',
      nextIcon: '>',
      shiftDateStr: null,
    };
  },
  computed: {
    isUsingSiteTimezone() {
      return this.$timely.current.isSite;
    },
    shift: {
      get() {
        const shiftId = (this.value || {}).id;
        const shiftIndex = (this.value || {}).index;
        const shift = this.indexedShifts.find(s => s.id === shiftId);
        if (!shift) {
          this.setShift(this.getCurrentShift());
        } else if (!shiftIndex) {
          this.setShift(shift);
        }

        this.shiftDateStr = getShiftDateString(shift);
        return shift;
      },
      set(shift) {
        this.setShift(shift);
      },
    },
    minDatetimeStr() {
      const minTimestamp = (this.indexedShifts[0] || {}).startTime;
      const minDatetime = this.minDatetime || minTimestamp;
      if (!minDatetime) {
        return null;
      }
      return getLocalDatetimeString(minDatetime);
    },
    maxDatetimeStr() {
      const maxTimestamp = (this.indexedShifts[this.indexedShifts.length - 1] || {}).endTime;
      const maxDatetime = this.maxDatetime || maxTimestamp;
      if (!maxDatetime) {
        return null;
      }
      return getLocalDatetimeString(maxDatetime);
    },
    indexedShifts() {
      const shifts = this.shifts.map(s => {
        return {
          id: s.id,
          startTime: new Date(s.startTime),
          endTime: new Date(s.endTime),
          shiftTypeId: s.shiftTypeId,
          site: {
            year: s.site.year,
            month: s.site.month,
            day: s.site.day,
          },
        };
      });

      shifts.sort((a, b) => a.startTime.getTime() - b.startTime.getTime());

      shifts.forEach((s, index) => (s.index = index));

      return shifts;
    },
    shiftType() {
      const shiftTypeId = (this.shift || {}).shiftTypeId;
      return this.circularShiftTypes.find(st => st.id === shiftTypeId);
    },
    shiftTypeName() {
      return (this.shiftType || {}).name;
    },
    shiftTypeId() {
      return (this.shiftType || {}).id;
    },
    earliestShift() {
      if (this.minDatetime) {
        return shiftEncompassing(this.indexedShifts, this.minDatetime);
      }

      return this.indexedShifts[0];
    },
    latestShift() {
      if (this.maxDatetime) {
        return shiftEncompassing(this.indexedShifts, this.maxDatetime);
      }
      return this.indexedShifts[this.indexedShifts.length - 1];
    },
    circularShiftTypes() {
      const shiftTypes = this.shiftTypes.map(st => {
        return {
          id: st.id,
          name: st.name,
        };
      });
      shiftTypes.sort((a, b) => a.id - b.id);

      chunkEvery(shiftTypes, 2, 1, 'discard').forEach(([cur, next]) => {
        cur.next = next;
        next.prev = cur;
      });

      const first = shiftTypes[0];
      const last = shiftTypes[shiftTypes.length - 1];

      first.prev = last;
      last.next = first;

      return shiftTypes;
    },
    canNext() {
      if (!this.shift) {
        return false;
      }

      if (this.maxDatetime && this.maxDatetime.getTime() < this.shift.endTime.getTime()) {
        return false;
      }

      return this.shift.index < this.indexedShifts.length - 1;
    },
    canPrev() {
      if (!this.shift) {
        return false;
      }

      if (this.minDatetime && this.minDatetime.getTime() > this.shift.startTime.getTime()) {
        return false;
      }

      return this.shift.index !== 0;
    },
  },
  watch: {
    indexedShifts: {
      immediate: true,
      handler(shifts) {
        if (!this.shift) {
          this.shift = this.getCurrentShift();
        }
      },
    },
  },
  methods: {
    setShift(shift) {
      this.$emit('input', shift);
      this.$emit('change', shift);
    },
    getCurrentShift() {
      const earliestStart = this.earliestShift ? this.earliestShift.startTime.getTime() : -Infinity;
      const latestEnd = this.latestShift ? this.latestShift.endTime.getTime() : Infinity;
      const now = Date.now();

      if (now < earliestStart) {
        return this.earliestShift;
      }

      if (now > latestEnd) {
        return this.latestShift;
      }

      return shiftEncompassing(this.indexedShifts, now);
    },
    toggleShift() {
      // get the next shiftTypeId
      const nextShiftTypeId = this.shiftType.next.id;
      const { day, month, year } = this.shift.site;
      const shift = this.indexedShifts.find(
        ({ shiftTypeId, site }) =>
          site.day === day &&
          site.month === month &&
          site.year === year &&
          shiftTypeId === nextShiftTypeId,
      );

      this.setShift(shift);
    },
    onDateChange(datetimeStr) {
      if (!datetimeStr) {
        return;
      }
      const year = parseInt(datetimeStr.slice(0, 4), 10);
      const month = parseInt(datetimeStr.slice(5, 7), 10);
      const day = parseInt(datetimeStr.slice(8, 10), 10);

      const shift = this.indexedShifts.find(
        ({ shiftTypeId, site }) =>
          site.day === day &&
          site.month === month &&
          site.year === year &&
          shiftTypeId === this.shiftTypeId,
      );

      this.setShift(shift);
    },
    onToday() {
      this.setShift(this.getCurrentShift());
    },
    onRefresh() {
      if (!this.disabled) {
        this.$emit('refresh');
      }
    },
    setNextShift(offset) {
      const nextShift = this.getNextShift(offset);
      if (nextShift) {
        // if there is a min time, check that the end time is not smaller than it
        if (this.minDatetime && nextShift.endTime.getTime() < this.minDatetime.getTime()) {
          return;
        }

        // if there is a mx time, check that the dates start time is not greater than it
        if (this.maxDatetime && nextShift.startTime.getTime() > this.maxDatetime.getTime()) {
          return;
        }

        this.setShift(nextShift);
      }
    },
    getNextShift(step = 0) {
      return this.indexedShifts[this.shift.index + step];
    },
  },
};
</script>

<style>
.shift-selector {
  display: flex;
  padding: 1rem 0;
}

.shift-selector .shift-selector-button-wrapper {
  display: flex;
  margin: auto 0;
}

.shift-selector .calendar-icon.hx-icon {
  width: 3rem;
}

.shift-selector .gap {
  width: 0.3rem;
}

.shift-selector .shift-button,
.shift-selector .vdatetime-input {
  cursor: pointer;
  width: 8em;
  height: 1.25rem;
  color: #0c1419;
  background-color: #ededed;
  border-style: none;
  text-align: center;
  user-select: none;
}

.shift-selector .shift-inc-toggle {
  cursor: pointer;
  width: 2em;
  height: 1.25rem;
  color: #0c1419;
  background-color: #ededed;
  border-style: none;
  text-align: center;
  padding-top: 0.2em;
}

.shift-selector .shift-inc-toggle[disabled],
.shift-selector .shift-button[disabled],
.shift-selector .vdatetime-input[disabled] {
  cursor: default;
  opacity: 0.5;
}

.shift-selector button,
.shift-selector .shift-inc-toggle,
.shift-selector .vdatetime-input {
  outline: none;
  transition: 0.2s;
}

.shift-selector .refresh-icon.hx-icon {
  cursor: pointer;
  width: 1.3rem;
  height: 1.3rem;
}

.shift-selector .timezone-different {
  margin-left: 0.5rem;
  font-style: italic;
  line-height: 1.25rem;
}
</style>