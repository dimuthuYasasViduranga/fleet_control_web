<template>
  <div class="dately">
    <transition name="dately-modal">
      <div
        v-show="showDateModal"
        ref="modal-mask"
        class="modal-mask"
        @click="onCloseDateModal()"
        @keyup.esc="onCloseDateModal()"
        @keyup.enter="onOk()"
        tabindex="0"
      >
        <div class="modal-container" @click.stop>
          <div class="date-header">
            <div class="year" @click="onOpenYearPane()">{{ modalDate.year }}</div>
            <div class="date" @click="onOpenMonthPane()">
              {{ modalDate.date }} {{ selectedMonthName }}
            </div>
          </div>

          <div class="calendar-pane">
            <div v-if="showYearPane" class="year-pane">
              <Scrollable ref="scrollable-year" :options="{ wheelSpeed: 0.25 }">
                <button
                  class="scrollable-entry"
                  v-for="year in scrollableYears"
                  :key="year.name"
                  :class="{ selected: year.selected, first: year.first, last: year.last }"
                  @click="onYearSelect(year)"
                >
                  {{ year.year }}
                </button>
              </Scrollable>
            </div>
            <div v-else-if="showMonthPane" class="month-pane">
              <Scrollable ref="scrollable-month" :options="{ wheelSpeed: 0.25 }">
                <button
                  class="scrollable-entry"
                  v-for="month in scrollableMonths"
                  :key="month.name"
                  :class="{ selected: month.selected, first: month.first, last: month.last }"
                  @click="onMonthSelect(month)"
                >
                  {{ month.name }}
                </button>
              </Scrollable>
            </div>
            <div v-else class="calendar-area">
              <div class="month-navigator">
                <div class="arrow prev-arrow" @click="moveNavigatorMonth(-1)">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 61.3 102.8">
                    <path
                      fill="none"
                      stroke="#444"
                      stroke-width="14"
                      stroke-miterlimit="10"
                      d="M56.3 97.8L9.9 51.4 56.3 5"
                    />
                  </svg>
                </div>
                <div class="content">{{ navigatorMonthName }} {{ navigator.year }}</div>
                <div class="arrow next-arrow" @click="moveNavigatorMonth(1)">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 61.3 102.8"
                    transform="scale(-1 1)"
                  >
                    <path
                      fill="none"
                      stroke="#444"
                      stroke-width="14"
                      stroke-miterlimit="10"
                      d="M56.3 97.8L9.9 51.4 56.3 5"
                    />
                  </svg>
                </div>
              </div>
              <table>
                <thead>
                  <tr>
                    <th>Mon</th>
                    <th>Tue</th>
                    <th>Wed</th>
                    <th>Thu</th>
                    <th>Fri</th>
                    <th>Sat</th>
                    <th>Sun</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(row, rowIndex) in calendarGrid" :key="`calendar-${rowIndex}`">
                    <td v-for="(day, colIndex) in row" :key="`calendar-${rowIndex}-${colIndex}`">
                      <button
                        class="day-wrapper"
                        :disabled="getCalendarDayDisabled(day)"
                        @click="setModalDate(day)"
                      >
                        <Bubble class="calendar-day" :class="getCalendarDayClass(day)" color="">
                          {{ day.day }}
                        </Bubble>
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div class="actions">
              <div class="action-btn" @click="onCloseDateModal()">Cancel</div>
              <div class="action-btn" @click="onOk()">Ok</div>
            </div>
          </div>
        </div>
      </div>
    </transition>
    <div class="date-component">
      <button class="date-button" @click="onOpenDateModal">{{ dateButtonText }}</button>
    </div>
    <div class="time-component">
      <input
        v-tooltip="errorTooltip"
        class="time-input"
        :value="inputTimeString"
        :class="{ invalid: hasErrors }"
        @change="onInputTimeChange"
        placeholder="HH:MM:SS"
        :maxLength="8"
      />
      <div v-if="hasErrors" v-tooltip="errorTooltip" class="reset-wrapper" @click="onResetTime()">
        <Icon class="reset-icon" :icon="refreshIcon" />
      </div>
    </div>
  </div>
</template>

<script>
import { DateTime, Info } from 'luxon';
import Icon from 'hx-layout/Icon.vue';
import Scrollable from '@/components/Scrollable.vue';
import { pad, setTimeZone, toUtcDate } from '@/code/time';

