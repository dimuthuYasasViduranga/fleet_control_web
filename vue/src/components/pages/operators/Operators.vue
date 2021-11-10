<template>
  <div class="operators-page">
    <hxCard style="width: auto" :title="title" :icon="manIcon">
      <EditOperator :show="!!pendingOperator" :operator="pendingOperator" @close="onEditClose" />
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

import EditOperator from './EditOperator.vue';
import OperatorTable from './OperatorTable.vue';
import Loaded from '../../Loaded.vue';

export default {
  name: 'Operators',
  components: {
    hxCard,
    OperatorTable,
    Loaded,
    EditOperator,
  },
  data: () => {
    return {
      title: 'Operators',
      manIcon: ManIcon,
      addIcon: AddIcon,
      pendingOperator: null,
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
    onEditClose() {
      this.pendingOperator = null;
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
      this.pendingOperator = {
        id: null,
        name: null,
        nickname: null,
        employeeId: null,
      };
    },
    onEdit(operator) {
      this.pendingOperator = {
        id: operator.id,
        name: operator.name,
        nickname: operator.nickname,
        employeeId: operator.employeeId,
      };
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
