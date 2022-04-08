<template>
  <div class="operator-table">
    <SearchBar placeholder="Filter table" v-model="search" :showClear="true" />
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No Operators to Show"
      :data="filteredOperators"
      :show-caption="false"
      :show-filter="false"
      sort-by="name"
    >
      <table-column cell-class="table-cel" label="Legal Name">
        <template slot-scope="row">
          <span :class="{ deleted: row.deleted }">{{ row.name }}</span>
        </template>
      </table-column>

      <table-column cell-class="table-cel" label="Name">
        <template slot-scope="row">
          <span :class="{ deleted: row.deleted }">{{ row.nickname }}</span>
        </template>
      </table-column>

      <table-column cell-class="table-cel" label="Employee ID">
        <template slot-scope="row">
          <span :class="{ deleted: row.deleted }">{{ row.employeeId }}</span>
        </template>
      </table-column>

      <table-column
        label
        :sortable="false"
        :filterable="false"
        cell-class="table-btn-cel"
        :hidden="readonly"
      >
        <template slot-scope="row">
          <Icon
            v-if="!row.deleted"
            v-tooltip="'Edit'"
            class="edit-icon"
            :icon="editIcon"
            @click="onEdit(row)"
          />
        </template>
      </table-column>

      <table-column
        label="Enabled"
        :sortable="false"
        :filterable="false"
        cell-class="table-btn-cel action-cel"
      >
        <template slot-scope="row">
          <toggle-button
            :css-colors="true"
            :value="!row.deleted"
            :sync="true"
            :disabled="readonly"
            @input="onToggleActive(row, $event)"
          />
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import SearchBar from '../../SearchBar.vue';
import { ToggleButton } from 'vue-js-toggle-button';
import { isInText } from '../../../code/helpers';
import EditIcon from '@/components/icons/Edit.vue';

function filterByText(list, text, fields) {
  if (!text) {
    return list;
  }
  return list.filter(e => {
    return fields.some(field => isInText(e[field], text));
  });
}

export default {
  name: 'OperatorTable',
  components: {
    Icon,
    TableColumn,
    TableComponent,
    SearchBar,
    ToggleButton,
  },
  props: {
    readonly: Boolean,
    operators: { type: Array, default: () => [] },
    maxLength: { type: Number, default: 255 },
    error: { type: String, default: '' },
  },
  data: () => {
    return {
      editIcon: EditIcon,
      editingId: null,
      name: null,
      nickname: null,
      search: '',
    };
  },
  computed: {
    filteredOperators() {
      return filterByText(this.operators.slice(), this.search, [
        'name',
        'nickname',
        'employeeId',
      ]).sort((a, b) => a.name.localeCompare(b.name));
    },
  },
  methods: {
    greyedOut(row) {
      return {
        'greyed-out': row.deleted,
      };
    },
    onEdit(operator) {
      this.$emit('edit', operator);
    },
    onToggleActive(operator, isActive) {
      this.$emit('setActive', operator.id, isActive);
    },
  },
};
</script>

<style>
.operator-table .search-bar .search {
  max-width: 14rem;
  height: 2rem;
}

.operator-table .table th {
  cursor: default;
}

.operator-table .deleted {
  font-style: italic;
  color: grey;
}

.operator-table .button-set {
  display: flex;
  flex-direction: column;
}

.operator-table .table-btn-cel {
  text-align: center;
}

.operator-table .action-cel {
  min-width: 6rem;
}

.operator-table a {
  padding: 0.2rem;
  text-align: center;
}

.operator-table .edit-icon {
  cursor: pointer;
  height: 1rem;
}

.operator-table .edit-icon:hover {
  stroke: orange;
}

.operator-table .vue-js-switch.disabled {
  opacity: 1;
}
</style>