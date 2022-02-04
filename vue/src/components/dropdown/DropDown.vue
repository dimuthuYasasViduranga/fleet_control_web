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
    appendToBody: { type: [Boolean, String], default: false },
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
.drop-down {
  font-family: 'GE Inspira Sans', sans-serif;
  background-color: #1a2931;
  border: 1px solid #677e8c;
}

.drop-down .v-select,
.drop-down .drop-down-standard,
.drop-down .drop-down-touch {
  height: 100%;
}

.drop-down .vs--disabled {
  background-color: #142025;
  border-color: gray;
}

.drop-down .vs__clear {
  background-color: transparent;
}

.drop-down .vs__dropdown-toggle {
  border-radius: 0;
  background-color: transparent;
  height: 100%;
}

.drop-down .vs__dropdown-toggle .vs__selected-options {
  flex-wrap: nowrap;
  overflow: hidden;
}

.drop-down .vs__search {
  color: #b6c3cc;
}

.drop-down input.vs__search::placeholder {
  opacity: 0.5;
}

.drop-down .vs__search[disabled] {
  background-color: transparent;
  color: #b3b2b2;
  font-style: italic;
}

.drop-down .vs__selected {
  color: #b6c3cc;
  background-color: transparent;
  border: none;
  white-space: nowrap;
}

/* controls action colors (clear and dropdown icon) */
.drop-down .vs__actions svg {
  fill: #9aa7b1;
  background-color: transparent;
}

/* loading icon */
.drop-down .vs__spinner {
  height: 1.5rem;
  width: 1.5rem;
  border-color: #b5e5fd;
  border-left-color: #007acc;
  border-width: 3px;
}

/* dropdown menu */
.vs__dropdown-menu {
  font-family: 'GE Inspira Sans', sans-serif;
  width: 100%;
  background-color: #23343f;
  border: 1px solid #b6c3cc;
  border-radius: 0;
  padding: 0;
  max-height: 35vh;
  z-index: 9999;
}

.vs__dropdown-menu .vs__dropdown-option {
  color: #b6c3cc;
}

.vs__dropdown-menu .vs__dropdown-option--highlight,
.vs__dropdown-menu .vs__dropdown-option:hover {
  background-color: #08657a;
}

.vs__dropdown-menu .vs__no-options {
  line-height: 2rem;
  color: #b6c3cc;
  font-style: italic;
}
</style>