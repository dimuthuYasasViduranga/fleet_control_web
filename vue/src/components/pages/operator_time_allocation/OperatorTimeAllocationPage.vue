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

      <div class="search-bar-wrapper">
        <SearchBar placeholder="Search operator name" v-model="search" :showClear="true" />
      </div>
      <div class="blank-toggle">
        <input
          type="checkbox"
          :checked="hideBlankOperators"
          @change="onToggleHideBlankOperators()"
        />
        <span @click="onToggleHideBlankOperators()">Hide Blank Operators</span>
      </div>

      <Loading v-if="!!shiftInTransit" :isLoading="true" />
      <template v-else>
        <div v-if="filteredOperatorData.length" class="time-allocations">
          <OperatorTimeSpanInfo
            v-for="operator in filteredOperatorData"
            :key="operator.id"
            :operatorId="operator.id"
            :operatorName="operator.name"
            :assets="assets"
            :allocations="operator.allocations"
            :rangeStart="operator.rangeStart"
            :rangeEnd="operator.rangeEnd"
          />
        </div>
        <div v-else class="no-allocations">No Data to Show</div>
      </template>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import Loading from 'hx-layout/Loading.vue';

import ShiftSelector from '@/components/ShiftSelector.vue';
import SearchBar from '@/components/SearchBar.vue';
import OperatorTimeSpanInfo from './OperatorTimeSpanInfo.vue';

import ClockIcon from '@/components/icons/Time.vue';
import { parseAsset, parseOperator } from '@/store/modules/constants';
import { toUtcDate } from '@/code/time';
import { attributeFromList, groupBy, isInText } from '@/code/helpers';

import fuzzysort from 'fuzzysort';

function parseOperatorData(data) {
  const assets = data.assets.map(parseAsset);
  const operators = data.operators.map(parseOperator);
  const rangeStart = toUtcDate(data.start_time);
  const rangeEnd = toUtcDate(data.end_time);
  const allocations = data.operator_allocations.map(alloc => {
    return parseOperatorAllocation(alloc, assets, operators);
  });

  return {
    rangeStart,
    rangeEnd,
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
    Loading,
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
      hideBlankOperators: true,
    };
  },
  computed: {
    ...mapState('constants', {
      shifts: state => state.shifts,
      shiftTypes: state => state.shiftTypes,
      assets: state => state.assets,
    }),
    filteredOperatorData() {
      if (!this.shiftOperatorData) {
        return [];
      }

      const lookup = groupBy(this.shiftOperatorData.allocations, 'operatorId');

      let operatorData = this.shiftOperatorData.operators
        .map(operator => {
          const allocs = lookup[operator.id] || [];

          return {
            id: operator.id,
            name: operator.fullname || '',
            rangeStart: this.shiftOperatorData.rangeStart,
            rangeEnd: this.shiftOperatorData.rangeEnd,
            allocations: allocs,
          };
        })
        .sort((a, b) => a.name.localeCompare(b.name));

      if (this.hideBlankOperators) {
        operatorData = operatorData.filter(o => o.allocations.length);
      }

      if (this.search) {
        operatorData = fuzzysort.go(this.search, operatorData, { key: 'name' }).map(r => r.obj);
      }

      return operatorData;
    },
  },
  methods: {
    onShiftChange(shift) {
      this.shift = shift;
      this.fetchAllocationsByShift(shift);
    },
    onToggleHideBlankOperators() {
      this.hideBlankOperators = !this.hideBlankOperators;
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

      if (this.shiftInTransit) {
        return;
      }

      this.shiftInTransit = shift.id;

      this.$channel
        .push('get operator time allocation data', shift.id)
        .receive('ok', data => {
          this.shiftSelectDisabled = false;

          if (this.shiftInTransit === data.shift.id) {
            this.clearData();
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
.operator-time-allocation-page .loading-wrapper {
  display: flex;
  align-items: center;
}

.operator-time-allocation-page .loading-wrapper svg {
  margin: auto;
  display: block;
  min-height: 15rem;
}

.operator-time-allocation-page .blank-toggle {
  padding: 0.5rem 0;
}

.operator-time-allocation-page .blank-toggle input,
.operator-time-allocation-page .blank-toggle span {
  cursor: pointer;
}

.operator-time-allocation-page .search-bar-wrapper {
  max-width: 24rem;
  margin: 0.5rem 0;
  height: 1.6rem;
}

.operator-time-allocation-page .no-allocations {
  color: gray;
  font-size: 1.5rem;
  font-style: italic;
  width: 100%;
  height: 200px;
  padding-top: 90px;
  text-align: center;
}
</style>