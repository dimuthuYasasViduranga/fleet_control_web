<template>
  <div class="time-allocation-page">
    <hxCard title="Time Allocation" :icon="icon">
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
      <div class="gap"></div>
      <div class="time-scale-wrapper">
        <div v-if="mode === 'live'" class="time-scale-options">
          <button
            class="hx-btn"
            v-for="(value, index) in liveTimeScaleValues"
            :key="index"
            :class="{ selected: value === liveTimeScale }"
            @click="setTimeScaleValue(value)"
          >
            {{ -value }} {{ value === 1 ? 'hour' : 'hours' }}
          </button>
        </div>
        <div v-else class="shift-select-options">
          <ShiftSelector
            :value="shift"
            :shifts="shifts"
            :shiftTypes="shiftTypes"
            :disabled="disableShiftSelect"
            :maxDatetime="maxShiftDatetime"
            @change="onShiftChange"
            @refresh="onRefresh"
          />
        </div>
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

      <AssetTimeSpanInfo
        v-for="{
          asset,
          timeAllocations,
          deviceAssignments,
          timeusage,
          cycles,
        } in filteredAssetData"
        :key="asset.name"
        :asset="asset"
        :timeAllocations="timeAllocations"
        :deviceAssignments="deviceAssignments"
        :timeusage="timeusage"
        :cycles="cycles"
        :operators="operators"
        :devices="devices"
        :timeCodes="timeCodes"
        :timeCodeGroups="timeCodeGroups"
        :fullTimeCodes="fullTimeCodes"
        :locations="locations"
        :activeEndTime="now"
        :minDatetime="range.min"
        :maxDatetime="range.max"
        :timezone="timezone"
        :shiftId="mode === 'shift' && shift ? shift.id : undefined"
        @update="refreshIfShift"
        @lock="refreshIfShift"
        @unlock="refreshIfShift"
      />
      <div class="gap"></div>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';

import ShiftSelector from '../../ShiftSelector.vue';
import SearchBar from '../../SearchBar.vue';

import AssetTimeSpanInfo from './AssetTimeSpanInfo.vue';

import TimeIcon from '../../icons/Time.vue';
import { isInText } from '../../../code/helpers';
import { parseTimeAllocation, parseTimeusage, parseCycle } from '../../../store/store.js';
import { parseDeviceAssignment } from '../../../store/modules/device_store.js';

const ACTIVE_INTERVAL_MS = 5 * 1000;
const HOURS_TO_MS = 60 * 60 * 1000;

function getRange({ now, width = 0, offset = 0 }) {
  return {
    min: new Date(now - offset - width),
    max: new Date(now - offset),
  };
}

function groupByAsset(assets, timeAllocations, deviceAssignments, timeusage, allCycles) {
  return assets.map(asset => {
    const assetId = asset.id;
    const allocations = timeAllocations.filter(ta => ta.assetId === assetId);
    const assignments = deviceAssignments.filter(da => da.assetId === assetId);
    const tus = timeusage.filter(tu => tu.assetId === assetId);
    const cycles = allCycles.filter(c => c.assetId === assetId);
    return {
      asset,
      timeAllocations: allocations,
      deviceAssignments: assignments,
      timeusage: tus,
      cycles,
    };
  });
}

