<template>
  <table class="error-table-row">
    <tr>
      <td class="selector-column" @click="onRowSelect"></td>
      <td v-if="!isMaterialTimeline" class="time-code-column">
        <TimeAllocationDropDown
          :value="timeSpan.data.timeCodeId"
          :allowedTimeCodeIds="allowedTimeCodeIds"
          @change="onTimeCodeChange"
        />
      </td>
      <td v-else class="time-code-column">
        <DropDown
          class="tc-drop-down"
          :value="timeSpan.data.materialTypeId"
          :options="materialTypes"
          label="name"
          placeholder="select Material Type"
          direction="auto"
          :disabled="false"
          :holdOpen="false"
          @change="onMaterialTypeChange"
        />
      </td>
      <td class="start-time-column">
        <Dately
          v-model="startTime"
          :minDatetime="minDatetime"
          :maxDatetime="endTime"
          :timezone="timezone"
        />
      </td>
      <td class="end-time-column">
        <Dately
          v-model="endTime"
          :minDatetime="startTime"
          :maxDatetime="maxDatetime"
          :timezone="timezone"
        />
      </td>
      <td class="action-column">
        <LockableButton v-if="timeSpan.level !== 0" @click="onFix">Fix</LockableButton>
        <LockableButton v-else @click="onDelete">Delete</LockableButton>
      </td>
    </tr>
  </table>
</template>

<script>
import LockableButton from '@/components/LockableButton.vue';
import Dately from '@/components/dately/Dately.vue';
import TimeAllocationDropDown from '@/components/TimeAllocationDropDown.vue';
import { DropDown } from 'hx-vue';
import { mapState } from 'vuex';

const MISSING_COLOR = 'magenta';

export default {
  name: 'ErrorTableRow',
  components: {
    LockableButton,
    Dately,
    TimeAllocationDropDown,
    DropDown,
  },
  props: {
    isMaterialTimeline: { type: Boolean, default: () => false },
    timeSpan: { type: Object, required: true },
    allowedTimeCodeIds: { type: Array, default: () => [] },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
  },
  computed: {
    ...mapState('constants', {
      materialTypes: state => state.materialTypes,
    }),
    startTime: {
      get() {
        return this.timeSpan.startTime;
      },
      set(val) {
        this.emitChange({ ...this.timeSpan, startTime: new Date(val) });
      },
    },
    endTime: {
      get() {
        return this.timeSpan.endTime;
      },
      set(val) {
        this.emitChange({ ...this.timeSpan, endTime: new Date(val) });
      },
    },
  },
  methods: {
    emitChange(timeSpan) {
      this.$emit('change', timeSpan);
    },
    onTimeCodeChange(timeCodeId) {
      // eslint-disable-next-line vue/no-mutating-props
      this.timeSpan.data.timeCodeId = timeCodeId || null;
      this.emitChange(this.timeSpan);
    },
    onMaterialTypeChange(materialTypeId) {
      // eslint-disable-next-line vue/no-mutating-props
      this.timeSpan.data.materialTypeId = materialTypeId || null;
      this.emitChange(this.timeSpan);
    },
    onRowSelect() {
      this.$emit('select');
    },
    onFix() {
      this.$emit('fix');
    },
    onDelete() {
      // eslint-disable-next-line vue/no-mutating-props
      this.timeSpan.data.deleted = true;
      this.emitChange(this.timeSpan);
    },
  },
};
</script>

<style>
.error-table-row {
  width: 100%;
  background-color: rgba(114, 9, 9, 0.158);
  padding-right: 0.75rem;
  border-bottom: 0.05em solid #2c404c;
  border-left: 0;
}

.error-table-row .selector-column {
  background-color: #2c404c;
  cursor: pointer;
}

.error-table-row.selected {
  background-color: #00000028;
}

.error-table-row.selected .selector-column {
  background-color: #1a262e;
}

.error-table-row td {
  text-align: center;
}

.error-table-row .time-code-column .time-allocation-drop-down .dropdown-wrapper {
  height: 1.75rem;
}

.error-table-row .hx-select {
  width: 100%;
  height: 1.6rem;
  padding: 0 1rem;
}
</style>
