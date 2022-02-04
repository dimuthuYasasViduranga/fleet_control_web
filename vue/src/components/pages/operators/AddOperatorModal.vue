<template>
  <div class="add-operator-modal">
    <h1 class="title">Add Operator</h1>
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
import { customValidator } from '@/components/form/validators';
import Form from '@/components/form/Form.vue';

export default {
  name: 'AddOperatorModal',
  wrapperClass: 'add-operator-modal-wrapper',
  mixins: [validationMixin],
  components: {
    Form,
  },
  props: {
    employeeIds: { type: Array, default: () => [] },
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
        unique: data => `'${data.v.$model}' already taken`,
      },
    };
  },
  validations: {
    form: {
      name: { required },
      nickname: {},
      employeeId: {
        required,
        unique: customValidator('unique', function (value) {
          return !this.employeeIds.includes(value);
        }),
      },
    },
  },
  computed: {
    layout() {
      return {
        name: { type: 'input', label: 'Name' },
        nickname: { type: 'input', label: 'Short Name (optional)' },
        employeeId: { type: 'input', label: 'Employee ID' },
      };
    },
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
      Object.keys(this.form).forEach(key => {
        this.form[key] = null;
      });
    },
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$error) {
        return;
      }

      console.dir(this.form);

      const payload = {
        name: this.form.name,
        nickname: this.form.nickname,
        employee_id: this.form.employeeId,
      };

      this.$channel
        .push('add operator', payload)
        .receive('ok', () => {
          this.$toaster.info('Operator created');
          this.close();
        })
        .receive('error', error => this.$toaster.error(error.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to create operator at this time'));
    },
  },
};
</script>

<style>
.add-operator-modal-wrapper .modal-container {
  max-width: 32rem;
}

.add-operator-modal .title {
  text-align: center;
}

.add-operator-modal .actions {
  display: flex;
  width: 100%;
}

.add-operator-modal .actions > button {
  width: 100%;
  font-size: 1rem;
  margin: 0.1rem;
}
</style>