<template>
  <Button
    v-if="circular"
    class="toggle-btn"
    :text="circularText"
    :disabled="disabled"
    :textTransform="textTransform"
    @tap="nextOption"
  />
  <FlexboxLayout class="toggle" v-else>
    <Button
      class="toggle-btn"
      :width="width"
      v-for="(option, index) in formattedOptions"
      :key="index"
      :class="{ selected: value === option.id }"
      :text="option.text"
      :disabled="disabled"
      :textTransform="textTransform"
      @tap="set(option)"
    />
  </FlexboxLayout>
</template>

<script>
import { attributeFromList } from '../code/helper';
function toOption(option) {
  if (typeof option === 'string') {
    return { id: option, text: option };
  }
  return option;
}

export default {
  name: 'Toggle',
  props: {
    value: undefined,
    circular: { type: Boolean, default: false },
    options: { type: Array, default: () => [] },
    textTransform: { type: String, default: 'capitalize' },
    disabled: { type: Boolean, default: false },
  },
  computed: {
    formattedOptions() {
      return this.options.map(toOption);
    },
    width() {
      return `${(100 / this.options.length + 1).toFixed(3)}%`;
    },
    circularText() {
      return attributeFromList(this.formattedOptions, 'id', this.value, 'text');
    },
  },
  methods: {
    set(option) {
      this.$emit('input', option.id);
    },
    nextOption() {
      const options = this.formattedOptions;
      const length = options.length;
      if (length < 2) {
        return null;
      }

      let nextIndex = options.findIndex(o => o.id === this.value) + 1;
      if (nextIndex >= length) {
        nextIndex = 0;
      }

      this.$emit('input', options[nextIndex].id);
    },
  },
};
</script>

<style>
.toggle .selected {
  background-color: lightslategray;
  color: white;
}
</style>