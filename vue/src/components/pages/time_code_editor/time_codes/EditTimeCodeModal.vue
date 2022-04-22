<template>
  <div class="edit-time-code-modal">
    <h1 class="title">{{ title }}</h1>
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
import { customValidator } from '@/components/form/validators.js';

import Form from '@/components/form/Form.vue';
import { uniq } from '@/code/helpers';
import LoadingModal from '@/components/modals/LoadingModal.vue';

export default {
  name: 'EditTimeCodeModal',
  wrapperClass: 'edit-time-code-modal-wrapper',
  mixins: [validationMixin],
  components: {
    Form,
  },
  props: {
    value: Object,
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    timeCodeCategories: { type: Array, default: () => [] },
  },
  data() {
    return {
      form: {
        code: null,
        name: null,
        groupId: null,
        categoryId: null,
      },
      errorParser: {
        required: 'This field is required',
        unique: data => `'${data.v.$model}' already taken`,
      },
    };
  },
  validations: {
    form: {
      code: {
        required,
        unique: customValidator('unique', function (value) {
          return !this.codes.includes(value);
        }),
      },
      name: { required },
      groupId: { required },
      categoryId: {},
    },
  },
  computed: {
    title() {
      if (this.timeCode?.id) {
        return 'Edit Time Code';
      }
      return 'Add Time Code';
    },
    codes() {
      return uniq(this.timeCodes.map(t => t.code)).filter(code => code !== this.value?.code);
    },
    layout() {
      return {
        code: { type: 'input', label: 'Code' },
        name: { type: 'input', label: 'Name' },
        groupId: {
          type: 'dropdown',
          label: 'Group',
          props: { options: this.timeCodeGroups, keyLabel: 'siteName', placeholder: '--' },
        },
        categoryId: {
          type: 'dropdown',
          label: 'Category (optional)',
          props: {
            options: this.timeCodeCategories,
            keyLabel: 'name',
            clearable: true,
            placeholder: '--',
          },
        },
      };
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
      const timeCode = this.value || {};
      Object.keys(this.form).forEach(key => {
        this.form[key] = timeCode[key];
      });
    },
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$error) {
        return;
      }

      const payload = {
        id: this.value?.id,
        code: this.form.code,
        name: this.form.name,
        group_id: this.form.groupId,
        category_id: this.form.categoryId,
      };

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'Creating Time Code' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('update time code', payload)
        .receive('ok', () => {
          loading.close();
          this.$toaster.info(`Time Code ${payload.id ? 'Updated' : 'Created'}`);
          this.close();
        })
        .receive('error', resp => {
          loading.close();
          this.$toaster.error(resp.error);
        })
        .receive('timeout', () => {
          loading.close();
          this.$toaster.noComms('Unable to edit time code at this time');
        });
    },
  },
};
</script>

<style>
.edit-time-code-modal-wrapper .modal-container {
  max-width: 32rem;
}

.edit-time-code-modal .title {
  text-align: center;
}

.edit-time-code-modal .actions {
  display: flex;
  width: 100%;
}

.edit-time-code-modal .actions > button {
  width: 100%;
  font-size: 1rem;
  margin: 0.1rem;
}
</style>