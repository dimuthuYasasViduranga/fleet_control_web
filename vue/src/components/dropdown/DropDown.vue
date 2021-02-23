<template>
  <div class="dropdown-wrapper">
    <div class="dd-right">
      <div class="caret-down"></div>
    </div>
    <div class="dd-body">
      <standardDropdown
        v-if="!useTouch"
        :value="value"
        :items="items"
        :keyName="keyName"
        :label="label"
        :placeholder="placeholder"
        :maxItems="maxItems"
        :searchable="searchable"
        :autofocus="autofocus"
        :useScrollLock="useScrollLock"
        :direction="direction"
        @input="modelEmit"
      />
      <touchDropdown
        v-else
        :value="value"
        :items="items"
        :keyName="keyName"
        :label="label"
        :placeholder="placeholder"
        :maxItems="maxItems"
        :searchable="searchable"
        :autofocus="autofocus"
        :useScrollLock="useScrollLock"
        @input="modelEmit"
      />
    </div>
  </div>
</template>

<script>
import standardDropdown from './StandardDropdown.vue';
import touchDropdown from './TouchDropdown.vue';

function objEqual(obj1, obj2) {
  return JSON.stringify(obj1) === JSON.stringify(obj2);
}

export default {
  name: 'DropDown',
  components: {
    touchDropdown,
    standardDropdown,
  },
  props: {
    placeholder: { type: String, default: 'Select' },
    keyName: { type: String, default: 'id' },
    label: { type: String, default: 'name' },
    items: { type: Array, default: () => [] },
    useTouch: { type: Boolean, default: false },
    maxItems: { type: Number, default: Infinity },
    autofocus: { type: Boolean, default: true },
    searchable: { type: Boolean, default: true },
    direction: {type: String, default: 'auto'},
    useScrollLock: {type: Boolean, default: true},
    value: [Number, String],
  },
  data: () => {
    return {
      selected: null,
    };
  },
  methods: {
    modelEmit(event) {
      // Determine if there has been a change
      const hasChanged = !objEqual(this.selected, event.selected);

      // set local params
      this.selected = (event.selected || {})[this.keyName];

      // only emit selected to parent
      const data = this.selected;
      this.$emit('input', data);

      if (hasChanged) {
        this.$emit('change', data);
      }
    },
  },
};
</script>

<style>
.dropdown-wrapper {
  display: inline-block;
  position: relative;
  height: 2rem;
  min-width: 2rem;
  background-color: #425866;
  cursor: pointer;
  padding: 0;
  margin: 0;
}

.dropdown-wrapper:hover {
  border-color: transparent;
  box-shadow: none;
  background-color: #2c404c;
}

.dropdown-wrapper .dd-body {
  position: relative;
  width: 100%;
  height: 100%;
  padding-right: 1rem;
}

.dropdown-wrapper .dd-right {
  position: absolute;
  right: 0;
  top: calc(50% - 3px);
  width: 1rem;
}

.dropdown-wrapper .caret-down {
  width: 0;
  height: 0;
  border-left: 3px solid transparent;
  border-right: 3px solid transparent;
  border-top: 7px solid white;
  margin: 0 auto;
}
</style>


