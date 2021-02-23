<template>
  <div class="engine-hours">
    <hxCard style="width: auto" :title="title" :icon="icon">
      <loaded>
        <table-component
          table-wrapper="#content"
          table-class="table"
          filterNoResults="No information to display"
          :data="engineHours"
          :show-caption="false"
          sort-by="asset"
          sort-order="asc"
        >
          <table-column cell-class="table-cel" label="Asset" show="assetName" />
          <table-column cell-class="table-cel" label="Entered By" show="enteredBy" />
          <table-column
            cell-class="table-cel"
            label="Engine Hours"
            show="hours"
            :formatter="thousands"
          />
          <table-column
            cell-class="table-cel"
            label="Entered At"
            show="timestamp"
            :formatter="formatTime"
          />
          <table-column :sortable="false" :filterable="false" cell-class="table-btn-cel request">
            <template slot-scope="row">
              <a :id="`${row.id}`" @click="onRequestHours(row)">Request Hours</a>
            </template>
          </table-column>
        </table-component>
      </loaded>
    </hxCard>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';
import { copyDate, formatTodayRelative } from './../../../code/time';

import Loaded from '../../Loaded.vue';
import hxCard from 'hx-layout/Card.vue';
import error from 'hx-layout/Error.vue';
import Icon from 'hx-layout/Icon.vue';

import PlaneEngineIcon from '../../icons/PlaneEngine.vue';
import { attributeFromList } from '@/code/helpers';

const MAX_TIME_BETWEEN_ENTRIES = 24;

export default {
  name: 'EngineHours',
  components: {
    hxCard,
    error,
    TableColumn,
    TableComponent,
    Icon,
    Loaded,
  },
  data: () => {
    return {
      title: 'Engine Hours',
      icon: PlaneEngineIcon,
    };
  },
  computed: {
    engineHours() {
      const engineHours = this.$store.getters.engineHours();
      const assets = this.$store.getters.fullAssets.filter(a => a.hasDevice);

      return assets.map(a => {
        const engineHrs = attributeFromList(engineHours, 'assetId', a.id) || {};

        return {
          id: a.id,
          assetName: a.name,
          hours: engineHrs.hours,
          enteredBy: engineHrs.operatorFullname,
          timestamp: copyDate(engineHrs.timestamp),
        };
      });
    },
  },
  methods: {
    formatTime(time) {
      if (!time) {
        return '--';
      }
      const format = formatTodayRelative(time, { format: 'HH:mm' });
      const deltaHours = (Date.now() - time) / (3600 * 1000);
      let color = '';

      if (deltaHours > MAX_TIME_BETWEEN_ENTRIES) {
        color = 'red-text';
      }
      return `<span class="${color}">${format}</span>`;
    },
    thousands(num) {
      if (!num) {
        return '--';
      }

      return num.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 2 });
    },
    onRequestHours(row) {
      const payload = {
        message: 'Please enter engine hours when safe',
        asset_id: row.id,
        timestamp: Date.now(),
      };

      this.$channel.push('add dispatcher message', payload);
    },
  },
};
</script>

<style>
@import '../../../assets/table.css';
@import '../../../assets/hxInput.css';
@import '../../../assets/textColors.css';

.engine-hours .request {
  min-width: 8rem;
}
</style>
