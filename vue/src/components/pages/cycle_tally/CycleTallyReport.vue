<template>
  <div class="cycle-tally-report">
    <hxCard :title="`${asset.name} |`" :icon="icon" :class="[show ? 'open' : 'closed']">
      <div class="title-post" slot="title-post">
        <div class="summary-key cycles">Cycles: {{ cycles.length }}</div>
        <div class="summary-key man-hours">Man Hours: {{ formatHours(manSeconds) }}</div>
        <div class="summary-key machine-hours">Machine Hours: {{ machineHours }}</div>
        <div class="summary-key operators">Operators: {{ activeOperators.length }}</div>

        <Icon
          class="chevron-icon"
          :icon="chevronIcon"
          :rotation="show ? 270 : 90"
          @click="toggleShow"
        />
      </div>
      <div class="report-body" v-if="show">
        <hxCard class="distribution-card" title="Distribution">
          <CycleTallyDistributionTable
            :cycles="formattedCycles"
            :assets="assets"
            :locations="locations"
            :materialTypes="materialTypes"
          />
        </hxCard>
        <hxCard class="cycle-card" title="Cycles">
          <CycleTallyTable
            :cycles="formattedCycles"
            :assets="assets"
            :operators="operators"
            :locations="locations"
            :materialTypes="materialTypes"
            @edit="onCycleEdit"
            @delete="onCycleDelete"
            @copy="onCycleCopy"
          />
        </hxCard>
      </div>
    </hxCard>
  </div>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import CycleTallyTable from './CycleTallyTable.vue';
import CycleTallyDistributionTable from './CycleTallyDistributionTable.vue';
import ChevronIcon from '../../icons/ChevronRight.vue';

import { uniq, sortByTime, chunkEvery } from '../../../code/helpers';
import { copyDate } from '../../../code/time';

const SECONDS_IN_HOUR = 3600;

function getEngineHoursValue(engineHours, timestamp) {
  if (engineHours.length === 0) {
    return null;
  }

  const chunks = chunkEvery(engineHours, 2, 1, 'discard');
  const epoch = timestamp.getTime();
  for (const [a, b] of chunks) {
    const aEpoch = a.timestamp.getTime();
    const bEpoch = b.timestamp.getTime();

    if (timestamp >= aEpoch && timestamp <= bEpoch) {
      if (a.hours === b.hours) {
        return a.hours;
      }

      // linear interpolation
      const gradient = (b.hours - a.hours) / (bEpoch - aEpoch);
      const offset = a.hours - gradient * bEpoch;
      return epoch * gradient + offset;
    }
  }

  return null;
}

function getEngineHoursForCycle(engineHours, cycle) {
  const startEngineHours = getEngineHoursValue(engineHours, cycle.startTime);
  const endEngineHours = getEngineHoursValue(engineHours, cycle.endTime);

  if (startEngineHours === null || endEngineHours === null) {
    return null;
  }
  return endEngineHours - startEngineHours;
}

export default {
  name: 'CycleTallyReport',
  components: {
    hxCard,
    Icon,
    CycleTallyTable,
    CycleTallyDistributionTable,
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    cycles: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    engineHours: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    materialTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      chevronIcon: ChevronIcon,
      show: false,
      shift: null,
    };
  },
  computed: {
    icon() {
      return this.$store.state.constants.icons[this.asset.type];
    },
    activeOperators() {
      return uniq(this.cycles.map(c => c.operatorId));
    },
    manSeconds() {
      return (
        this.cycles
          .map(c => c.endTime.getTime() - c.startTime.getTime())
          .reduce((acc, duration) => acc + duration, 0) / 1000
      );
    },
    machineHours() {
      const hours = this.formattedCycles.reduce((acc, c) => acc + c.engineHours || 0, 0);
      return hours.toFixed(1);
    },
    formattedCycles() {
      return this.cycles.map(c => {
        return {
          ...c,
          startTime: copyDate(c.startTime),
          endTime: copyDate(c.endTime),
          engineHours: getEngineHoursForCycle(this.relevantEngineHours, c),
        };
      });
    },
    relevantEngineHours() {
      const engineHours = this.engineHours.filter(eh => eh.assetId === this.asset.id);
      return sortByTime(engineHours, 'timestamp');
    },
  },
  methods: {
    toggleShow() {
      this.show = !this.show;
    },
    formatHours(seconds) {
      return (seconds / SECONDS_IN_HOUR).toFixed(1);
    },
    onCycleEdit(cycle) {
      this.$emit('edit', cycle);
    },
    onCycleDelete(cycle) {
      this.$emit('delete', cycle);
    },
    onCycleCopy(cycle) {
      this.$emit('copy', cycle);
    },
  },
};
</script>

<style>
.cycle-tally-report .hxCardIcon {
  height: 2.5rem;
}

.cycle-tally-report .hxCard {
  border-left: 2px solid transparent;
}

.cycle-tally-report .hxCard.open {
  border: 2px solid #364c59;
}

.cycle-tally-report .distribution-card,
.cycle-tally-report .cycle-card {
  padding: 0;
}

.cycle-tally-report .title-post {
  text-transform: capitalize;
  display: flex;
  flex-direction: row;
  margin-left: 1rem;
}

.cycle-tally-report .chevron-icon {
  height: 1rem;
  width: 1.25rem;
  cursor: pointer;
}

.cycle-tally-report .summary-key {
  margin-right: 2rem;
}
</style>