<template>
  <modal class="edit-operator" :show="show" @close="onClose()">
    <div class="edit-operator-wrapper">
      <div class="title">Edit Operator</div>
      <div class="error">{{ error }}</div>
      <input
        id="name"
        class="operator-name typeable"
        v-model="localOperator.name"
        placeholder="Legal Name"
        type="text"
        autocomplete="off"
      />

      <input
        id="nickname"
        class="operator-nickname typeable"
        v-model="localOperator.nickname"
        placeholder="Short Name (optional)"
        type="text"
        autocomplete="off"
      />

      <input
        id="employee_id"
        class="employee-id typeable"
        placeholder="Employee ID"
        v-model="localOperator.employeeId"
        type="number"
        :disabled="localOperator.id"
        pattern="\d+"
        min="0"
        step="1"
      />

      <div class="buttons">
        <button
          v-if="!localOperator.id"
          class="hx-btn"
          :disabled="!hasChanged || !validEntry"
          @click="onAdd"
        >
          Create
        </button>
        <button v-else class="hx-btn" :disabled="!hasChanged || !validEntry" @click="onUpdate">
          Update
        </button>
        <button class="hx-btn" @click="reset">Reset</button>
        <button class="hx-btn" @click="onClose">Close</button>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from '../../modals/Modal.vue';

function getError(operator) {
  if (!operator.name) {
    return 'Please enter valid name';
  }

  if (!operator.employeeId) {
    return 'Please enter valid employee id';
  }

  return;
}

export default {
  name: 'EditOperator',
  components: {
    Modal,
  },
  props: {
    operator: { type: Object, default: () => null },
    show: { type: Boolean, default: false },
  },
  data: () => {
    return {
      error: '',
      localOperator: {},
    };
  },
  computed: {
    hasChanged() {
      const a = this.operator || {};
      const b = this.localOperator || {};
      return ['id', 'name', 'nickname', 'employeeId'].some(key => a[key] !== b[key]);
    },
    validEntry() {
      return this.localOperator.name && this.localOperator.employeeId;
    },
  },
  watch: {
    show(isOpen) {
      if (isOpen) {
        this.reset();
      } else {
        this.localOperator = {};
      }
      this.clearError();
    },
  },
  methods: {
    reset() {
      this.localOperator = { ...this.operator };
    },
    setError(error) {
      this.error = error;
    },
    clearError() {
      this.error = '';
    },
    onClose() {
      this.$emit('close');
    },
    onAdd() {
      const operator = this.localOperator;
      const error = getError(operator);
      if (error) {
        this.setError(error);
        return;
      }

      const payload = {
        name: operator.name,
        nickname: operator.nickname,
        employee_id: operator.employeeId,
      };

      this.sendAction('add operator', payload, 'Unable to add operator');
    },
    onUpdate() {
      const operator = this.localOperator;
      const error = getError(operator);
      if (error) {
        this.setError(error);
        return;
      }

      const payload = {
        id: operator.id,
        name: operator.name,
        nickname: operator.nickname,
      };

      this.sendAction('update operator', payload, 'Unable to update operator');
    },
    sendAction(topic, payload, timeoutMsg) {
      this.$channel
        .push(topic, payload)
        .receive('ok', () => this.onClose())
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms(timeoutMsg));
    },
  },
};
</script>

<style>
.edit-operator .modal-container {
  max-width: 25rem;
}

.edit-operator .title {
  font-size: 1.5rem;
}

.edit-operator-wrapper {
  display: flex;
  flex-direction: column;
}

.edit-operator-wrapper .error {
  height: 0.5rem;
  text-align: center;
}

.edit-operator-wrapper .typeable {
  margin-top: 0.5rem;
}

.edit-operator-wrapper .typeable[disabled] {
  font-style: italic;
}

.edit-operator-wrapper .buttons {
  padding-top: 1rem;
  display: flex;
  justify-content: space-between;
}

.edit-operator-wrapper .hx-btn[disabled] {
  cursor: default;
  opacity: 0.5;
}

.edit-operator-wrapper .hx-btn[disabled]:hover {
  background-color: #425866;
}

.edit-operator-wrapper .buttons .hx-btn {
  width: 33%;
}
</style>