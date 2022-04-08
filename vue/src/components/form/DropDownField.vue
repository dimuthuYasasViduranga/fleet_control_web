<template>
  <FieldWrapper class="drop-down-field" :v="v" v-bind="wrapper">
    <DropDown
      :value="value"
      :keyId="keyId"
      :label="keyLabel"
      :options="options"
      :placeholder="placeholder"
      :searchable="searchable"
      :selectable="selectable"
      :clearable="clearable"
      :useTouch="useTouch"
      :valueIsObj="valueIsObj"
      @input="onInput"
    />
  </FieldWrapper>
</template>

<script>
import FieldWrapper from './FieldWrapper.vue';
import { DropDown } from 'hx-vue';

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
    selectable: { type: Function },
    useTouch: Boolean,
    searchable: Boolean,
    clearable: Boolean,
    valueIsObj: Boolean,
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