export default {
  name: 'TimeAllocationPage',
  components: {
    hxCard,
    ShiftSelector,
    SearchBar,
    AssetTimeSpanInfo,
  },
  data: () => {
    const liveTimeScaleValues = [12, 6, 3, 1, 0.5, 0.1];
    const liveTimeScale = liveTimeScaleValues[0];
    const now = new Date();
    return {
      icon: TimeIcon,
      error: '',
      search: '',
      mode: 'live',
      now,
      range: getRange({
        now,
        width: liveTimeScale * HOURS_TO_MS,
      }),
      shiftAssetData: [],
      liveTimeScale,
      liveTimeScaleValues,
      shift: null,
      maxShiftDatetime: new Date(),
      disableShiftSelect: false,
      activeInterval: null,
      selectedAssetTypes: [],
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      assetTypes: state => state.assetTypes,
      operators: state => state.operators,
      shifts: state => state.shifts,
      shiftTypes: state => state.shiftTypes,
      timeCodes: state => state.timeCodes,
      timeCodeGroups: state => state.timeCodeGroups,
      locations: state => state.locations,
    }),
    ...mapState('deviceStore', {
      devices: state => state.devices,
      liveDeviceAssignments: state => state.historicDeviceAssignments,
    }),
    ...mapState({
      fleetOpsCycles: state => state.fleetOps.cycles,
      fleetOpsTimeusage: state => state.fleetOps.timeusage,
    }),
    timezone() {
      return this.$timely.current.timezone;
    },
    fullTimeCodes() {
      return this.$store.getters['constants/fullTimeCodes'];
    },
    liveTimeAllocations() {
      const historic = this.$store.state.historicTimeAllocations;
      const activeAllocations = this.$store.state.activeTimeAllocations;

      return historic.concat(activeAllocations);
    },
    liveAssetData() {
      return groupByAsset(
        this.assets,
        this.liveTimeAllocations,
        this.liveDeviceAssignments,
        this.fleetOpsTimeusage,
        this.fleetOpsCycles,
      );
    },
    selectedAssetData() {
      if (this.mode === 'shift') {
        return this.shiftAssetData;
      }
      return this.liveAssetData;
    },
    filteredAssetData() {
      let assetData = this.selectedAssetData.slice();

      const selectedAssetTypes = this.selectedAssetTypes.filter(t => t.selected).map(t => t.type);
      assetData = assetData.filter(ad => selectedAssetTypes.includes(ad.asset.type));

      // sort by name
      assetData.sort((a, b) => a.asset.name.localeCompare(b.asset.name));

      // filter by search text
      if (!this.search) {
        return assetData;
      }

      return assetData.filter(ad => isInText(ad.asset.name, this.search));
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
    filteredAssetData() {
      this.updateNow();
    },
  },
  mounted() {
    this.setActiveInterval();
  },
  methods: {
    setActiveInterval() {
      clearInterval(this.activeInteravl);
      this.activeInterval = setInterval(() => this.updateNow(), ACTIVE_INTERVAL_MS);
    },
    updateNow() {
      const now = new Date();
      this.now = now;
      if (this.mode === 'live') {
        this.range = getRange({ now: this.now, width: this.liveTimeScale * HOURS_TO_MS });
      }
    },
    setTimeScaleValue(value) {
      this.liveTimeScale = value;
      this.range = getRange({ now: this.now, width: value * HOURS_TO_MS });
    },
    setTimeMode(mode) {
      this.mode = mode;

      if (mode === 'live') {
        this.shift = null;
        this.range = getRange({ now: this.now, width: this.liveTimeScale * HOURS_TO_MS });
      }
    },
    clearAssetTypeSelection() {
      this.selectedAssetTypes.forEach(t => (t.selected = false));
    },
    setAssetTypeSelection() {
      this.selectedAssetTypes.forEach(t => (t.selected = true));
    },
    onShiftChange(shift) {
      this.shift = shift;
      this.fetchAllocationsByShift(shift);
    },
    onRefresh() {
      this.maxShiftDatetime = new Date();
      this.fetchAllocationsByShift(this.shift);
    },
    refreshIfShift() {
      if (this.mode === 'shift') {
        this.onRefresh();
      }
    },
    fetchAllocationsByShift(shift) {
      this.disableShiftSelect = true;

      if (this.mode !== 'shift' || !shift) {
        this.disableShiftSelect = false;
        return;
      }

      const onError = () => {
        this.shiftAssetData = [];
        this.disableShiftSelect = false;
      };

      this.$channel
        .push('get time allocation data', shift.id)
        .receive('ok', data => {
          this.disableShiftSelect = false;

          if (shift.id !== data.shift.id) {
            console.error('[TimeAlloc] received wrong shift');
            return;
          }

          this.range = {
            min: new Date(shift.startTime),
            max: new Date(shift.endTime),
          };

          const allocations = (data.allocations || []).map(parseTimeAllocation);
          const deviceAssignments = (data.device_assignments || []).map(parseDeviceAssignment);
          const timeusage = (data.timeusage || []).map(parseTimeusage);
          const cycles = (data.cycles || []).map(parseCycle);

          this.shiftAssetData = groupByAsset(
            this.assets,
            allocations,
            deviceAssignments,
            timeusage,
            cycles,
          );
        })
        .receive('error', onError)
        .receive('timeout', onError);
    },
  },
};
</script>

<style>
.time-allocation-page .gap {
  height: 0.5rem;
}

.time-allocation-page .time-mode-selector {
  display: flex;
}

.time-allocation-page .time-mode-selector .hx-btn {
  width: 8rem;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
}

.time-allocation-page .time-mode-selector .hx-btn.selected {
  background-color: #2c404c;
  border: 1px solid #898f94;
}

.time-allocation-page .time-scale-wrapper {
  height: 4rem;
}

.time-allocation-page .time-scale-options {
  height: 100%;
  display: flex;
  padding-top: 1rem;
}

.time-allocation-page .asset-type-selector {
  width: 100%;
  display: flex;
  flex-wrap: wrap;
}

.time-allocation-page .asset-type-selector .hx-btn {
  margin: 0.05rem 0;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
}

.time-allocation-page .asset-type-selector .hx-btn.not-selected {
  opacity: 0.5;
}

.time-allocation-page .time-scale-options .hx-btn {
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
}

.time-allocation-page .time-scale-options .hx-btn.selected {
  background-color: #2c404c;
  border: 1px solid #898f94;
}

.time-allocation-page .search-bar-wrapper {
  max-width: 12rem;
  margin: 0.5rem 0;
  height: 1.6rem;
}
</style>