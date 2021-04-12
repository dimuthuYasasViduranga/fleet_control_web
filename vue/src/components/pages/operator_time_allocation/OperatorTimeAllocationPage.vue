<template>
  <div class="operator-time-allocation-page">
    <hxCard title="Operator Time Allocation" :icon="clockIcon">
      <ShiftSelector
        :value="shift"
        :shifts="shifts"
        :shiftTypes="shiftTypes"
        :disabled="shiftSelectDisabled"
        :maxDatetime="maxShiftDatetime"
        @change="onShiftChange"
        @refresh="onRefresh"
      />

      <div class="options">
        <!-- Show all operators, only show operators with data, etc -->
      </div>

      <div class="search-bar-wrapper">
        <SearchBar placeholder="Search operator name" v-model="search" :showClear="true" />
      </div>

      <div class="time-allocations">
        <OperatorTimeSpanInfo
          v-for="operator in filteredOperatorData"
          :key="operator.id"
          :operatorId="operator.id"
          :operatorName="operator.name"
          :allocations="operator.allocations"
          :rangeStart="operator.rangeStart"
          :rangeEnd="operator.rangeEnd"
        />
      </div>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';

import ShiftSelector from '@/components/ShiftSelector.vue';
import SearchBar from '@/components/SearchBar.vue';
import OperatorTimeSpanInfo from './OperatorTimeSpanInfo.vue';

import ClockIcon from '@/components/icons/Time.vue';
import { parseAsset, parseOperator } from '@/store/modules/constants';
import { toUtcDate } from '@/code/time';
import { attributeFromList, groupBy } from '@/code/helpers';

function parseOperatorData(data) {
  const assets = data.assets.map(parseAsset);
  const operators = data.operators.map(parseOperator);
  const startTime = toUtcDate(data.start_time);
  const endTime = toUtcDate(data.end_time);
  const allocations = data.operator_allocations.map(alloc => {
    return parseOperatorAllocation(alloc, assets, operators);
  });

  return {
    startTime,
    endTime,
    assets,
    operators,
    allocations,
  };
}

function parseOperatorAllocation(alloc, assets, operators) {
  const [assetName, assetType] = attributeFromList(assets, 'id', alloc.asset_id, ['name', 'type']);
  const operatorName = attributeFromList(operators, 'id', alloc.operator_id, 'fullname');

  return {
    operatorId: alloc.operator_id,
    operatorName,
    assetId: alloc.asset_id,
    assetName,
    assetType,
    startTime: toUtcDate(alloc.start_time),
    endTime: toUtcDate(alloc.end_time),
    timeCodeId: alloc.time_code_id,
    timeCode: alloc.time_code,
    timeCodeGroup: alloc.time_code_group,
  };
}

export default {
  name: 'OperatorTimeAllocation',
  components: {
    hxCard,
    ShiftSelector,
    SearchBar,
    OperatorTimeSpanInfo,
  },
  data: () => {
    return {
      clockIcon: ClockIcon,
      maxShiftDatetime: new Date(),
      shiftSelectDisabled: false,
      shiftOperatorData: null,
      shift: null,
      shiftInTransit: null,
      search: '',
    };
  },
  computed: {
    ...mapState('constants', {
      shifts: state => state.shifts,
      shiftTypes: state => state.shiftTypes,
    }),
    filteredOperatorData() {
      if (!this.shiftOperatorData) {
        return [];
      }
      // this needs to be left join operator list so that blanks show up

      const lookup = groupBy(this.shiftOperatorData.allocations, 'operatorId');

      return Object.values(lookup)
        .map(allocs => {
          const first = allocs[0];

          return {
            id: first.operatorId,
            name: first.operatorName || '',
            rangeStart: this.shiftOperatorData.rangeStart,
            rangeEnd: this.shiftOperatorData.rangeEnd,
            allocations: allocs,
          };
        })
        .sort((a, b) => a.name.localeCompare(b.name));
    },
  },
  methods: {
    onShiftChange(shift) {
      this.shift = shift;

      if (this.shiftInTransit !== shift.id) {
        this.clearData();
      }

      this.fetchAllocationsByShift(shift);
    },
    onRefresh() {
      this.maxShiftDatetime = new Date();
      this.fetchAllocationsByShift(this.shift);
    },
    fetchAllocationsByShift(shift) {
      this.shiftSelectDisabled = true;

      if (!shift) {
        this.shiftSelectDisabled = false;
        return;
      }

      this.shiftInTransit = shift.id;

      this.$channel
        .push('get operator time allocation data', shift.id)
        .receive('ok', data => {
          this.shiftSelectDisabled = false;

          if (this.shiftInTransit === shift.id) {
            this.shiftOperatorData = parseOperatorData(data.data);
          } else {
            console.error(
              `[OperatorAlloc] Got different report. Expected shift ${this.shiftInTransit}`,
            );
          }
        })
        .receive('error', resp => {
          this.clearData();
          this.$toaster.error(resp.error);
        })
        .receive('timeout', () => {
          this.clearData();
          this.$toaster.noComms('Unable to fetch data');
        });
    },
    clearData() {
      this.shiftSelectDisabled = false;
      this.shiftOperatorData = null;
      this.shiftInTransit = null;
    },
  },
};
</script>

<style>
</style>