import RefreshIcon from '@/components/icons/Refresh.vue';
import Bubble from '@/components/Bubble.vue';
import {
  getDatesOfMonth,
  alignDatesOfMonth,
  extrapolateTimeFromString,
  isValidTime,
  deconstructDate,
  dayLessThan,
  dayGreaterThan,
  dateInRange,
} from './dately.js';

export default {
  name: 'Dately',
  components: {
    Icon,
    Bubble,
    Scrollable,
  },
  props: {
    value: Date,
    timezone: { type: String, default: 'local' },
    minDatetime: { type: [Object, Date, String], default: '' },
    maxDatetime: { type: [Object, Date, String], default: '' },
    yearsPadding: { type: Number, default: 20 },
  },
  data: () => {
    return {
      refreshIcon: RefreshIcon,
      showDateModal: false,
      modalDate: {
        year: 1970,
        month: 1,
        day: 1,
      },
      navigator: {
        year: 1970,
        month: 1,
      },
      inputTimeString: '',
      proposedDate: deconstructDate(new Date(null)),
      errors: {
        belowMin: false,
        aboveMax: false,
        invalidText: false,
      },
      showYearPane: false,
      showMonthPane: false,
    };
  },
  computed: {
    minDatetimeJS() {
      return this.minDatetime ? new Date(this.minDatetime) : null;
    },
    maxDatetimeJS() {
      return this.maxDatetime ? new Date(this.maxDatetime) : null;
    },
    calendarGrid() {
      const dates = getDatesOfMonth(this.navigator.year, this.navigator.month);
      return alignDatesOfMonth(dates);
    },
    monthNames() {
      return Info.months();
    },
    scrollableYears() {
      const currentYear = new Date().getFullYear();

      let minYear = currentYear - this.yearsPadding;
      let maxYear = currentYear + this.yearsPadding;

      if (this.minDatetimeJS) {
        minYear = setTimeZone(this.minDatetimeJS, this.timezone).toObject().year;
      }

      if (this.maxDatetimeJS) {
        maxYear = setTimeZone(this.maxDatetimeJS, this.timezone).toObject().year;
      }

      const years = [];
      for (let i = minYear; i <= maxYear; i++) {
        years.push({
          year: i,
          selected: i === this.navigator.year,
        });
      }

      years[0].first = true;
      years[years.length - 1].last = true;

      return years;
    },
    scrollableMonths() {
      const min = { year: 0, month: 0 };
      const max = { year: Infinity, month: 13 };

      if (this.minDatetimeJS) {
        const minObj = setTimeZone(this.minDatetimeJS, this.timezone).toObject();
        min.year = minObj.year;
        min.month = minObj.month;
      }

      if (this.maxDatetimeJS) {
        const maxObj = setTimeZone(this.maxDatetimeJS, this.timezone).toObject();
        max.year = maxObj.year;
        max.month = maxObj.month;
      }

      const months = this.monthNames
        .map((name, index) => {
          const month = index + 1;
          const selected = index + 1 === this.navigator.month;
          const disabled = false;

          const givenYear = this.navigator.year;
          const beforeMin = givenYear <= min.year && month < min.month;
          const afterMax = givenYear >= max.year && month > max.month;

          return {
            name,
            month,
            selected,
            disabled: beforeMin || afterMax,
          };
        })
        .filter(m => !m.disabled);

      months[0].first = true;
      months[months.length - 1].last = true;

      return months;
    },
    navigatorMonthName() {
      return this.monthNames[this.navigator.month - 1];
    },
    selectedMonthName() {
      return this.monthNames[this.modalDate.month - 1];
    },
    dateButtonText() {
      const date = this.proposedDate;
      if (!date || !date.year || !date.month || !date.day) {
        return 'Select Date';
      }
      const shortMonth = Info.months('short')[date.month - 1];
      return `${date.year} ${shortMonth} ${date.day}`;
    },
    hasErrors() {
      return Object.values(this.errors).some(a => a);
    },
    errorTooltip() {
      if (!this.hasErrors) {
        return;
      }

      const errors = [];

      if (this.errors.invalid) {
        console.error('[Dately] Provided date object is invalid');
        errors.push('Provided date object is invalid');
      }

      if (this.errors.invalidText) {
        errors.push(`Please enter valid time 'HH:MM:SS'`);
      }

      if (this.errors.belowMin) {
        const min = setTimeZone(this.minDatetimeJS, this.timezone).toFormat('yyyy-MM-dd HH:mm:ss');
        errors.push(`Must be greater than ${min}`);
      }

      if (this.errors.aboveMax) {
        const max = setTimeZone(this.maxDatetimeJS, this.timezone).toFormat('yyyy-MM-dd HH:mm:ss');
        errors.push(`Must be less than ${max}`);
      }

      const errorList = errors.map(e => `<li>${e}</li>`);
      errorList.unshift('<ul>');
      errorList.push('</ul>');

      return {
        html: true,
        content: errorList.join(''),
        classes: 'dately-error-popover',
      };
    },
  },
  mounted() {
    this.resetProposedDate();
    this.setModalDate(this.proposedDate);
    this.setNavigatorDate(this.proposedDate);
    this.setInputTime(this.proposedDate);
  },
  watch: {
    value: {
      immediate: true,
      handler() {
        this.resetProposedDate();
        this.setModalDate(this.proposedDate);
        this.setNavigatorDate(this.proposedDate);
        this.setInputTime(this.proposedDate);
      },
    },
    showDateModal: {
      immediate: true,
      handler(doShow) {
        if (doShow) {
          this.$nextTick(() => {
            this.$refs['modal-mask'].focus();
          });
          this.setModalDate(this.proposedDate);
          this.setNavigatorDate(this.proposedDate);
        }
      },
    },
  },
  methods: {
    onOpenDateModal() {
      this.showDateModal = true;
    },
    onCloseDateModal() {
      this.showDateModal = false;
      this.showYearPane = false;
      this.showMonthPane = false;
    },
    resetProposedDate() {
      const date = this.value;
      this.proposedDate = deconstructDate(date, this.timezone);
      if (!date) {
        this.inputTimeString = '';
      }
    },
    getCalendarDayClass(day) {
      const modalDate = this.modalDate;
      const selected =
        day &&
        day.year === modalDate.year &&
        day.month === modalDate.month &&
        day.day === modalDate.day;

      const today = DateTime.fromJSDate(new Date()).setZone(this.timezone).toObject();
      const isToday = day.year === today.year && day.month === today.month && day.day === today.day;

      return { selected, today: isToday && !selected };
    },
    getCalendarDayDisabled(day) {
      return (
        !day.year ||
        dayLessThan(day, this.minDatetimeJS, this.timezone) ||
        dayGreaterThan(day, this.maxDatetimeJS, this.timezone)
      );
    },
    setModalDate(components) {
      const { year, month, day } =
        components ||
        deconstructDate(dateInRange(this.minDatetimeJS, this.maxDatetimeJS), this.timezone);
      if (year && month && day) {
        this.modalDate = {
          year,
          month,
          day,
        };
      }
    },
    setNavigatorDate(components) {
      // the deconstruct date needs to consider the min and max datetimes
      const { year, month } =
        components ||
        deconstructDate(dateInRange(this.minDatetimeJS, this.maxDatetimeJS), this.timezone);
      if (year && month) {
        this.navigator = { year, month };
      }
    },
    setInputTime(components) {
      const { hour, minute, second } = components || {};
      if (hour !== undefined && minute !== undefined && second !== undefined) {
        this.inputTimeString = `${pad(hour)}:${pad(minute)}:${pad(second)}`;
      } else {
        this.inputTimeString = '';
      }
    },
    moveNavigatorMonth(amount) {
      const newMonth = this.navigator.month + amount;
      if (newMonth > 12) {
        this.navigator.month = 1;
        this.navigator.year += 1;
      } else if (newMonth < 1) {
        this.navigator.month = 12;
        this.navigator.year -= 1;
      } else {
        this.navigator.month = newMonth;
      }
    },
    onOk() {
      if (this.showMonthPane || this.showYearPane) {
        this.clearPanes();
        return;
      }

      this.proposedDate = { ...this.proposedDate, ...this.modalDate };
      this.tryEmitDate();
      this.onCloseDateModal();
    },
    onResetTime() {
      this.clearErrors();
      this.resetProposedDate();
      this.setInputTime(this.proposedDate);
    },
    onInputTimeChange(event) {
      const timeString = extrapolateTimeFromString(event.target.value);

      this.inputTimeString = timeString;
      this.tryEmitDate();
    },
    onOpenYearPane() {
      this.showYearPane = true;
      this.showMonthPane = false;

      // determine the selected year and scroll accordingly (48 == text height)
      const offset = (this.navigator.year - this.scrollableYears[0].year) * 48;
      this.$nextTick(() => {
        this.$refs['scrollable-year'].scrollTo(offset);
      }, 0);
    },
    onOpenMonthPane() {
      this.showYearPane = false;
      this.showMonthPane = true;

      // determine the selected month and scroll accordingly (48 == text height)
      const offset = (this.navigator.month - 1) * 48;
      this.$nextTick(() => {
        this.$refs['scrollable-month'].scrollTo(offset);
      }, 0);
    },
    clearPanes() {
      this.showYearPane = false;
      this.showMonthPane = false;
    },
    onMonthSelect({ month }) {
      this.navigator.month = month;
    },
    onYearSelect({ year }) {
      this.navigator.year = year;
    },
    clearErrors() {
      this.errors = {
        invalid: false,
        belowMin: false,
        aboveMax: false,
        invalidText: false,
      };
    },
    tryEmitDate() {
      this.clearErrors();

      if (
        !this.inputTimeString ||
        !this.proposedDate ||
        !this.proposedDate.year ||
        !this.proposedDate.month ||
        !this.proposedDate.day
      ) {
        // this represents the case in which neither elements have been set yet
        return;
      }

      if (!isValidTime(this.inputTimeString)) {
        this.errors.invalidText = true;
        return;
      }

      const [hours, minutes, seconds] = this.inputTimeString.split(':');

      const timeComponents = {
        hour: parseInt(hours, 10),
        minute: parseInt(minutes, 10),
        second: parseInt(seconds, 10),
      };

      this.proposedDate = { ...(this.proposedDate || {}), ...timeComponents };

      const localisedLuxDate = DateTime.fromObject({
        year: this.proposedDate.year,
        month: this.proposedDate.month,
        day: this.proposedDate.day,
        ...timeComponents,
        zone: this.timezone,
      });

      if (localisedLuxDate.invalid) {
        this.errors.invalid = true;
        return;
      }

      const jsDate = localisedLuxDate.toJSDate();

      if (this.minDatetimeJS && jsDate.getTime() < this.minDatetimeJS.getTime()) {
        this.errors.belowMin = true;
        return;
      }

      if (this.maxDatetimeJS && jsDate.getTime() > this.maxDatetimeJS.getTime()) {
        this.errors.aboveMax = true;
        return;
      }

      this.$emit('input', jsDate);
    },
  },
};
</script>

