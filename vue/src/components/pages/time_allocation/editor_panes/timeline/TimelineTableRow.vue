<template>
  <table class="timeline-table-row">
    <tr>
      <td class="selector-column" @click="onRowSelect"></td>
      <td class="time-code-column">
        <TimeAllocationDropDown
          v-if="canEditTimeCode"
          :value="timeSpan.data.timeCodeId"
          :allowedTimeCodeIds="allowedTimeCodeIds"
          :showAll="showAllTimeCodes"
          @change="onTimeCodeChange"
        />
        <div v-else>
          {{ timeCode }}
        </div>
      </td>
      <td class="start-time-column">
        <Dately
          v-if="canEditStart"
          v-model="startTime"
          :minDatetime="minStartTime"
          :maxDatetime="maxStartTime"
          :timezone="timezone"
        />
        <div v-else>
          {{ formatDate(startTime, '%d %b %Y %HH:%MM:%SS') }}
        </div>
      </td>
      <td class="end-time-column">
        <Dately
          v-if="canEditEnd"
          v-model="endTime"
          :minDatetime="minEndTime"
          :maxDatetime="maxEndTime"
          :timezone="timezone"
        />
        <div v-else-if="!timeSpan.endTime">
          <LockableButton @click="onEndtimeSpan">End</LockableButton>
        </div>
        <div v-else>
          {{ formatDate(timeSpan.endTime, '%d %b %Y %HH:%MM:%SS') }}
        </div>
      </td>
      <td class="action-column">
        <div class="action-buttons-wrapper">
          <Icon
            v-if="hasGapBefore && !isLocked"
            v-tooltip="'Fill Backwards'"
            :icon="expandIcon"
            @click="onFillBack"
          />
          <Icon
            v-if="hasGapAfter && !isLocked"
            v-tooltip="'Fill Forwards'"
            :icon="expandIcon"
            :rotation="180"
            @click="onFillForward"
          />
          <Icon v-if="canEditEnd" v-tooltip="'Split'" :icon="splitIcon" @click="onSplit" />

          <Icon
            v-if="canDelete"
            v-tooltip="'Delete'"
            :icon="trashIcon"
            :scale="0.95"
            @click="onDelete"
          />
        </div>
      </td>
    </tr>
  </table>
</template>


<script>
import Icon from 'hx-layout/Icon.vue';
import Dately from '@/components/dately/Dately.vue';
import LockableButton from '@/components/LockableButton.vue';
import TimeAllocationDropDown from '@/components/TimeAllocationDropDown.vue';

import ExpandIcon from '../../../../icons/Expand.vue';
import TrashIcon from '../../../../icons/Trash.vue';
import SplitIcon from '../../../../icons/Split.vue';

import { formatDate, copyDate } from '../../../../../code/time.js';
import { attributeFromList } from '../../../../../code/helpers';
import { coverage } from '../../timeSpan';

function copyTimeSpan(span) {
  return {
    data: { ...span.data, id: null },
    startTime: copyDate(span.startTime),
    endTime: copyDate(span.endTime),
    activeEndTime: copyDate(span.activeEndTime),
  };
}

function getMaxDate(arr) {
  return copyDate(Math.max.apply(null, arr));
}

function dateBetween(a, b) {
  return new Date((a.getTime() + b.getTime()) / 2);
}

