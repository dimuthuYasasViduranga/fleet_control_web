<template>
  <div class="operators-page">
    <hxCard style="width: auto" :title="title" :icon="manIcon">
      <loaded>
        <div v-if="!readonly" class="actions">
          <button class="hx-btn add-new-btn" @click="onAdd()">Add New</button>
          <button class="hx-btn add-new-btn" @click="onBulkAdd()">Bulk Add</button>
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
      readonly: state => !state.permissions.can_edit_operators,
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
        .push('set operator enabled', payload)
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to change status at this time'));
    },
    onAdd() {
      const opts = {
        title: 'Add Operator',
        operators: this.operators,
        operator: {
          id: null,
          name: null,
          nickname: null,
          employeeId: null,
        },
      };

      this.$modal.create(EditOperatorModal, opts);
    },
    onEdit(operator) {
      const opts = {
        title: 'Edit Operator',
        operators: this.operators,
        operator: { ...operator },
      };
      this.$modal.create(EditOperatorModal, opts);
    },
    onBulkAdd() {
      const opts = { operators: this.operators };
      this.$modal.create(BulkAddOperatorModal, opts);
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
.operators-page .actions * {
  margin-right: 0.25rem;
}
</style>
