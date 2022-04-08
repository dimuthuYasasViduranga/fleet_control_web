<template>
  <FieldWrapper class="autocomplete-field" :v="v" v-bind="wrapper">
    <Typeahead
      :value="value"
      :options="stringOptions"
      :placeholder="placeholder"
      :clearable="clearable"
      :useTouch="useTouch"
      @input="onInput"
    />
  </FieldWrapper>
</template>

<script>
import FieldWrapper from './FieldWrapper.vue';

import Typeahead from '@/components/Typeahead.vue';

export default {
  name: 'AutocompleteField',
  components: {
    FieldWrapper,
    Typeahead,
  },
  props: {
    wrapper: { type: Object, required: true },
    value: { type: [String, Object] },
    v: { type: Object, default: () => ({}) },
    options: { type: Array, default: () => [] },
    placeholder: { type: String },
    clearable: { type: Boolean, default: false },
    useTouch: { type: [Boolean, String], default: 'auto' },
  },
  computed: {
    stringOptions() {
      return this.options.filter(o => typeof o === 'string');
    },
  },
  methods: {
    onInput(value) {
      this.$emit('input', value);
    },
  },
};
</script>

<style>
.autocomplete-field .typeahead {
  width: 100%;
  height: 2rem;
}

.autocomplete-field .typeahead .drop-down {
  height: 100%;
  border: none;
}

.autocomplete-field.error .typeahead {
  border-color: #bd1d1d;
  border-width: 2px;
}
</style>