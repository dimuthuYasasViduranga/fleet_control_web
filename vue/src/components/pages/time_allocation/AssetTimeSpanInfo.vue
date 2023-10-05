<template>
  <div class="asset-time-span-info">
    <div class="info">
      <div class="asset-icon-wrapper">
        <Icon class="asset-icon" :icon="assetIcon" :class="iconClass" />
      </div>
      <div class="asset-name">{{ asset.name }}</div>
      <div class="active-time-allocation">
        <div class="time-code">{{ activeTimeAllocationTimeCode || 'No Active Allocation' }}</div>
        <div class="duration">{{ formatDuration(activeTimeAllocationTimeDuration) }}</div>
      </div>
    </div>

    <div class="chart-wrapper" :class="{ open: isOpen }">
      <TimeSpanChart
        ref="chart"
        :name="asset.name"
        :timeSpans="timeSpans.flat()"
        :layout="chartLayout"
        :margins="margins"
        :colors="timeSpanColors"
        :styler="timeSpanStyler"
        :minDatetime="minDatetime"
        :maxDatetime="maxDatetime"
        :contextHeight="contextHeight"
      >
        <template slot-scope="timeSpan">
          <div class="__tooltip-boundary">
            <AllocationTooltip v-if="timeSpan.group === 'allocation'" :timeSpan="timeSpan" />
            <MaterialTypeToolTip
              v-else-if="timeSpan.group === 'dig-unit-activity'"
              :timeSpan="timeSpan"
            />
            <LoginTooltip v-else-if="timeSpan.group === 'device-assignment'" :timeSpan="timeSpan" />
            <TimeusageTooltip v-else-if="timeSpan.group === 'timeusage'" :timeSpan="timeSpan" />
            <CycleTooltip v-else-if="timeSpan.group === 'cycle'" :timeSpan="timeSpan" />
            <ShiftTooltip v-else-if="timeSpan.group === 'shift'" :timeSpan="timeSpan" />
            <DefaultTooltip v-else :timeSpan="timeSpan" />
          </div>
        </template>
      </TimeSpanChart>
    </div>
    <div class="action-wrapper">
      <Icon
        v-if="!readonly"
        v-tooltip="'Edit Allocation'"
        class="edit-icon"
        :icon="editIcon"
        @click="onEdit"
      />
      <Icon
        v-if="!readonly && showMaterialEditBtn"
        v-tooltip="'Edit Material'"
        class="edit-icon"
        :icon="editIcon"
        @click="onEditMaterial"
      />
      <Icon
        v-tooltip="isOpen ? 'Less' : 'More'"
        class="chevron-icon"
        :icon="chevronRightIcon"
        :rotation="isOpen ? 270 : 90"
        @click="toggleOpen"
      />
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import TimeSpanChart from './chart/TimeSpanChart.vue';

import DefaultTooltip from './tooltips/DefaultTimeSpanTooltip.vue';
import AllocationTooltip from './tooltips/AllocationTimeSpanTooltip.vue';
import LoginTooltip from './tooltips/LoginTimeSpanTooltip.vue';
import MaterialTypeToolTip from './tooltips/MaterialTypeToolTip.vue';
import TimeusageTooltip from './tooltips/TimeusageTimeSpanTooltip.vue';
import CycleTooltip from './tooltips/CycleTimeSpanTooltip.vue';
import ShiftTooltip from './tooltips/ShiftTimeSpanTooltip.vue';

import EditIcon from '@/components/icons/Edit.vue';
import ChevronRightIcon from '@/components/icons/ChevronRight.vue';

import { attributeFromList, dedupByMany, uniq, sortByTime, chunkEvery } from '@/code/helpers';
import { formatSeconds, copyDate } from '@/code/time';
import {
  toDeviceAssignmentSpans,
  loginStyle,
} from './timespan_formatters/deviceAssignmentTimeSpans';
import { toDigUnitActivitySpans, materialStyle } from './timespan_formatters/digUnitActivitySpans';
import {
  toAllocationTimeSpans,
  allocationStyle,
  allocationColors,
} from './timespan_formatters/timeAllocationTimeSpans';
import { toShiftTimeSpans, shiftStyle } from './timespan_formatters/shiftTimeSpans';
import { toTimeusageTimeSpans, timeusageStyle } from './timespan_formatters/timeusageTimeSpans';

import { toCycleTimeSpans, cycleStyle } from './timespan_formatters/cycleTimeSpans';

