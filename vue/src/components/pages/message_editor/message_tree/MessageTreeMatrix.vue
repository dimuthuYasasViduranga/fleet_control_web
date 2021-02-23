<template>
  <div class="message-tree-matrix">
    <table-component
      table-wrapper="#content"
      table-class="table"
      filterNoResults="No information to display"
      :data="rows"
      :show-caption="false"
    >
      <table-column cell-class="type" label="" show="type" />
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
  name: 'MessageTreeMatrix',
  components: {
    Icon,
    TableComponent,
    TableColumn,
  },
  props: {
    messageTypes: { type: Array, default: () => [] },
    messageTree: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      tickIcon: TickIcon,
    };
  },
  computed: {
    rows() {
      const assetLookup = this.assetTypes.reduce((acc, type) => {
        acc[type.id] = type.type;
        return acc;
      }, {});

      return this.messageTypes
        .filter(t => !t.deleted)
        .map(messageType => {
          const row = { type: messageType.type };
          const assetTypeIds = this.messageTree
            .filter(mt => mt.messageTypeId === messageType.id)
            .forEach(mt => (row[assetLookup[mt.assetTypeId]] = true));

          return row;
        })
        .sort((a, b) => a.type.localeCompare(b.type));
    },
    orderedAssetTypes() {
      const types = this.assetTypes.slice();
      types.sort((a, b) => a.type.localeCompare(b.type));
      return types;
    },
  },
};
</script>

<style>
.message-tree-matrix .table th {
  padding: 1rem 0;
  color: #b6c3cc;
  text-transform: none;
}

.message-tree-matrix .table td.bool {
  border-left: 0.05em solid #2c404c;
}

.message-tree-matrix .hx-icon {
  margin: auto;
  height: 1.25rem;
}

.message-tree-matrix .hx-icon svg {
  stroke-width: 1.5;
}

@media screen and (max-width: 1250px) {
  .message-tree-matrix th,
  .message-tree-matrix td.type {
    font-size: 11px;
  }
}
</style>