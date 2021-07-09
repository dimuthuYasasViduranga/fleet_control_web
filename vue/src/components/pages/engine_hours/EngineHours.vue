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
            data-type="numeric"
            :formatter="thousands"
          />
          <table-column
            cell-class="table-cel"
            label="Entered At"
            show="timestamp"
            data-type="date"
            :formatter="formatTime"
          />
          <table-column :sortable="false" :filterable="false" cell-class="table-btn-cel request">
            <template slot-scope="row">
              <LockableButton @click="onRequestHours(row)" :lock="locked.includes(row.id)">
                Request Hours
              </LockableButton>
            </template>
          </table-column>
        </table-component>
      </loaded>
    </hxCard>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';
import { copyDate, formatDateRelativeToIn } from './../../../code/time';

import Loaded from '../../Loaded.vue';
import hxCard from 'hx-layout/Card.vue';
import LockableButton from '@/components/LockableButton.vue';

import PlaneEngineIcon from '../../icons/PlaneEngine.vue';
import { attributeFromList } from '@/code/helpers';
import { uniq } from '../../../code/helpers';

const MAX_HOURS_BETWEEN_ENTRIES = 24;

export default {
  name: 'EngineHours',
  components: {
    hxCard,
    TableColumn,
    TableComponent,
    Loaded,
    LockableButton,
  },
  data: () => {
    return {
      title: 'Engine Hours',
      icon: PlaneEngineIcon,
      locked: [],
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
          assetName: a.name || '',
          hours: engineHrs.hours,
          enteredBy: engineHrs.operatorFullname || '',
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
      const tz = this.$timely.current.timezone;
      const format = formatDateRelativeToIn(time, tz);
      const deltaHours = (Date.now() - time) / (3600 * 1000);
      let color = '';

      if (deltaHours > MAX_HOURS_BETWEEN_ENTRIES) {
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
    setLocked(id, bool) {
      if (bool === true) {
        this.locked = uniq(this.locked.concat([id]));
      } else {
        this.locked = this.locked.filter(id => id !== id);
      }
    },
    onRequestHours(row) {
      const payload = {
        message: 'Please enter engine hours when safe',
        asset_id: row.id,
        timestamp: Date.now(),
      };

      this.setLocked(row.id, true);

      this.$channel
        .push('add dispatcher message', payload)
        .receive('ok', () => {
          this.setLocked(row.id, false);

          this.$toaster.info(`${row.assetName} | Engine Hours request sent`, { onlyOne: true });
        })
        .receive('error', resp => {
          this.setLocked(row.id, false);

          this.$toaster.error(resp.error || `${row.assetName} | Unable to send request`);
        })
        .receive('timeout', () => {
          this.setLocked(row.id, false);

          this.$toaster.noComms(`${row.assetName} | Unable to send request`);
        });
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