<style>
.dately {
  display: inline-flex;
}

/* ---- modal styling --- */
.dately .modal-mask {
  position: fixed;
  display: flex;
  flex-direction: column;
  justify-content: center;
  z-index: 9998;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  transition: opacity 0.3s ease;
  overflow: auto;
  color: #b6c3cc;
  font-family: 'GE Inspira Sans', sans-serif;
}

.dately .modal-container {
  width: 340px;
  height: 530px;
  background-color: white;
  padding: 0;
}

/* ---- date header ---- */
.dately .date-header {
  height: 84px;
  padding: 18px 30px;
  background-color: #425866;
  text-align: center;
  color: white;
}

.dately .date-header .year {
  font-weight: 200;
  font-size: 16px;
  cursor: pointer;
  transition: opacity 0.3s;
  color: rgb(214, 214, 214);
  height: 1.25rem;
}

.dately .date-header .date {
  font-size: 32px;
  cursor: pointer;
}

/* --- month navigator --- */
.dately .month-navigator {
  height: 18px;
  margin: 15px 0;
  text-align: center;
  color: black;
  display: flex;
  justify-content: space-around;
  user-select: none;
}

.dately .month-navigator .content {
  width: 10rem;
}

.dately .month-navigator .arrow {
  height: 12px;
  width: 1rem;
  cursor: pointer;
}

