<template>
  <div class="review-pane">
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No dig units have been assigned to devices"
      :data="restrictionGroups"
      :show-caption="false"
      :show-filter="false"
    >
      <table-column cell-class="table-cel" label="Group" show="name" />
      <table-column cell-class="table-cel" label="Asset Types" show="assetTypes">
        <template slot-scope="row">
          {{ row.assetTypes.join(',  ') }}
        </template>
      </table-column>

      <table-column cell-class="table-status-cel" label="Status">
        <template slot-scope="row">
          <Icon
            v-if="row.edgeIds.length"
            v-tooltip="'Routes available'"
            class="tick-icon"
            :icon="tickIcon"
          />
          <Icon v-else v-tooltip="'Missing Routes'" class="cross-icon" :icon="crossIcon" />
        </template>
      </table-column>
    </table-component>

    <div class="actions">
      <button class="hx-btn" @click="up('reset')">Reset All Changes</button>
      <button class="hx-btn" @click="up('cancel')">Cancel</button>
      <button class="hx-btn" @click="up('submit')">Submit</button>
    </div>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';
import Icon from 'hx-layout/Icon.vue';

import TickIcon from '@/components/icons/Tick.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';

export default {
  name: 'ReviewPane',
  components: {
    TableComponent,
    TableColumn,
    Icon,
  },
  props: {
    graph: { type: Object },
    locations: { type: Array, default: () => [] },
    restrictionGroups: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      tickIcon: TickIcon,
      crossIcon: CrossIcon,
    };
  },
  methods: {
    up(topic) {
      this.$emit(topic);
    },
  },
};
</script>

<style>
.review-pane .table-status-cel {
  width: 3rem;
}

.review-pane .table-status-cel .hx-icon {
  width: 2rem;
  margin: auto;
}

.review-pane .table-status-cel .tick-icon {
  stroke: rgb(0, 255, 0);
}

.review-pane .table-status-cel .cross-icon {
  stroke: rgb(255, 80, 80);
}
</style>