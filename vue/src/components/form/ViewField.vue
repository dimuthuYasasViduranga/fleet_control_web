<template>
  <FieldWrapper class="view-field" :v="v" v-bind="wrapper">
    <input :value="value" type="text" disabled="true" />
  </FieldWrapper>
</template>

<script>
import FieldWrapper from './FieldWrapper.vue';

export default {
  name: 'ViewField',
  components: {
    FieldWrapper,
  },
  props: {
    wrapper: { type: Object, required: true },
    value: [String, Number, Object, Boolean],
    v: { type: Object, default: () => ({}) },
    placeholder: { type: String, default: '' },
  },
};
</script>

<style>
.view-field input {
  width: 100%;
  height: 2rem;
  border-radius: 0;
  border: 1px solid #677e8c;
  background-color: #1a2931;
  box-shadow: none;
  color: rgb(199, 199, 199);
  border-width: 1px;
  padding: 0 0.4rem;
  opacity: 0.5;
}
</style>