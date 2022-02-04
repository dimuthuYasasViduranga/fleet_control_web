<template>
  <div ref="self" class="drop-down-standard">
    <DropDownStandardBase
      ref="base"
      :value="value"
      :label="keyLabel"
      :appendToBody="appendToBody"
      :options="options"
      :placeholder="placeholder"
      :searchable="searchable"
      :selectable="selectable"
      :inputId="inputId"
      :tabIndex="inputTabIndex"
      :clearable="clearable"
      :dir="alignment"
      :disabled="disabled"
      :filterable="false"
      :selectOnTab="selectOnTab"
      :ignoreMobileComposition="ignoreMobileComposition"
      autocomplete="nope"
      v-bind="bindings"
      @input="onInputChange"
      @open="onOpen"
      @close="onClose"
      @option:selecting="up('option:selecting', $event)"
      @option:selected="up('option:selected', $event)"
      @option:deselecting="up('option:deselecting', $event)"
      @option:deselected="up('option:deselecting', $event)"
      @option:created="up('option:create', $event)"
      @search="onSearch"
      @search:blur="up('search:blur', $event)"
      @search:focus="up('search:focus', $event)"
      @click.native.stop
    >
      <template slot="option" slot-scope="slotData">
        <slot name="option" v-bind="slotData"></slot>
      </template>
      <template #spinner>
        <div v-if="loading" class="vs__spinner async-spinner"></div>
      </template>
    </DropDownStandardBase>
  </div>
</template>

<script>
import DropDownStandardBase from './DropDownStandardBase.vue';

export default {
  name: 'DropDownStandard',
  components: {
    DropDownStandardBase,
  },
  props: {
    value: { type: [String, Number, Object], default: null },
    appendToBody: { type: [Boolean, String], default: false },
    keyLabel: { type: String, default: 'label' },
    keyId: { type: String, default: 'id' },
    options: { type: Array, default: () => [] },
    placeholder: { type: String },
    searchable: { type: Boolean, default: true },
    selectable: { type: Function },
    inputId: { type: String },
    inputTabIndex: { type: Number },
    clearable: { type: Boolean, default: true },
    alignment: { type: String, default: 'ltr' },
    disabled: { type: Boolean, default: false },
    disabledOnNoOptions: { type: Boolean, default: false },
    holdOpen: { type: Boolean, default: false },
    filter: { type: Function },
    filterable: { type: Boolean, default: true },
    paginationSize: { type: Number, default: Infinity },
    selectOnTab: { type: Boolean, default: false },
    ignoreMobileComposition: { type: Boolean, default: true },
    detectMobile: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
  },
  computed: {
    passedSlots() {
      return Object.entries(this.$scopedSlots).reduce((acc, [key, slot]) => {
        if (key !== 'no-options') {
          acc[key] = slot;
        }
        return acc;
      }, {});
    },
    bindings() {
      const opts = {};
      if (this.holdOpen) {
        opts.dropdownShouldOpen = () => true;
      }
      return opts;
    },
  },
  methods: {
    up(name, payload) {
      this.$emit(name, payload);
    },
    onInputChange(value) {
      this.$emit('input', value);
    },
    onSearch(search) {
      this.$emit('update:search', search);
    },
    onOpen(event) {
      this.$emit('open', event);
    },
    onClose(event) {
      this.$emit('close', event);
    },
  },
};
</script>

<style>
.drop-down-standard .vs__spinner.async-spinner {
  opacity: 1;
  margin-left: 0.25rem;
}
</style>