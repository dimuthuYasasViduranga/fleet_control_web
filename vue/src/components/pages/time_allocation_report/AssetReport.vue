<template>
  <div class="asset-report">
    <TimeSpanEditor
      v-if="timeAllocationData"
      :show="true"
      :asset="asset"
      :timeAllocations="timeAllocationData.allocations"
      :deviceAssignments="timeAllocationData.deviceAssignments"
      :timeusage="timeAllocationData.timeusage"
      :cycles="timeAllocationData.cycles"
      :devices="devices"
      :operators="operators"
      :timeCodes="timeCodes"
      :timeCodeGroups="timeCodeGroups"
      :allowedTimeCodeIds="allowedTimeCodeIds"
      :locations="locations"
      :activeEndTime="activeEndTime"
      :minDatetime="timeAllocationData.shift.startTime"
      :maxDatetime="timeAllocationData.shift.endTime"
      :timezone="timezone"
      :shiftId="timeAllocationData.shift.id"
      @close="timeAllocationData = null"
      @update="onUpdate()"
    />
    <hxCard :title="`${asset.name} |`" :icon="icon" :class="[titleClass, show ? 'open' : 'closed']">
      <div class="title-post" slot="title-post">
        <div class="smu">SMU: {{ formatHours(totalEngineHours) }}</div>
        <div class="distribution">
          <span class="compiant gap-left" :class="{ dim: eventSummary.compliant === 0 }">
            Compliant: {{ eventSummary.compliant }}
          </span>
          <span class="warn gap-left" :class="{ dim: eventSummary.warn === 0 }">
            Warn: {{ eventSummary.warn }}
          </span>
          <span class="issues gap-left" :class="{ dim: eventSummary.issues === 0 }">
            Issues: {{ eventSummary.issues }}
          </span>
        </div>
        <Icon
          class="chevron-icon gap-left"
          :icon="chevronIcon"
          :rotation="show ? 270 : 90"
          @click="toggleShow"
        />
        <Icon v-tooltip="'Edit'" class="edit-icon" :icon="editIcon" @click="onEditAllocations()" />
      </div>
      <div class="report-body" v-if="show">
        <hxCard title="Operator Breakdown" class="operators">
          <table-component
            table-wrapper="#content"
            table-class="table"
            filterNoResults="No Operator Information"
            :data="assignmentSummary"
            :show-caption="false"
            :show-filter="false"
            sort-by="startTime"
            sort-order="asc"
          >
            <table-column cell-class="table-cel" label="Operator" show="name" />

            <table-column
              cell-class="table-cel"
              label="Duration"
              show="duration"
              :formatter="formatDuration"
            />
          </table-component>
        </hxCard>

        <hxCard title="Time Allocations" class="time-allocations">
          <table-component
            table-wrapper="#content"
            table-class="table"
            filterNoResults="No Time Allocations"
            :data="formattedAllocations"
            :show-caption="false"
            :show-filter="false"
            sort-by="startTime"
            sort-order="asc"
          >
            <table-column cell-class="table-cel" label="Time Code" show="timeCode" />
            <table-column
              cell-class="table-cel"
              label="Start"
              show="startTime"
              :formatter="formatDate"
            />
            <table-column
              cell-class="table-cel"
              label="End"
              show="endTime"
              :formatter="formatDate"
            />
            <table-column
              cell-class="table-cel"
              label="Duration"
              show="duration"
              :formatter="formatDuration"
            />

            <table-column
              cell-class="table-cel"
              label="Operator"
              show="operators"
              :formatter="formatOperators"
            />
          </table-component>
        </hxCard>
        <hxCard title="Events" class="events">
          <div class="filters" v-if="events.length !== 0">
            <button
              class="hx-btn"
              v-for="condition in ['compliant', 'warn', 'issues']"
              :key="condition"
              :class="{ selected: !filters[condition] }"
              @click="toggleFilter(condition)"
            >
              {{ condition }}
            </button>
          </div>
          <table-component
            table-wrapper="#content"
            table-class="table"
            filterNoResults="No Events"
            :data="filteredEvents"
            :show-caption="false"
            :show-filter="false"
            sort-by="startTime"
            sort-order="asc"
          >
            <table-column cell-class="table-cel" label="Event" show="event" />
            <table-column
              cell-class="table-cel"
              label="Start"
              show="startTime"
              :formatter="formatDate"
            />
            <table-column
              cell-class="table-cel"
              label="End"
              show="endTime"
              :formatter="formatDate"
            />
            <table-column
              cell-class="table-cel"
              label="Duration"
              show="duration"
              :formatter="formatDuration"
            />
            <table-column
              cell-class="table-cel"
              label="Compliance"
              show="compliance"
              :formatter="compliancePercent"
            />

            <table-column
              cell-class="table-cel"
              label="Operator"
              show="operators"
              :formatter="formatOperators"
            />

            <table-column cell-class="table-cel" label="Info" show="info" />
          </table-component>
        </hxCard>
      </div>
    </hxCard>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';

