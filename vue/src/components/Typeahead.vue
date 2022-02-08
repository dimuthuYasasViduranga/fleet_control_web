<template>
  <div class="typeahead">
    <DropDown
      :appendToBody="appendToBody"
      :value="value"
      :options="options"
      :filter="filter"
      :placeholder="placeholder"
      :clearable="clearable"
      :useTouch="useTouch"
      :valueIsObj="true"
      @input="onInput"
    >
      <template slot-scope="option">
        <div :class="{ 'add-new': isAddNew(option) }">{{ getOptionLabel(option) }}</div>
      </template>
    </DropDown>
  </div>
</template>

<script>
import { DropDown } from 'hx-vue';
import { orderedFuzzySort } from '@/code/sort';

function toComparableOption(option, keyLabel) {
  if (typeof option === 'string' || option == null) {
    return { cmp: option || '', option };
  }
  return { cmp: option[keyLabel] || '', option };
}

function fuzzyFilter(options, search, ctx) {
  if (!search) {
    return options;
  }

  const items = options.map(o => toComparableOption(o, ctx.keyLabel));

  return orderedFuzzySort(search, items, 'cmp');
}

export default {
  name: 'Typeahead',
  components: {
    DropDown,
  },
  props: {
    value: { type: String },
    keyId: { type: String, default: 'id' },
    keyLabel: { type: String, default: 'label' },
    options: { type: Array, default: () => [] },
    appendToBody: { type: Boolean },
    placeholder: { type: String },
    clearable: { type: Boolean, default: false },
    useTouch: { type: [String, Boolean], default: 'auto' },
  },
  methods: {
    filter(options, search, ctx) {
      const filteredOptions = fuzzyFilter(options, search, ctx);

      const hasExactMatch = filteredOptions.some(o => this.getOptionLabel(o) === search);

      if (hasExactMatch || !search) {
        return filteredOptions;
      }

      const addNew = {
        [this.keyId]: undefined,
        [this.keyLabel]: `Add: ${search}`,
        $value: search,
        $new: true,
      };

      return [addNew].concat(filteredOptions);
    },
    getOptionLabel(option) {
      return typeof option === 'object' ? option[this.keyLabel] : option;
    },
    isAddNew(option) {
      return typeof option === 'object' && option.$new;
    },
    onInput(option) {
      if (option && typeof option === 'object' && option.$new === true) {
        const newValue = option.$value.trim();

        this.$emit('input', newValue);
        this.$emit('new', newValue);
        return;
      }

      this.$emit('input', option);
    },
  },
};
</script>

<style>
.typeahead {
  font-family: 'GE Inspira Sans', sans-serif;
  background-color: #1a2931;
  border: 1px solid #677e8c;
}

.typeahead .drop-down {
  border: none;
}

.vs__dropdown-menu .add-new {
  font-style: italic;
}
</style>