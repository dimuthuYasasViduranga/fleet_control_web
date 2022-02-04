<template>
  <div class="drop-down-touch v-select" :class="classAnchor">
    <DropDownTouchWrapper
      v-if="showModal"
      :classAnchor="classAnchor"
      v-bind="$props"
      @close="onClose()"
      @select="onSelect"
      @search="onSearchChange"
    >
      <template slot="option" slot-scope="slotData">
        <slot name="option" v-bind="normalizeOptionForSlot(slotData)">
          {{ getOptionLabel(slotData) }}
        </slot>
      </template>
    </DropDownTouchWrapper>
    <div class="vs__dropdown-toggle" @click="onOpen()">
      <div class="vs__selected-options">
        <span v-if="value" class="vs__selected">{{ getOptionLabel(value) }}</span>
        <input
          ref="search"
          class="vs__search"
          v-bind="scope.search.attributes"
          :placeholder="value ? '' : placeholder"
          @focus="onFocus()"
        />
      </div>
      <div class="vs__actions" ref="actions">
        <button
          v-show="value && clearable"
          type="button"
          title="Clear Selected"
          aria-label="Clear Selected"
          class="vs__clear"
          :disabled="disabled"
          @click.stop="clearSelection()"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
            <path
              d="M6.895455 5l2.842897-2.842898c.348864-.348863.348864-.914488 0-1.263636L9.106534.261648c-.348864-.348864-.914489-.348864-1.263636 0L5 3.104545 2.157102.261648c-.348863-.348864-.914488-.348864-1.263636 0L.261648.893466c-.348864.348864-.348864.914489 0 1.263636L3.104545 5 .261648 7.842898c-.348864.348863-.348864.914488 0 1.263636l.631818.631818c.348864.348864.914773.348864 1.263636 0L5 6.895455l2.842898 2.842897c.348863.348864.914772.348864 1.263636 0l.631818-.631818c.348864-.348864.348864-.914489 0-1.263636L6.895455 5z"
            />
          </svg>
        </button>

        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="14"
          height="10"
          role="presentation"
          class="vs__open-indicator"
        >
          <path
            d="M9.211364 7.59931l4.48338-4.867229c.407008-.441854.407008-1.158247 0-1.60046l-.73712-.80023c-.407008-.441854-1.066904-.441854-1.474243 0L7 5.198617 2.51662.33139c-.407008-.441853-1.066904-.441853-1.474243 0l-.737121.80023c-.407008.441854-.407008 1.158248 0 1.600461l4.48338 4.867228L7 10l2.211364-2.40069z"
          />
        </svg>
      </div>
    </div>
  </div>
</template>

<script>
import DropDownTouchWrapper from './DropDownTouchWrapper.vue';

export default {
  name: 'DropDownTouch',
  components: {
    DropDownTouchWrapper,
  },
  props: {
    value: { type: [String, Number, Object], default: null },
    appendToBody: { type: [Boolean, String], default: false },
    keyLabel: { type: String, default: 'label' },
    keyId: { type: String, default: 'id' },
    options: { type: [Array, Function], default: () => [] },
    placeholder: { type: String },
    search: { type: String, default: '' },
    searchable: { type: Boolean, default: true },
    selectable: { type: Function },
    inputId: { type: String },
    inputTabIndex: { type: Number },
    clearable: { type: Boolean, default: true },
    alignment: { type: String, default: 'ltr' },
    disabled: { type: Boolean, default: false },
    disabledOnNoOptions: { type: Boolean, default: false },
    filter: { type: [String, Function], default: 'fuzzy' },
    filterable: { type: Boolean, default: true },
    paginationSize: { type: Number, default: Infinity },
    classAnchor: { type: String },
    ignoreMobileComposition: { type: Boolean, default: true },
  },
  data: () => {
    return {
      showModal: false,
    };
  },
  computed: {
    scope() {
      return {
        search: {
          attributes: {
            disabled: this.disabled || (this.disabledOnNoOptions && this.options.length === 0),
            placeholder: this.placeholder,
            tabindex: this.inputTabIndex,
            id: this.inputId,
            'aria-autocomplete': 'list',
            ref: 'search',
            type: 'search',
          },
        },
      };
    },
  },
  methods: {
    onOpen() {
      this.showModal = true;
    },
    onClose() {
      this.showModal = false;
    },
    onSelect(option) {
      this.$emit('input', option);
    },
    onFocus() {
      this.onOpen();
      this.$refs.search.blur();
    },
    clearSelection() {
      this.onSelect();
    },
    onSearchChange(value) {
      this.$emit('update:search', value);
    },
    normalizeOptionForSlot(option) {
      return typeof option === 'object' ? option : { [this.keyLabel]: option };
    },
    getOptionLabel() {
      return typeof this.value === 'object' ? this.value[this.keyLabel] : this.value;
    },
  },
};
</script>