<template>
  <div class="time-allocation-report-page">
    <hxCard title="Time Allocation Report" :icon="reportIcon">
      <div class="shift-selector-wrapper">
        <ShiftSelector
          :value="shift"
          :shifts="shifts"
          :shiftTypes="shiftTypes"
          :disabled="!!reportInTransit"
          :maxDatetime="maxReportDate"
          @change="onShiftChange"
          @refresh="onFetchReport(shift)"
        />
      </div>
      <div class="asset-type-selector">
        <button
          class="hx-btn"
          v-for="(assetType, index) in selectedAssetTypes"
          :key="index"
          :class="{ 'not-selected': !assetType.selected }"
          @click="assetType.selected = !assetType.selected"
        >
          {{ assetType.type }}
        </button>

        <button
          class="hx-btn"
          :class="{ selected: selectedAssetTypes.every(assetType => assetType.selected) }"
          @click="setAssetTypeSelection"
        >
          All
        </button>

        <button class="hx-btn" @click="clearAssetTypeSelection">clear</button>
      </div>

      <div class="search-bar-wrapper">
        <SearchBar placeholder="Search asset name" v-model="search" :showClear="true" />
      </div>
      <div class="reports">
        <Loading :isLoading="!!reportInTransit" />

        <AssetReport
          v-for="{ asset, allocations, assignments, events, totalEngineHours } in filteredReports"
          :key="asset.name"
          :asset="asset"
          :shift="shift"
          :allocations="allocations"
          :assignments="assignments"
          :events="events"
          :totalEngineHours="totalEngineHours"
          :timeCodes="timeCodes"
          :timeCodeGroups="timeCodeGroups"
          :operators="operators"
          :devices="devices"
          :locations="locations"
          :timezone="timezone"
          :fullTimeCodes="fullTimeCodes"
          @update="onFetchReport(shift)"
        />
      </div>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';

import Loading from 'hx-layout/Loading.vue';
import hxCard from 'hx-layout/Card.vue';
import ShiftSelector from '../../ShiftSelector.vue';
import SearchBar from '../../SearchBar.vue';
import AssetReport from './AssetReport.vue';

import ReportIcon from '../../icons/Report.vue';
import { parseTimeAllocation } from '../../../store/store';
import { parseAsset } from '../../../store/modules/constants';
import { toUtcDate } from '../../../code/time';
import { isInText, attributeFromList } from '../../../code/helpers';

function parseReport(report, operators) {
  const now = new Date();
  const allocations = parseAllocations(report.allocations, operators);
  const asset = parseAsset(report.asset);
  const events = report.events.map(e => parseEvent(e, operators));
  const assignments = report.assignments.map(a => parseAssigment(a, operators, now));

  return {
    asset,
    reportStartTime: toUtcDate(report.report_start),
    reportEndTime: toUtcDate(report.report_end),
    allocations,
    assignments,
    events,
    totalEngineHours: report.total_engine_hours || 0,
  };
}

function parseAllocations(allocations, operators) {
  return allocations.map(a => {
    const alloc = parseTimeAllocation(a);
    alloc.operators = getOperatorsFromIds(operators, a.operator_ids);
    return alloc;
  });
}

function parseEvent(event, operators) {
  return {
    event: event.event,
    startTime: toUtcDate(event.start_time),
    endTime: toUtcDate(event.end_time),
    spans: event.spans,
    compliance: event.compliance,
    operators: getOperatorsFromIds(operators, event.operator_ids),
    details: event.details,
  };
}

function parseAssigment(assignment, operators, now) {
  const timestamp = now.getTime();
  const startTime = toUtcDate(assignment.start_time);
  let endTime = toUtcDate(assignment.end_time);

  if (endTime === null || endTime.getTime() > timestamp) {
    endTime = now;
  }

  const duration = Math.trunc((endTime.getTime() - startTime.getTime()) / 1000);

  return {
    operatorId: assignment.operator_id,
    startTime,
    endTime,
    duration,
    operatorId: assignment.operator_id,
    operator: attributeFromList(operators, 'id', assignment.operator_id, 'fullname'),
  };
}

