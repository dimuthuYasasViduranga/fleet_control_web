<template>
  <div class="cycle-tally-distribution-table">
    <table-component
      table-wrapper="#content"
      table-class="table"
      filterNoResults="No information to display"
      :data="distribution"
      :show-caption="false"
      :show-filter="false"
      sort-order="desc"
    >
      <table-column cell-class="table-cel" label="Load Unit" show="loadUnit" />
      <table-column cell-class="table-cel" label="Dump" show="dumpLocation" />
      <table-column cell-class="table-cel" label="Material" show="materialType" />
      <table-column
        cell-class="table-cel"
        label="Man Hours"
        show="manSeconds"
        :formatter="formatSecondsAsHours"
      />
      <table-column
        cell-class="table-cel"
        label="Engine hours"
        show="engineSeconds"
        :formatter="formatSecondsAsHours"
      />
    </table-component>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';
import { attributeFromList, groupBy } from '../../../code/helpers';
import { firstBy } from 'thenby';

const SECONDS_IN_HOUR = 3600;

export default {
  name: 'CycleTallyDistributionTable',
  components: {
    TableComponent,
    TableColumn,
  },
  props: {
    cycles: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    materialTypes: { type: Array, default: () => [] },
  },
  computed: {
    distribution() {
      const cycles = this.cycles.map(c => {
        const loadUnit = attributeFromList(this.assets, 'id', c.loadUnitId, 'name');
        const dumpLocation = attributeFromList(this.locations, 'id', c.dumpLocationId, 'name');
        const materialType = attributeFromList(
          this.materialTypes,
          'id',
          c.materialTypeId,
          'commonName',
        );
        const duration = c.endTime.getTime() - c.startTime.getTime();
        return {
          loadUnit,
          dumpLocation,
          materialType,
          duration,
          engineHours: c.engineHours,
          key: `${loadUnit}|${dumpLocation}|${materialType}`,
        };
      });

      const distribution = Object.values(groupBy(cycles, 'key')).map(groupCycles => {
        const first = groupCycles[0];

        const totalDuration = Math.trunc(
          groupCycles.reduce((acc, cycle) => acc + cycle.duration, 0) / 1000,
        );

        const totalEngineSeconds = Math.trunc(
          groupCycles.reduce((acc, cycle) => acc + (cycle.engineHours || 0), 0) * 3600,
        );

        return {
          loadUnit: first.loadUnit,
          dumpLocation: first.dumpLocation,
          materialType: first.materialType,
          manSeconds: totalDuration,
          engineSeconds: totalEngineSeconds,
        };
      });

      distribution.sort(firstBy('loadUnit').thenBy('dumpLocation').thenBy('materialType'));

      return distribution;
    },
  },
  methods: {
    formatSecondsAsHours(seconds) {
      if (!seconds && seconds !== 0) {
        return '--';
      }

      return (seconds / SECONDS_IN_HOUR).toFixed(1);
    },
  },
};
</script>

<style>
</style>