import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import TimeSpanEditor from '../time_allocation/TimeSpanEditor.vue';
import LoadingModal from '@/components/modals/LoadingModal.vue';

import { attributeFromList, groupBy } from '../../../code/helpers';
import { formatDateIn, formatSeconds, divMod } from '../../../code/time';
import { parseCycle, parseTimeAllocation, parseTimeusage } from '@/store/store';
import { parseDeviceAssignment } from '@/store/modules/device_store';

import ChevronIcon from '../../icons/ChevronRight.vue';
import EditIcon from '../../icons/Edit.vue';

const EVENTS = {
  STATIC: 'Exception at static geofence',
  'CYCLE-VALID-TASK': 'Cycle with valid task',
};

const COLORS = {
  compliant: 'green',
  warn: 'orange',
  issues: 'red',
};

const SECONDS_IN_DAY = 3600 * 24;

function getComplianceLevel(compliance) {
  if (compliance > 0.9) {
    return 'compliant';
  }
  if (compliance > 0.6) {
    return 'warn';
  }
  return 'issues';
}

function getInfo(event, level) {
  if (event.event === EVENTS.STATIC && level !== 'compliant') {
    return `Missing exception at '${event.details.location}'`;
  }

  if (event.event === EVENTS['CYCLE-VALID-TASK'] && level !== 'compliant') {
    return level === 'warn' ? 'Has partial valid task' : 'Missing valid task';
  }

  return '';
}

function parseData(data, key, assetId, parser) {
  return (data[key] || []).filter(d => d.asset_id === assetId).map(parser);
}