.dately .month-navigator .arrow svg {
  height: 100%;
}

/* ---- calendar area ----- */
.dately .calendar-area table {
  table-layout: fixed;
  width: 100%;
  height: 100%;
}

.dately .calendar-area th {
  color: black;
  text-align: center;
  user-select: none;
}

.dately .calendar-area td .day-wrapper {
  cursor: pointer;
  background-color: transparent;
  padding: 0;
  margin: 0;
  box-shadow: none;
  border: none;
  outline: none;
}

.dately .calendar-area td .day-wrapper[disabled] {
  opacity: 0.3;
  cursor: default;
}

.dately .calendar-area .calendar-day,
.dately .calendar-area .calendar-day .day-wrapper {
  margin: 0;
  padding: 0;
  width: 3rem;
  height: 3rem;
}

.dately .calendar-area .calendar-day .bubble {
  font-weight: 200;
  color: #444444;
}

.dately .calendar-area .calendar-day.selected .bubble {
  background-color: #425866;
  padding-top: 3px;
  padding-right: 0;
  color: white;
}

.dately .calendar-area .calendar-day.today .bubble {
  background-color: rgb(230, 230, 230);
  padding-top: 3px;
  padding-right: 0;
}

/* ---- year/month pane ----- */
.dately .scrollable {
  height: 405px;
}

