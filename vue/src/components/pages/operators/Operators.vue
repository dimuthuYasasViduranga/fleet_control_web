<template>
  <div class="operators-page">
    <hxCard style="width: auto" :title="title" :icon="manIcon">
      <loaded>
        <div class="heading">
          <button class="hx-btn add-new-btn" @click="onAdd">Add New Operator</button>
        </div>
        <operator-table :operators="operators" @edit="onEdit" @setActive="onSetActive" />
      </loaded>
    </hxCard>
  </div>
</template>

<script >
import hxCard from 'hx-layout/Card.vue';

import ManIcon from '../../icons/Man.vue';
import AddIcon from '../../icons/Add.vue';

import OperatorTable from './OperatorTable.vue';
import Loaded from '../../Loaded.vue';
import EditOperatorModal from './EditOperatorModal.vue';

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
    operators() {
      return this.$store.state.constants.operators;
    },
  },
  methods: {
    setError(reason) {
      this.error = reason;
    },
    clearError() {
      this.error = '';
    },
    onSetActive(operatorId, enabled) {
      const payload = {
        id: operatorId,
        enabled,
      };

      this.$channel
        .push('set operator enabled', payload)
        .receive('error', resp => this.onError(resp.error))
        .receive('timeout', () => this.onError('No Connection - Cannot edit enabled status'));
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
    onError(msg) {
      this.$toaster.error(msg);
    },
  },
};
</script>

<style>
@import '../../../assets/table.css';
@import '../../../assets/hxInput.css';

.operators-page .heading {
  padding-bottom: 1rem;
}
</style>
