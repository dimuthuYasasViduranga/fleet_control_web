<template>
  <div class="gmap-dropdown">
    <DropDown
      class="g-drop-down"
      :placeholder="placeholder"
      v-bind="$props"
      @input="propogate('input', $event)"
      @change="propogate('change', $event)"
    />
    <div class="x" @click="onClear">x</div>
  </div>
</template>

<script>
import { DropDown } from 'hx-vue';
export default {
  name: 'GMapDropDown',
  components: {
    DropDown,
  },
  props: {
    value: Number,
    placeholder: { type: String, default: 'Select' },
    keyId: { type: String, default: 'id' },
    label: { type: String, default: 'name' },
    options: { type: Array, default: () => [] },
    useTouch: Boolean,
    searchable: { type: Boolean, default: true },
    direction: { type: String, default: 'auto' },
  },
  methods: {
    propogate(name, value) {
      this.$emit(name, value);
    },
    onClear() {
      this.$emit('input', null);
      this.$emit('change', null);
    },
  },
};
</script>

<style>
.gmap-dropdown {
  display: flex;
  width: 100%;
  height: 100%;
}

.gmap-dropdown .drop-down {
  width: 100%;
}

.g-drop-down .v-select {
  background-color: transparent;
  height: 100%;
}

.g-drop-down .vs__dropdown-menu {
  background-color: white;
  font-family: Roboto, Arial, sans-serif;
  font-weight: 500;
}

.g-drop-down .dd-option {
  font-family: Roboto, Arial, sans-serif;
  font-weight: 500;
  color: black;
  height: 2rem;
  line-height: 2rem;
}

.g-drop-down .vs__search {
  font-family: Roboto, Arial, sans-serif;
  font-weight: 500;
  color: black;
  text-align: center;
}

.g-drop-down .vs__selected {
  font-family: Roboto, Arial, sans-serif;
  font-weight: 500;
  color: black;
}

.g-drop-down .vs__search::placeholder {
  opacity: 1;
}

.g-drop-down .vs__dropdown-toggle {
  border: none;
}

.g-drop-down .vs__dropdown-option--selected,
.g-drop-down .vs__dropdown-option--highlight,
.g-drop-down .vs__dropdown-option:hover {
  background-color: #bebebe;
}

.gmap-dropdown .x {
  width: 2rem;
  font-size: 1.2rem;
}

.gmap-dropdown .x:hover {
  color: gray;
}
</style>