import TimeSpanEditorModal from '@/components/modals/TimeSpanEditorModal.vue';
import MaterialTypeEditorModal from '@/components/modals/MaterialTypeEditorModal.vue';

const SECONDS_IN_HOUR = 3600;
const SECONDS_IN_DAY = 24 * 60 * 60;

function addActiveEndTime(timeSpan, activeEndTime) {
  if (!timeSpan.endTime) {
    timeSpan.activeEndTime = activeEndTime;
  }

  return timeSpan;
}

function isInRange(timeSpan, minDatetime) {
  if (!minDatetime) {
    return true;
  }

  return (timeSpan.endTime || timeSpan.activeEndTime).getTime() > minDatetime.getTime();
}

function getChartLayoutGroups([TASpans, DUASpans, DASpans, TUSpans, CSpans], asset, isOpen) {
  if (asset.type === 'Haul Truck' && isOpen) {
    return [
      {
        group: 'shift',
        label: 'S',
        percent: 0.15,
        subgroups: [0],
      },
      {
        group: 'device-assignment',
        label: 'Op',
        percent: 0.15,
        subgroups: uniq(DASpans.map(ts => ts.level || 0)),
      },
      {
        group: 'timeusage',
        label: 'TU',
        percent: 0.15,
        subgroups: uniq(TUSpans.map(ts => ts.level || 0)),
      },
      {
        group: 'cycle',
        label: 'C',
        percent: 0.15,
        subgroups: uniq(CSpans.map(ts => ts.level || 0)),
      },
      {
        group: 'allocation',
        label: 'Al',
        percent: 0.4,
        subgroups: uniq(TASpans.map(ts => ts.level || 0)),
      },
    ];
  } else if (asset.type === 'Excavator' && isOpen) {
    return [
      {
        group: 'device-assignment',
        label: 'Op',
        percent: 0.3,
        subgroups: uniq(DASpans.map(ts => ts.level || 0)),
      },
      {
        group: 'dig-unit-activity',
        label: 'Mt',
        percent: 0.3,
        subgroups: uniq(DUASpans.map(ts => ts.level || 0)),
      },
      {
        group: 'allocation',
        label: 'Al',
        percent: 0.7,
        subgroups: uniq(TASpans.map(ts => ts.level || 0)),
      },
    ];
  }
  return [
    {
      group: 'device-assignment',
      label: 'Op',
      percent: 0.3,
      subgroups: uniq(DASpans.map(ts => ts.level || 0)),
    },
    {
      group: 'allocation',
      label: 'Al',
      percent: 0.7,
      subgroups: uniq(TASpans.map(ts => ts.level || 0)),
    },
  ];
}

function toShiftSpans(shifts, shiftTypes, timestamps) {
  const uniqTimestamps = uniq(timestamps.map(ts => ts.getTime()));

  const relevantShifts = uniqTimestamps
    .map(ts => shifts.find(s => s.startTime.getTime() <= ts && ts < s.endTime.getTime()))
    .filter(s => s);

  return toShiftTimeSpans(relevantShifts, shiftTypes);
}

function toLocalDigUnitActivities(digUnitActivities = []) {
  return chunkEvery(sortByTime(digUnitActivities, 'timestamp'), 2, 1).map(([cur, next]) => {
    const startTime = cur.timestamp;
    const endTime = (next || {}).timestamp;

    return {
      id: cur.id,
      assetId: cur.assetId,
      startTime: copyDate(startTime),
      endTime: copyDate(endTime),
      materialTypeId: cur.materialTypeId,
      locationId: cur.locationId,
      deleted: false,
    };
  });
}

