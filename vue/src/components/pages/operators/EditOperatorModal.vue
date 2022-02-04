<template>
  <div class="edit-operator-modal">
    <h1 class="title">Edit Operator</h1>
    <Form :v="$v.form" :layout="layout" :parser="errorParser" />
    <div class="actions">
      <button class="hx-btn" @click="onSubmit()">Submit</button>
      <button class="hx-btn" @click="onReset()">Reset</button>
      <button class="hx-btn" @click="onCancel()">Cancel</button>
    </div>
  </div>
</template>

<script>
import { validationMixin } from 'vuelidate';
import { required } from 'vuelidate/lib/validators';

import Form from '@/components/form/Form.vue';

export default {
  name: 'EditOperatorModal',
  wrapperClass: 'edit-operator-modal-wrapper',
  mixins: [validationMixin],
  components: {
    Form,
  },
  props: {
    operator: Object,
  },
  data() {
    return {
      form: {
        name: null,
        nickname: null,
        employeeId: null,
      },
      errorParser: {
        required: 'This field is required',
      },
      layout: {
        name: { type: 'input', label: 'Name' },
        nickname: { type: 'input', label: 'Short Name (optional)' },
        employeeId: { type: 'view', label: 'Employee ID' },
      },
    };
  },
  validations: {
    form: {
      name: { required },
      nickname: {},
      employeeId: { required },
    },
  },
  mounted() {
    this.onReset();
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onCancel() {
      this.close();
    },
    onReset() {
      this.$v.$reset();
      Object.keys(this.form).map(key => {
        this.form[key] = (this.operator || {})[key];
      });
    },
    onSubmit() {
      this.$v.$touch();
      if (!this.operator?.id) {
        return;
      }

      if (this.$v.$error) {
        return;
      }

      const payload = {
        id: this.operator.id,
        name: this.form.name,
        nickname: this.form.nickname,
      };

      this.$channel
        .push('update operator', payload)
        .receive('ok', () => {
          this.$toaster.info('Operator updated');
          this.close();
        })
        .receive('error', error => this.$toaster.error(error.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to update operator at this time'));
    },
  },
};
</script>

<style>
.edit-operator-modal-wrapper .modal-container {
  max-width: 32rem;
}

.edit-operator-modal .title {
  text-align: center;
}

.edit-operator-modal .actions {
  display: flex;
  width: 100%;
}

.edit-operator-modal .actions > button {
  width: 100%;
  font-size: 1rem;
  margin: 0.1rem;
}
</style>