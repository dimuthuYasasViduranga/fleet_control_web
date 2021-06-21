<template>
  <div class="cycle-tally-page">
    <CycleEditModal
      :show="!!cycleToEdit"
      :shift="mode === 'live' ? null : shift"
      :cycle="cycleToEdit"
      @close="onEditModalClose"
    />

    <hxCard title="Cycle Tally" :icon="listIcon">
      <div class="time-mode-selector">
        <button
          class="hx-btn live"
          :class="{ selected: mode === 'live' }"
          @click="setTimeMode('live')"
        >
          Live
        </button>
        <button
          class="hx-btn shift"
          :class="{ selected: mode === 'shift' }"
          @click="setTimeMode('shift')"
        >
          Shift
        </button>
      </div>
      <ShiftSelector
        v-show="mode === 'shift'"
        :value="shift"
        :shifts="shifts"
        :shiftTypes="shiftTypes"
        :disabled="fetchingData"
        @change="onShiftChange"
        @refresh="onRefresh"
      />
      <button v-if="showAddButton" class="hx-btn" @click="onAddCycle">Add Cycle</button>
      <div class="search-bar-wrapper">
        <SearchBar placeholder="Search asset name" v-model="search" :showClear="true" />
      </div>
      <CycleTallyReport
        v-for="{ asset, cycles } in filteredCyclesByAsset"
        :key="asset.id"
        :asset="asset"
        :cycles="cycles"
        :assets="assets"
        :operators="operators"
        :locations="locations"
        :materialTypes="materialTypes"
        :engineHours="engineHours"
        @edit="onEditCycle"
        @delete="onDeleteCycle"
        @copy="onCopyCycle"
      />
    </hxCard>
  </div>
</template> 
 
<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import ListIcon from '../../icons/List.vue';
import CycleTallyReport from './CycleTallyReport.vue';
import SearchBar from '../../SearchBar.vue';
import CycleEditModal from './CycleEditModal.vue';
import ShiftSelector from '../../ShiftSelector.vue';

import ConfirmModal from '../../modals/ConfirmModal.vue';

import { groupBy, attributeFromList, isInText } from '../../../code/helpers';
import { parseManualCycle } from '../../../store/modules/haul_truck';
import { parseEngineHour } from '../../../store/store';
import { copyDate } from '../../../code/time';

const CONFIRM_MESSAGE = `Are you sure you want to delete this cycle?`;

export default {
  name: 'CycleTally',
  components: {
    hxCard,
    CycleTallyReport,
    SearchBar,
    CycleEditModal,
    ShiftSelector,
  },
  data: () => {
    return {
      listIcon: ListIcon,
      search: '',
      cycleToEdit: null,
      confirmMessage: CONFIRM_MESSAGE,
      okName: 'ok',
      cancelName: 'No',
      shift: null,
      fetchingData: false,
      mode: 'live',
      shiftCycles: [],
      shiftEngineHours: [],
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
      materialTypes: state => state.materialTypes,
      locations: state => state.locations,
      shifts: state => state.shifts,
      shiftTypes: state => state.shiftTypes,
    }),
    ...mapState('haulTruck', {
      manualCycles: state => state.manualCycles,
    }),
    liveCycles() {
      if (this.shift) {
        const startTime = this.shift.startTime.getTime();
        return this.manualCycles.filter(c => c.startTime.getTime() > startTime);
      }
      return this.manualCycles;
    },
    liveEngineHours() {
      return this.$store.state.historicEngineHours;
    },
    engineHours() {
      return this.mode === 'live' ? this.liveEngineHours : this.shiftEngineHours;
    },
    cyclesByAsset() {
      const cycles = this.mode === 'live' ? this.liveCycles : this.shiftCycles;

      const groupMap = groupBy(cycles, 'assetId');

      return Object.keys(groupMap).map(assetId => {
        const asset = attributeFromList(this.assets, 'id', parseInt(assetId, 10));
        return {
          asset,
          cycles: groupMap[assetId],
        };
      });
    },
    filteredCyclesByAsset() {
      return this.cyclesByAsset.filter(c => isInText(c.asset.name, this.search));
    },
    showAddButton() {
      const shift = this.shift;
      if (!shift) {
        return true;
      }

      return shift.startTime.getTime() <= this.$everySecond.timestamp;
    },
  },
  methods: {
    onShiftChange(shift) {
      this.shift = shift;
      this.fetchCyclesByShift(shift);
    },
    onRefresh() {
      if (this.mode === 'shift') {
        this.fetchCyclesByShift(this.shift);
      }
    },
    setTimeMode(mode) {
      this.mode = mode;
    },
    onEditModalClose() {
      this.cycleToEdit = null;
      this.onRefresh();
    },
    onAddCycle() {
      this.cycleToEdit = {};
    },
    onEditCycle(cycle) {
      this.cycleToEdit = cycle;
    },
    onDeleteCycle(cycle) {
      this.$modal
        .create(ConfirmModal, {
          title: 'Delete Cycle',
          body: CONFIRM_MESSAGE,
          ok: 'Yes',
          cancel: 'No',
        })
        .onClose(answer => {
          if (answer === 'Yes') {
            this.deleteCycle(cycle);
          }
        });
    },
    onCopyCycle(cycle) {
      const freshCycle = {
        ...cycle,
        startTime: copyDate(cycle.startTime),
        endTime: copyDate(cycle.endTime),
      };
      delete freshCycle.id;
      delete freshCycle.timestamp;

      this.cycleToEdit = freshCycle;
    },
    deleteCycle(cycle) {
      const prevState = cycle.deleted;
      cycle.deleted = true;

      this.$channel
        .push('haul:delete manual cycle', cycle.id)
        .receive('ok', () => this.onRefresh())
        .receive('error', resp => {
          cycle.deleted = prevState;
        })
        .receive('timeout', resp => {
          cycle.deleted = prevState;
        });
    },
    fetchCyclesByShift(shift) {
      if (!shift) {
        this.fetchingData = false;
        return;
      }

      this.fetchingData = true;

      const onError = () => {
        this.shiftData = [];
        this.fetchingData = false;
      };

      this.$channel
        .push('haul:get manual cycle data', shift.id)
        .receive('ok', data => {
          this.fetchingData = false;

          if (shift.id !== data.shift.id) {
            console.error('[CycleTally] Received wrong shift');
            return;
          }

          this.shiftCycles = data.cycles.map(parseManualCycle);
          this.shiftEngineHours = data.engine_hours.map(parseEngineHour);
        })
        .receive('error', onError)
        .receive('timeout', onError);
    },
  },
};
</script> 
 
<style>
@import '../../../assets/hxInput.css';

.cycle-tally-page .search-bar-wrapper {
  max-width: 12rem;
  margin: 0.5rem 0;
  height: 1.6rem;
}

.cycle-tally-page .time-mode-selector {
  display: flex;
}

.cycle-tally-page .time-mode-selector .hx-btn {
  width: 8rem;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
}

.cycle-tally-page .time-mode-selector .hx-btn.selected {
  background-color: #2c404c;
  border: 1px solid #898f94;
}
</style>