export default {
  name: 'TimelineTableRow',
  components: {
    Dately,
    LockableButton,
    TimeAllocationDropDown,
    Icon,
  },
  props: {
    timeSpan: { type: Object, required: true },
    prevTimeSpan: { type: Object, default: null },
    nextTimeSpan: { type: Object, default: null },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
    timeCodes: { type: Array, default: () => [] },
    allowedTimeCodeIds: { type: Array, default: () => [] },
    showAllTimeCodes: { type: Boolean, default: false },
  },
  data: () => {
    return {
      expandIcon: ExpandIcon,
      trashIcon: TrashIcon,
      splitIcon: SplitIcon,
    };
  },
  computed: {
    startTime: {
      get() {
        return this.timeSpan.startTime;
      },
      set(datetime) {
        const changes = [{ ...this.timeSpan, startTime: datetime }];

        if (
          this.prevTimeSpan &&
          (this.prevTimeSpan.endTime.getTime() === this.timeSpan.startTime.getTime() ||
            this.prevTimeSpan.endTime.getTime() >= datetime.getTime())
        ) {
          changes.push({ ...this.prevTimeSpan, endTime: datetime });
        }

        this.emitChanges(changes);
      },
    },
    endTime: {
      get() {
        return this.timeSpan.endTime;
      },
      set(datetime) {
        const changes = [{ ...this.timeSpan, endTime: datetime }];

        const nextTimeSpan = this.nextTimeSpan;
        if (
          nextTimeSpan &&
          (nextTimeSpan.startTime.getTime() === this.timeSpan.endTime.getTime() ||
            nextTimeSpan.startTime.getTime() <= datetime.getTime())
        ) {
          changes.push({ ...nextTimeSpan, startTime: datetime });
        }

        this.emitChanges(changes);
      },
    },
    minStartTime() {
      if (this.prevTimeSpan) {
        const prevStartTime = this.prevTimeSpan.startTime;
        if (this.minDatetime && this.minDatetime.getTime() > prevStartTime.getTime()) {
          return this.minDatetime;
        }
        return prevStartTime;
      } else {
        return this.minDatetime;
      }
    },
    maxStartTime() {
      return this.timeSpan.endTime || this.maxDatetime;
    },
    minEndTime() {
      const startTime = this.timeSpan.startTime;
      if (this.minDatetime && startTime.getTime() < this.minDatetime.getTime()) {
        return this.minDatetime;
      }
      return startTime;
    },
    maxEndTime() {
      if (this.nextTimeSpan) {
        return this.nextTimeSpan.endTime || this.nextTimeSpan.activeEndTime;
      } else {
        return this.maxDatetime;
      }
    },
    canEditStart() {
      const prevLocked = this.prevTimeSpan && !!this.prevTimeSpan.data.lockId;
      return (
        !this.isLocked &&
        !prevLocked &&
        this.minDatetime &&
        this.startTime.getTime() >= this.minDatetime.getTime()
      );
    },
    canEditEnd() {
      const nextLocked = this.nextTimeSpan && !!this.nextTimeSpan.data.lockId;
      return (
        !this.isLocked &&
        !nextLocked &&
        this.maxDatetime &&
        this.endTime &&
        this.endTime.getTime() <= this.maxDatetime.getTime()
      );
    },
    canEditTimeCode() {
      return this.canEditStart && !this.isLocked;
    },
    isLocked() {
      return !!this.timeSpan.data.lockId;
    },
    canDelete() {
      const timeSpan = this.timeSpan;
      const bounds = { startTime: this.minDatetime, endTime: this.maxDatetime };
      const isWithinRange =
        this.minDatetime && this.maxDatetime && coverage(bounds, timeSpan) === 'covers';
      return !this.isLocked && !timeSpan.activeEndTime && isWithinRange;
    },
    hasGapBefore() {
      if (!this.prevTimeSpan) {
        return false;
      }
      const endTime = this.prevTimeSpan.endTime || this.prevTimeSpan.activeEndTime;
      return endTime.getTime() !== this.timeSpan.startTime.getTime();
    },
    hasGapAfter() {
      if (!this.nextTimeSpan) {
        return false;
      }
      const endTime = this.timeSpan.endTime || this.timeSpan.activeEndTime;
      return this.nextTimeSpan.startTime.getTime() !== endTime.getTime();
    },
    timeCode() {
      if (this.timeSpan.data.timeCodeId) {
        return attributeFromList(this.timeCodes, 'id', this.timeSpan.data.timeCodeId, 'name');
      }
      return 'Unknown Task';
    },
  },
  methods: {
    formatDate(datetime, format) {
      return formatDate(datetime, format);
    },
    emitChanges(changes) {
      this.$emit('changes', changes);
    },
    onTimeCodeChange(timeCodeId) {
      this.timeSpan.data.timeCodeId = timeCodeId;
      this.emitChanges([this.timeSpan]);
    },
    onRowSelect() {
      this.$emit('select');
    },
    onEndtimeSpan() {
      this.$emit('end', this.timeSpan);
    },
    onDelete() {
      this.timeSpan.data.deleted = true;
      this.emitChanges([this.timeSpan]);
    },
    onFillForward() {
      const endTime = copyDate(this.nextTimeSpan.startTime);
      this.emitChanges([{ ...this.timeSpan, endTime }]);
    },
    onFillBack() {
      const endTime = this.prevTimeSpan.endTime || this.prevTimeSpan.activeEndTime;
      const startTime = copyDate(endTime);
      this.emitChanges([{ ...this.timeSpan, startTime }]);
    },
    onSplit() {
      if (this.timeSpan.activeEndTime) {
        return;
      }

      const midDate = dateBetween(this.timeSpan.startTime, this.timeSpan.endTime);

      const splitAtDate = getMaxDate([this.minDatetime, midDate]);

      const newTimeSpan = copyTimeSpan(this.timeSpan);
      newTimeSpan.startTime = copyDate(splitAtDate);

      this.emitChanges([{ ...this.timeSpan, endTime: splitAtDate }, newTimeSpan]);
    },
  },
};
</script>

<style>
.timeline-table-row {
  width: 100%;
  padding-right: 0.75rem;
  border-bottom: 0.05em solid #2c404c;
  border-left: 0;
}

.timeline-table-row .action-buttons-wrapper {
  display: flex;
  flex-direction: row;
  justify-content: center;
}

.timeline-table-row .action-buttons-wrapper .hx-icon {
  cursor: pointer;
  width: 1.25rem;
  margin: 3px;
}

.timeline-table-row .action-buttons-wrapper .hx-icon:hover {
  opacity: 0.5;
}

.timeline-table-row .selector-column {
  background-color: #2c404c;
  cursor: pointer;
}

.timeline-table-row.selected .selector-column {
  background-color: #1a262e;
}

.timeline-table-row td {
  text-align: center;
}

.timeline-table-row .dropdown-wrapper {
  width: 90%;
  height: 1.6rem;
}
</style>