export default {
  name: 'AssetTimeSpanInfo',
  components: {
    Icon,
    TimeSpanChart,
    DefaultTooltip,
    AllocationTooltip,
    LoginTooltip,
    MaterialTypeToolTip,
    TimeusageTooltip,
    CycleTooltip,
    ShiftTooltip,
  },
  props: {
    readonly: Boolean,
    showMaterialEditBtn: Boolean,
    asset: { type: Object, default: () => ({}) },
    timeAllocations: { type: Array, default: () => [] },
    digUnitActivities: { type: Array, default: () => [] },
    deviceAssignments: { type: Array, default: () => [] },
    cycles: { type: Array, default: () => [] },
    timeusage: { type: Array, default: () => [] },
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    fullTimeCodes: { type: Array, default: () => [] },
    materialTypes: { type: Array, default: () => [] },
    devices: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    activeEndTime: { type: Date, default: new Date() },
    range: { type: Object, default: null },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
    shifts: { type: Array, default: () => [] },
    shiftTypes: { type: Array, default: () => [] },
    shiftId: { type: Number, default: null },
    smoothAssignments: { type: Boolean, default: true },
  },
  data: () => {
    return {
      isOpen: false,
      editIcon: EditIcon,
      chevronRightIcon: ChevronRightIcon,
      margins: {
        focus: {
          top: 15,
          left: 25,
          right: 5,
          bottom: 30,
        },
        context: {
          top: 15,
          left: 25,
          right: 5,
          bottom: 30,
        },
      },
    };
  },
  computed: {
    contextHeight() {
      return this.isOpen ? 80 : 0;
    },
    assetIcon() {
      return this.$store.state.constants.icons[this.asset.type];
    },
    activeTimeAllocation() {
      return this.timeAllocations.find(ta => !ta.endTime) || {};
    },
    smoothDeviceAssignments() {
      const orderedDeviceAssignments = this.deviceAssignments
        .slice()
        .sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
      if (!this.smoothAssignments) {
        return orderedDeviceAssignments;
      }

      return dedupByMany(orderedDeviceAssignments, ['assetId', 'deviceId', 'operatorId']);
    },
    timeSpanColors() {
      return allocationColors();
    },
    iconClass() {
      const timeCodeId = this.activeTimeAllocation.timeCodeId;
      if (!timeCodeId) {
        return '';
      }

      const groupId = attributeFromList(this.timeCodes, 'id', timeCodeId, 'groupId');
      const groupName = attributeFromList(this.timeCodeGroups, 'id', groupId, 'name');

      if (groupName === 'Ready') {
        return 'ready';
      }

      return 'exception';
    },
    activeTimeAllocationTimeCode() {
      const timeCodeId = this.activeTimeAllocation.timeCodeId;
      return attributeFromList(this.timeCodes, 'id', timeCodeId, 'name');
    },
    activeTimeAllocationTimeDuration() {
      const alloc = this.activeTimeAllocation;
      const startTime = alloc.startTime;
      const endTime = alloc.endTime || this.activeEndTime;

      if (!startTime || !endTime) {
        return null;
      }

      return Math.trunc((endTime.getTime() - startTime.getTime()) / 1000);
    },
    filteredTimeAllocations() {
      if (!this.minDatetime) {
        return this.timeAllocations;
      }
      return this.timeAllocations.filter(ta => !ta.endTime || isInRange(ta, this.minDatetime));
    },
    timeSpans() {
      const activeEndTime = this.activeEndTime;
      const TASpans = toAllocationTimeSpans(
        this.filteredTimeAllocations,
        this.timeCodes,
        this.timeCodeGroups,
      ).map(ts => addActiveEndTime(ts, activeEndTime));

      const DUASpans = toDigUnitActivitySpans(
        toLocalDigUnitActivities(this.digUnitActivities),
        this.materialTypes,
      )
        .map(ts => addActiveEndTime(ts, activeEndTime))
        .filter(ts => isInRange(ts, this.minDatetime));

      const DASpans = toDeviceAssignmentSpans(
        this.smoothDeviceAssignments,
        this.devices,
        this.operators,
      )
        .map(ts => addActiveEndTime(ts, activeEndTime))
        .filter(ts => isInRange(ts, this.minDatetime));

      const TUSpans = toTimeusageTimeSpans(this.timeusage)
        .map(ts => addActiveEndTime(ts, activeEndTime))
        .filter(ts => isInRange(ts, this.minDatetime))
        .reverse();

      const CSpans = toCycleTimeSpans(this.cycles)
        .map(ts => addActiveEndTime(ts, activeEndTime))
        .filter(ts => isInRange(ts, this.minDatetime));

      const ShiftSpans = toShiftSpans(this.shifts, this.shiftTypes, [
        this.minDatetime,
        this.maxDatetime,
      ]);

      return [TASpans, DUASpans, DASpans, TUSpans, CSpans, ShiftSpans];
    },
    chartLayout() {
      const groups = getChartLayoutGroups(this.timeSpans, this.asset, this.isOpen);
      return {
        groups,
        padding: this.isOpen ? 5 : 2,
        yAxis: {
          show: this.isOpen,
          rotation: 0,
          yOffset: 0,
          xOffset: 0,
        },
      };
    },
    allowedTimeCodeIds() {
      return this.fullTimeCodes
        .filter(tc => tc.assetTypeIds.includes(this.asset.typeId))
        .map(tc => tc.id);
    },
  },
  methods: {
    onEdit() {
      const range = this.range || {};
      const minDatetime = this.minDatetime || range.min;
      const maxDatetime = this.maxDatetime || range.max;

      const opts = {
        asset: this.asset,
        allocations: this.filteredTimeAllocations,
        digUnitActivities: this.digUnitActivities,
        deviceAssignments: this.deviceAssignments,
        timeusage: this.timeusage,
        cycles: this.cycles,
        devices: this.devices,
        operators: this.operators,
        timeCodes: this.timeCodes,
        timeCodeGroups: this.timeCodeGroups,
        allowedTimeCodeIds: this.allowedTimeCodeIds,
        materialTypes: this.materialTypes,
        minDatetime,
        maxDatetime,
        timezone: this.timezone,
        shifts: this.shifts,
        shiftTypes: this.shiftTypes,
        shiftId: this.shiftId,
      };

      this.$modal.create(TimeSpanEditorModal, opts).onClose(resp => {
        if (['update', 'lock', 'unlock'].includes(resp)) {
          this.$emit(resp);
        }
      });
    },
    onEditMaterial() {
      const range = this.range || {};
      const minDatetime = this.minDatetime || range.min;
      const maxDatetime = this.maxDatetime || range.max;

      const opts = {
        asset: this.asset,
        allocations: this.filteredTimeAllocations,
        digUnitActivities: this.digUnitActivities,
        deviceAssignments: this.deviceAssignments,
        devices: this.devices,
        operators: this.operators,
        timeCodes: this.timeCodes,
        timeCodeGroups: this.timeCodeGroups,
        allowedTimeCodeIds: this.allowedTimeCodeIds,
        materialTypes: this.materialTypes,
        minDatetime,
        maxDatetime,
        timezone: this.timezone,
        shifts: this.shifts,
        shiftTypes: this.shiftTypes,
        shiftId: this.shiftId,
      };

      this.$modal.create(MaterialTypeEditorModal, opts).onClose(resp => {
        if (['update'].includes(resp)) {
          this.$emit(resp);
        }
      });
    },
    toggleOpen() {
      this.isOpen = !this.isOpen;
    },
    timeSpanStyler(timeSpan, region) {
      switch (timeSpan.group) {
        case 'allocation':
          return allocationStyle(timeSpan, region);

        case 'dig-unit-activity':
          return materialStyle(timeSpan, region, this.materialTypes);

        case 'device-assignment':
          return loginStyle(timeSpan, region);

        case 'timeusage':
          return timeusageStyle(timeSpan, region);

        case 'cycle':
          return cycleStyle(timeSpan, region);
        case 'shift':
          return shiftStyle(timeSpan, region);
      }
    },
    formatDuration(totalSeconds) {
      if (totalSeconds == null) {
        return '--';
      }

      if (totalSeconds < 0) {
        return '0:00';
      }

      if (totalSeconds > SECONDS_IN_DAY) {
        const days = Math.trunc(totalSeconds / SECONDS_IN_DAY);
        return days === 1 ? '> 1 day' : `> ${days} days`;
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
.asset-time-span-info {
  text-align: center;
  display: flex;
  width: 100%;
  border-bottom: 0.05rem solid #677e8c;
  margin: 2rem 0;
}

.asset-time-span-info .info {
  width: 12rem;
}

.asset-time-span-info .info .asset-name {
  font-size: 1.25rem;
  text-decoration: underline;
  padding-bottom: 0.5rem;
}

.asset-time-span-info .info .asset-icon {
  width: 100%;
  height: 3rem;
  margin-bottom: 0.25rem;
}

.asset-time-span-info .info .asset-icon.ready {
  stroke: green;
}

.asset-time-span-info .info .asset-icon.exception {
  stroke: orange;
}

.asset-time-span-info .chart-wrapper {
  transition: width 0.2s, height 0.2s;
  width: 100%;
  height: 120px;
  margin: 0 0.5rem;
}

.asset-time-span-info .chart-wrapper.open {
  height: 400px;
}

.asset-time-span-info .action-wrapper {
  margin: auto;
  width: 2rem;
  margin-right: 0.5rem;
}

.asset-time-span-info .edit-icon,
.asset-time-span-info .lock-icon,
.asset-time-span-info .unlock-icon,
.asset-time-span-info .chevron-icon {
  width: 1.25rem;
  cursor: pointer;
}

.__tooltip-boundary {
  margin: 10px;
}
</style>