export default {
  name: 'AssetReport',
  components: {
    Icon,
    hxCard,
    TableComponent,
    TableColumn,
    TimeSpanEditor,
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    shift: { type: Object, default: null },
    allocations: { type: Array, default: () => [] },
    totalEngineHours: { type: Number, default: 0 },
    assignments: { type: Array, default: () => [] },
    events: { type: Array, default: () => [] },
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    timezone: { type: String, default: 'local' },
    operators: { type: Array, default: () => [] },
    devices: { type: Array, default: () => [] },
    activeEndTime: { type: Date, default: () => new Date() },
    fullTimeCodes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      chevronIcon: ChevronIcon,
      editIcon: EditIcon,
      show: false,
      filters: {
        compliant: true,
        warn: true,
        issues: true,
      },
      timeAllocationData: null,
    };
  },
  computed: {
    icon() {
      return this.$store.state.constants.icons[this.asset.type];
    },
    titleClass() {
      const summary = this.eventSummary;
      if (summary.issues > 0) {
        return 'issues';
      }

      if (summary.warn > 0) {
        return 'warn';
      }

      return 'compliant';
    },
    formattedAllocations() {
      return this.allocations.map(alloc => {
        const endTime = alloc.endTime || this.activeEndTime;
        const duration = Math.trunc((endTime.getTime() - alloc.startTime.getTime()) / 1000);
        const [timeCode, timeCodeGroupId] = attributeFromList(
          this.timeCodes,
          'id',
          alloc.timeCodeId,
          ['name', 'groupId'],
        );
        const timeCodeGroup = attributeFromList(this.timeCodeGroups, 'id', timeCodeGroupId, 'name');

        return {
          startTime: alloc.startTime.getTime(),
          endTime: endTime.getTime(),
          operators: alloc.operators,
          duration,
          timeCode,
          timeCodeGroup,
        };
      });
    },
    formattedEvents() {
      return this.events.map(event => {
        const duration = Math.trunc((event.endTime.getTime() - event.startTime.getTime()) / 1000);
        const level = getComplianceLevel(event.compliance);
        const info = getInfo(event, level);
        return {
          event: event.event,
          startTime: event.startTime.getTime(),
          endTime: event.endTime.getTime(),
          duration,
          compliance: event.compliance,
          level,
          info,
          spans: event.spans.slice(),
        };
      });
    },
    filteredEvents() {
      return this.formattedEvents.filter(event => this.filters[event.level]);
    },
    eventSummary() {
      const distribution = groupBy(this.formattedEvents, 'level');

      Object.keys(distribution).map(key => (distribution[key] = distribution[key].length));
      return {
        compliant: distribution.compliant || 0,
        warn: distribution.warn || 0,
        issues: distribution.issues || 0,
      };
    },
    assignmentSummary() {
      const groups = this.assignments.reduce((acc, assignment) => {
        const name = assignment.operator || 'No Operator';
        acc[name] = acc[name] || 0 + assignment.duration;
        return acc;
      }, {});
      return Object.entries(groups).map(([name, duration]) => {
        return { name, duration };
      });
    },
    allowedTimeCodeIds() {
      return this.fullTimeCodes
        .filter(tc => tc.assetTypeIds.includes(this.asset.typeId))
        .map(tc => tc.id);
    },
  },
  methods: {
    toggleShow() {
      this.show = !this.show;
    },
    toggleFilter(filter) {
      this.filters[filter] = !this.filters[filter];
    },
    formatDate(epoch) {
      return formatDateIn(new Date(epoch));
    },
    formatDuration(seconds) {
      const [days, remainder] = divMod(seconds, SECONDS_IN_DAY);

      let daysStr = '';
      if (days > 0) {
        daysStr = days === 1 ? '1 day ' : `${days} days `;
      }
      return `${daysStr}${formatSeconds(remainder)}`;
    },
    formatHours(hours) {
      if (!hours) {
        return '--';
      }
      return hours.toFixed(1);
    },
    formatOperators(operators) {
      const names = (operators || []).map(o => o.fullname);

      if (names.length === 0) {
        return '--';
      }

      return names.join(', ');
    },
    compliancePercent(compliance, row) {
      const color = COLORS[row.level];
      const percent = compliance * 100;
      return `<span style="color: ${color}">${percent.toFixed(1)}%</span>`;
    },
    onEditAllocations() {
      const shift = this.shift;
      if (!shift) {
        this.$toasted.global.error('No shift available for editing');
        return;
      }

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'Fetching time allocations' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('get time allocation data', shift.id)
        .receive('ok', data => {
          loading.close();
          if (data.shift.id !== shift.id) {
            console.error('[Asset Report] received wrong shift');
            return;
          }

          const assetId = this.asset.id;
          this.timeAllocationData = {
            shift,
            allocations: parseData(data, 'allocations', assetId, parseTimeAllocation),
            deviceAssignments: parseData(
              data,
              'device_assignments',
              assetId,
              parseDeviceAssignment,
            ),
            timeusage: parseData(data, 'timeusage', assetId, parseTimeusage),
            cycles: parseData(data, 'cycles', assetId, parseCycle),
          };
        })
        .receive('error', resp => {
          loading.close();
          this.$toasted.global.error(resp.error);
        })
        .receive('timeout', () => {
          loading.close();
          this.$toasted.global.noComms('Unable to load time allocations');
        });
    },
    onUpdate() {
      this.$emit('update');
    },
  },
};
</script>

<style>
@import '../../../assets/hxInput.css';

/* hxCard styling */
.asset-report .hxCardIcon {
  height: 2.5rem;
}

.asset-report .hxCard {
  border-left: 2px solid transparent;
}

.asset-report .hxCard.open {
  border: 2px solid #364c59;
}

.asset-report .compliant .hxCardIcon {
  stroke: green;
}

.asset-report .warn .hxCardIcon {
  stroke: orange;
}

.asset-report .issues .hxCardIcon {
  stroke: red;
}

.asset-report .title-post {
  text-transform: capitalize;
  display: flex;
  flex-direction: row;
  margin-left: 1rem;
}

/* other styling */

.asset-report .chevron-icon,
.asset-report .edit-icon {
  margin-right: 0.25rem;
  height: 1rem;
  width: 1.25rem;
  cursor: pointer;
}

.asset-report .gap-left {
  margin-left: 1rem;
}

.asset-report .dim {
  opacity: 0.5;
}

.asset-report .title-post .distribution {
  display: flex;
}

.asset-report .heading {
  display: flex;
  height: 2rem;
}

.asset-report .heading .text {
  line-height: 2rem;
}

.asset-report .filters .hx-btn {
  margin-left: 0.25rem;
  text-transform: capitalize;
}

.asset-report .filters .hx-btn.selected {
  opacity: 0.5;
}
</style>