<template>
  <div class="drop-down" @esc.stop @keyup="onBlockEsc">
    <DropDownTouch
      v-if="isTouch && !isDisabled"
      :search.sync="search"
      :value="foundValue"
      v-bind="mobileBindings"
      :options="filteredOptions"
      @input="onInput"
    >
      <template slot="option" slot-scope="slotData">
        <slot v-bind="normalizeOptionForSlot(slotData)">{{ getOptionLabel(slotData) }}</slot>
      </template>
    </DropDownTouch>
    <DropDownStandard
      v-else
      :value="foundValue"
      v-bind="$props"
      :search.sync="search"
      :disabled="isDisabled"
      :options="filteredOptions"
      :position="position"
      @input="onInput"
    >
      <template slot="option" slot-scope="slotData">
        <slot v-bind="normalizeOptionForSlot(slotData)">{{ getOptionLabel(slotData) }}</slot>
      </template>
    </DropDownStandard>
  </div>
</template>

<script>
import DropDownStandard from './DropDownStandard.vue';
import DropDownTouch from './DropDownTouch.vue';

import fuzzysort from 'fuzzysort';

const MOBILE_PROPS = [
  'value',
  'keyLabel',
  'keyId',
  'options',
  'placeholder',
  'searchable',
  'inputId',
  'inputTabIndex',
  'clearable',
  'disabled',
  'disabledOnNoOptions',
  'filter',
  'paginationSize',
  'ignoreMobileComposition',
];

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
  return fuzzysort.go(search, items, { key: 'cmp' }).map(r => r.obj.option);
}

function isTouchDevice() {
  return 'ontouchstart' in window || navigator.maxTouchPoints > 0 || navigator.msMaxTouchPoints > 0;
}

export default {
  name: 'DropDown',
  components: {
    DropDownStandard,
    DropDownTouch,
  },
  props: {
    value: { type: [String, Number, Object], default: null },
    useTouch: { type: [Boolean, String], default: 'auto' },
    keyLabel: { type: String, default: 'label' },
    keyId: { type: String, default: 'id' },
    options: { type: Array, default: () => [] },
    placeholder: { type: String },
    searchable: { type: Boolean, default: true },
    selectable: { type: Function },
    inputId: { type: String },
    inputTabIndex: { type: Number },
    clearable: { type: Boolean, default: true },
    disabled: { type: Boolean, default: false },
    disabledOnNoOptions: { type: Boolean, default: false },
    holdOpen: { type: Boolean, default: false },
    filter: { type: Function, default: fuzzyFilter },
    filterable: { type: Boolean, default: true },
    paginationSize: { type: Number, default: Infinity },
    selectOnTab: { type: Boolean, default: false },
    ignoreMobileComposition: { type: Boolean, default: true },
    position: { type: [Boolean, String], default: 'auto' },
    loading: { type: Boolean, default: false },
    valueIsId: { type: Boolean, default: false },
  },
  data: () => {
    return {
      search: '',
      isMobile: isTouchDevice(),
    };
  },
  computed: {
    foundValue() {
      if (this.valueIsId && this.value && typeof this.value !== 'object') {
        return this.options.find(o => {
          if (typeof o === 'object') {
            return o[this.keyId] === this.value;
          }

          return o === this.value;
        });
      }

      return this.value;
    },
    mobileBindings() {
      return MOBILE_PROPS.reduce((acc, key) => {
        acc[key] = this[key];
        return acc;
      }, {});
    },
    isTouch() {
      if (this.useTouch === 'auto') {
        return this.isMobile;
      }

      return this.useTouch;
    },
    filteredOptions() {
      return this.filter(this.options, this.search, this);
    },
    isDisabled() {
      return this.disabled || (this.options.length === 0 && this.disabledOnNoOptions);
    },
  },
  methods: {
    onInput(event) {
      this.search = '';

      let payload = event;
      if (this.valueIsId && event && typeof event === 'object') {
        payload = event[this.keyId];
      }
      this.$emit('input', payload);
    },
    normalizeOptionForSlot(option) {
      return typeof option === 'object' ? option : { [this.keyLabel]: option };
    },
    getOptionLabel(option) {
      return typeof option === 'object' ? option[this.keyLabel] : option;
    },
    onBlockEsc(event) {
      if (event.key === 'Escape' || event.key === 'Esc') {
        event.stopPropagation();
      }
    },
  },
};
</script>

<style>
</style>