.dately .scrollable .ps .ps__rail-y,
.dately .scrollable .ps .ps__rail-x {
  background-color: white;
}

.dately .scrollable-entry {
  display: block;
  height: 3rem;
  width: 100%;
  text-align: center;
  font-size: 2rem;
  color: #555;
  cursor: pointer;
  border: none;
  outline: none;
  background-color: transparent;
  box-shadow: none;
  opacity: 0.75;
}

.dately .scrollable-entry:hover {
  opacity: 1;
}

.dately .scrollable-entry.first {
  margin-top: 175px;
}

.dately .scrollable-entry.last {
  margin-bottom: 175px;
}

.dately .scrollable-entry.selected {
  color: #007acc;
  opacity: 1;
}

/* ---- Actions ----- */
.dately .actions {
  height: 2rem;
  display: flex;
  justify-content: flex-end;
  margin-right: 0.5rem;
}

.dately .actions .action-btn {
  color: #007acc;
  width: 3rem;
  margin: 0 1rem;
  line-height: 2rem;
  text-align: center;
  cursor: pointer;
}

.dately .actions .action-btn:hover {
  opacity: 0.75;
}

/* ----- modal transitions ------ */
.dately-modal-enter {
  opacity: 0;
}

.dately-modal-leave-active {
  opacity: 0;
}

.dately-modal-enter .modal-container,
.dately-modal-leave-active .modal-container {
  -webkit-transform: scale(1.1);
  transform: scale(1.1);
}

/* ----- date selector ----- */
.dately .date-button {
  color: white;
  overflow: hidden;
  height: 2rem;
  min-width: 7rem;
  border: 1px solid transparent;
  border-radius: 0;
  padding: 0 1rem;
  box-shadow: none;
  line-height: 1rem;
  -webkit-font-smoothing: antialiased;
  cursor: pointer;
  text-align: center;
  white-space: nowrap;
  background-color: #425866;
  transition: background 0.4s, border-color 0.4s, color 0.4s, opacity 0.4s;
  user-select: none;
}

.dately .date-button:hover {
  opacity: 0.75;
}

.dately .date-button:focus {
  outline: none;
}

/* ---- time selector ---- */
.dately .time-component {
  display: flex;
}

.dately .time-input {
  height: 2rem;
  width: 6rem;
  border: none;
  border-radius: 0;
  border-bottom: 1px solid #677e8c;
  padding: 0 0.33333rem;
  color: #b6c3cc;
  background-color: transparent;
  outline: none;
  transition: background 0.4s, border-color 0.4s, color 0.4s;
}

.dately .time-input:focus {
  background-color: white;
  color: #0c1419;
  outline: none;
}

.dately .time-input.invalid {
  transition: background 0.4s, border-color 0.4s, color 0.4s;
  background-color: #461212;
  color: #b6c3cc;
}

.dately .time-input.invalid:focus {
  transition: background 0.4s, border-color 0.4s, color 0.4s;
  background-color: #461212;
  color: #b6c3cc;
}

/* ---- reset button ----- */
.dately .time-component .reset-wrapper {
  position: relative;
  right: 2rem;
  height: 2rem;
  width: 2rem;
  padding: 0.5rem;
  cursor: pointer;
}

.dately .time-component .reset-wrapper .reset-icon {
  width: 100%;
  height: 100%;
}

.dately .time-component .reset-wrapper:hover {
  opacity: 0.75;
}
</style>