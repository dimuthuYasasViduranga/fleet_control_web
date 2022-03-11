<template>
  <FieldWrapper class="input-field" :v="v" v-bind="wrapper">
    <input
      :value="value"
      :type="type"
      :placeholder="placeholder"
      v-bind="bindings"
      :autocomplete="autocomplete"
      @change="onChange"
      @keyup.enter="onEnter()"
      @focus="readonly = false"
      @click="readonly = false"
    />
  </FieldWrapper>
</template>

<script>
import FieldWrapper from './FieldWrapper.vue';

export default {
  name: 'InputField',
  components: {
    FieldWrapper,
  },
  props: {
    wrapper: { type: Object, required: true },
    value: { type: [String, Number], default: '' },
    v: { type: Object, default: () => ({}) },
    type: { type: String, default: 'text' },
    placeholder: { type: String, default: '' },
    autocomplete: { type: String, default: 'off' },
  },
  data: () => {
    return {
      readonly: true,
    };
  },
  computed: {
    bindings() {
      if (this.readonly) {
        return { readonly: true };
      }
      return {};
    },
  },
  watch: {
    autocomplete: {
      immediate: true,
      handler(value) {
        if (value === false || value === 'off') {
          this.readonly = true;
        }
      },
    },
  },
  methods: {
    onChange(event) {
      let value = event.target.value;
      if (this.type === 'number') {
        value = Number(value);
      }
      this.$emit('input', value);
    },
    onEnter() {
      this.$emit('input', this.value);
    },
  },
};
</script>

<style>
.input-field input {
  width: 100%;
  height: 2rem;
  border-radius: 0;
  border: 1px solid #677e8c;
  background-color: #1a2931;
  box-shadow: none;
  color: rgb(199, 199, 199);
  border-width: 1px;
  padding: 0 0.4rem;
}

.input-field.error input {
  border-color: #bd1d1d;
  border-width: 2px;
}

.input-field.error input:focus-visible {
  outline: 1px solid #bd1d1d;
}

/* hide the auto increment button */
.input-field input::-webkit-outer-spin-button,
.input-field input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

/* Firefox */
.input-field input[type='number'] {
  -moz-appearance: textfield;
}
</style>