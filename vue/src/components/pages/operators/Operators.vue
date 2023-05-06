<template>
  <div class="operators-page">
    <hxCard style="width: auto" :title="title" :icon="manIcon">
      <loaded>
        <div v-if="!readonly" class="actions">
          <button class="hx-btn" @click="onAdd()">Add New</button>
          <button class="hx-btn" @click="onBulkAdd()">Bulk Add</button>
          <button class="hx-btn" @click="onExport()">Export as CSV</button>
        </div>
        <operator-table
          :operators="operators"
          :readonly="readonly"
          @edit="onEdit"
          @setActive="onSetActive"
        />
      </loaded>
    </hxCard>
  </div>
</template>

<script >
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';

import ManIcon from '@/components/icons/Man.vue';
import AddIcon from '@/components/icons/Add.vue';

import OperatorTable from './OperatorTable.vue';
import Loaded from '@/components/Loaded.vue';
import EditOperatorModal from './EditOperatorModal.vue';
import BulkAddOperatorModal from './BulkAddOperatorModal.vue';
import AddOperatorModal from './AddOperatorModal.vue';
import { writeToString } from '@fast-csv/format';
import { downloadFromText } from '@/code/io';

function exportAsCSV(operators) {
  const formattedOperators = operators.map(o => {
    return {
      name: o.name,
      short_name: o.nickname,
      employee_id: o.employeeId,
    };
  });
  const headers = ['name', 'short_name', 'employee_id'];
  const rows = formattedOperators.map(o => headers.map(h => o[h]));

  writeToString(rows, { headers }).then(text => {
    downloadFromText(text, 'operators.csv');
  });
}

export default {
  name: 'Operators',
  components: {
    hxCard,
    OperatorTable,
    Loaded,
  },
  data: () => {
    return {
      title: 'Operators',
      manIcon: ManIcon,
      addIcon: AddIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      readonly: state => !state.permissions.fleet_control_edit_operators,
      operators: state => state.operators,
    }),
  },
  methods: {
    onSetActive(operatorId, enabled) {
      const payload = {
        id: operatorId,
        enabled,
      };

      this.$channel
        .push('operator:set-enabled', payload)
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to change status at this time'));
    },
    onAdd() {
      const employeeIds = this.operators.map(o => o.employeeId);

      this.$modal.create(AddOperatorModal, { employeeIds });
    },
    onEdit(operator) {
      this.$modal.create(EditOperatorModal, { operator });
    },
    onBulkAdd() {
      const opts = { operators: this.operators };
      this.$modal.create(BulkAddOperatorModal, opts);
    },
    onExport() {
      exportAsCSV(this.operators);
    },
  },
};
</script>

<style>
@import '../../../assets/table.css';
@import '../../../assets/hxInput.css';

.operators-page .actions {
  display: flex;
  padding-bottom: 1rem;
}
.operators-page .actions > * {
  margin-right: 0.25rem;
}
</style>
