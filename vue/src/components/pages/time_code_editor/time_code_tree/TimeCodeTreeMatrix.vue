<template>
  <div class="time-code-tree-matrix">
    <table-component
      table-wrapper="#content"
      table-class="table"
      filterNoResults="No information to display"
      :data="rows"
      :show-caption="false"
    >
      <table-column cell-class="type" label="" show="name" />
      <table-column
        cell-class="bool"
        v-for="type in orderedAssetTypes"
        :key="type.id"
        :label="type.type"
        :show="type.type"
      >
        <template slot-scope="row">
          <Icon
            v-tooltip="{ content: type.type, delay: { show: 300, hide: 10 } }"
            :icon="row[type.type] ? tickIcon : null"
          />
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import TickIcon from '@/components/icons/Tick.vue';
export default {
  name: 'TimeCodeTreeMatrix',
  components: {
    Icon,
    TableComponent,
    TableColumn,
  },
  props: {
    timeCodes: { type: Array, default: () => [] },
    timeCodeTreeElements: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      tickIcon: TickIcon,
    };
  },
  computed: {
    orderedAssetTypes() {
      const types = this.assetTypes.slice();
      types.sort((a, b) => a.type.localeCompare(b.type));
      return types;
    },
    rows() {
      const assetLookup = this.assetTypes.reduce((acc, type) => {
        acc[type.id] = type.type;
        return acc;
      }, {});

      const rows = this.timeCodes.map(tc => {
        const row = { name: `${tc.code} - ${tc.name}` };
        this.timeCodeTreeElements
          .filter(e => e.timeCodeId === tc.id)
          .forEach(e => (row[assetLookup[e.assetTypeId]] = true));
        return row;
      });

      rows.sort((a, b) => a.name.localeCompare(b.name));

      return rows;
    },
  },
};
</script>

<style>
.time-code-tree-matrix .table th {
  padding: 1rem 0;
  color: #b6c3cc;
  text-transform: none;
}

.time-code-tree-matrix .table td.bool {
  border-left: 0.05em solid #2c404c;
}

.time-code-tree-matrix .hx-icon {
  margin: auto;
  height: 1.25rem;
}

.time-code-tree-matrix .hx-icon svg {
  stroke-width: 1.5;
}

@media screen and (max-width: 1250px) {
  .time-code-tree-matrix th,
  .time-code-tree-matrix td.type {
    font-size: 11px;
  }
}
</style>