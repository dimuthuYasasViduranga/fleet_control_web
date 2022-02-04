<template>
  <FieldWrapper class="drop-down-field" :v="v" v-bind="wrapper">
    <DropDown
      :value="value"
      :keyId="keyId"
      :keyLabel="keyLabel"
      :options="options"
      :placeholder="placeholder"
      :searchable="searchable"
      :selectable="selectable"
      :clearable="clearable"
      :useTouch="useTouch"
      :valueIsId="valueIsId"
      @input="onInput"
    />
  </FieldWrapper>
</template>

<script>
import FieldWrapper from './FieldWrapper.vue';
import DropDown from '@/components/dropdown/DropDown.vue';

export default {
  name: 'DropDownField',
  components: {
    FieldWrapper,
    DropDown,
  },
  props: {
    wrapper: { type: Object, required: true },
    value: { type: [String, Number, Object] },
    v: { type: Object, default: () => ({}) },
    keyId: { type: String, default: 'id' },
    keyLabel: { type: String, default: 'label' },
    options: { type: Array, default: () => [] },
    placeholder: { type: String },
    searchable: { type: Boolean, default: false },
    selectable: { type: Function },
    clearable: { type: Boolean, default: false },
    useTouch: { type: [Boolean, String], default: 'auto' },
    valueIsId: { type: Boolean, default: false },
  },
  methods: {
    onInput(value) {
      this.$emit('input', value);
    },
  },
};
</script>

<style>
.drop-down-field .drop-down {
  height: 100%;
  width: 100%;
  height: 2rem;
}

.drop-down-field.error .drop-down {
  border-color: #bd1d1d;
  border-width: 2px;
}
</style>