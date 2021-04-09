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
        <!-- List of time allocations here -->
      </div>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';

import ShiftSelector from '@/components/ShiftSelector.vue';
import SearchBar from '@/components/SearchBar.vue';

import ClockIcon from '@/components/icons/Time.vue';

export default {
  name: 'OperatorTimeAllocation',
  components: {
    hxCard,
    ShiftSelector,
    SearchBar,
  },
  data: () => {
    return {
      clockIcon: ClockIcon,
      maxShiftDatetime: new Date(),
      shiftSelectDisabled: false,
      shiftOperatorData: [],
      shift: null,
      search: '',
    };
  },
  computed: {
    ...mapState('constants', {
      shifts: state => state.shifts,
      shiftTypes: state => state.shiftTypes,
    }),
  },
  methods: {
    onShiftChange(shift) {
      this.shift = shift;
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

      this.$channel
        .push('get operator time allocation data', shift.id)
        .receive('ok', data => {
          this.shiftSelectDisabled = false;

          console.dir('---- got operator data');
          console.dir(data);
        })
        .receive('error', resp => {
          this.clearData();
          this.$toaster.error(resp.error);
        })
        .receive('timeout', () => this.$toaster.noComms('Unable to fetch data'));
    },
    clearData() {
      this.shiftSelectDisabled = false;
      this.shiftOperatorData = [];
    },
  },
};
</script>

<style>
</style>