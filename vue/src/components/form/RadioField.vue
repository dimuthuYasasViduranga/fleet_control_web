<template>
  <FieldWrapper class="radio-field" :v="v" v-bind="wrapper">
    <div class="option" v-for="option in options" :key="option.id">
      <input
        type="checkbox"
        :checked="option.id === value"
        @change="onSet(option.id)"
        @keyup.enter="onSet(option.id)"
      />
      <span @click="onSet(option.id)"> {{ option.name }}</span>
    </div>
  </FieldWrapper>
</template>

<script>
import FieldWrapper from './FieldWrapper.vue';

function toOption(item) {
  if (typeof item === 'string') {
    return { id: item, name: item };
  }
  return item;
}

export default {
  name: 'RadioField',
  components: {
    FieldWrapper,
  },
  props: {
    wrapper: { type: Object, required: true },
    value: { type: [Number, String, Boolean] },
    v: { type: Object, defualt: () => ({}) },
    items: { type: Array, default: () => [] },
  },
  computed: {
    options() {
      return this.items.map(toOption);
    },
  },
  methods: {
    onSet(id) {
      if (id !== this.value) {
        this.$emit('input', id);
      }
    },
  },
};
</script>

<style>
.radio-field .option > * {
  cursor: pointer;
}
</style>