function getOperatorsFromIds(operators, ids) {
  return operators.filter(o => ids.includes(o.id));
}

export default {
  name: 'TimeAllocationReport',
  components: {
    hxCard,
    Loading,
    ShiftSelector,
    SearchBar,
    AssetReport,
  },
  data: () => {
    return {
      reportIcon: ReportIcon,
      shift: null,
      search: '',
      reportInTransit: null,
      maxReportDate: new Date(),
      reports: [],
      selectedAssetTypes: [],
    };
  },
  computed: {
    ...mapState('constants', {
      shifts: state => state.shifts,
      shiftTypes: state => state.shiftTypes,
      timeCodes: state => state.timeCodes,
      timeCodeGroups: state => state.timeCodeGroups,
      assetTypes: state => state.assetTypes,
      operators: state => state.operators,
      devices: state => state.devices,
      locations: state => state.locations,
    }),
    timezone() {
      return this.$timely.current.timezone;
    },
    filteredReports() {
      const selectedAssetTypes = this.selectedAssetTypes.filter(t => t.selected).map(t => t.type);
      return this.reports.filter(
        report =>
          selectedAssetTypes.includes(report.asset.type) &&
          isInText(report.asset.name, this.search),
      );
    },
    fullTimeCodes() {
      return this.$store.getters['constants/fullTimeCodes'];
    },
  },
  watch: {
    assetTypes: {
      immediate: true,
      handler(types = []) {
        const assetTypes = types.map(({ type }) => {
          return {
            type,
            selected: type === 'Haul Truck',
          };
        });
        this.selectedAssetTypes = assetTypes;
      },
    },
  },
  methods: {
    clearAssetTypeSelection() {
      this.selectedAssetTypes.forEach(t => (t.selected = false));
    },
    setAssetTypeSelection() {
      this.selectedAssetTypes.forEach(t => (t.selected = true));
    },
    onShiftChange(shift) {
      this.shift = shift;

      if (this.reportInTransit !== shift.id) {
        this.reports = [];
        this.reportInTransit = null;
      }

      this.onFetchReport(shift);
    },
    onFetchReport(shift) {
      if (this.reportInTransit) {
        return;
      }
      if (!shift) {
        console.error('[TimeAllocReport] Cannot create report without a shift');
        return;
      }
      this.reports = [];
      this.reportInTransit = shift.id;

      this.$channel
        .push('report:time allocation', shift.id)
        .receive('ok', data => {
          const reports = (data.reports || []).map(r => parseReport(r, this.operators));
          reports.sort((a, b) => a.asset.name.localeCompare(b.asset.name));
          if (this.reportInTransit === this.shift.id) {
            this.reports = reports;
          } else {
            console.error(
              `[TimeAllocReport] Got different report. Expected shift ${this.reportInTransit}`,
            );
          }
          this.reportInTransit = null;
        })
        .receive('error', resp => {
          this.reportInTransit = null;
          this.$toasted.global.error(resp.error);
        })
        .receive('timeout', () => {
          this.reportInTransit = null;
          this.$toasted.global.noComms('Unable to fetch report');
        });
    },
  },
};
</script>

<style>
@import '../../../assets/hxInput.css';

.time-allocation-report-page .shift-selector-wrapper {
  margin-left: 0.5rem;
}

.time-allocation-report-page .generate-btn {
  margin-top: 1rem;
  margin-bottom: 1rem;
}

.time-allocation-report-page .asset-type-selector {
  width: 100%;
  display: flex;
  flex-wrap: wrap;
}

.time-allocation-report-page .asset-type-selector .hx-btn {
  margin: 0.05rem 0;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
}

.time-allocation-report-page .asset-type-selector .hx-btn.not-selected {
  opacity: 0.5;
}

.time-allocation-report-page .search-bar-wrapper {
  max-width: 12rem;
  margin: 0.5rem 0;
  height: 1.6rem;
}

.time-allocation-report-page .loading-wrapper {
  display: flex;
  align-items: center;
}

.time-allocation-report-page .loading-wrapper svg {
  margin: auto;
  display: block;
  min-height: 60vh;
}
</style>