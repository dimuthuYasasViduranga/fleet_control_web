<template>
  <div class="gmap-dropdown">
    <DropDown
      v-bind="$props"
      @input="propogate('input', $event)"
      @change="propogate('change', $event)"
    />
    <div class="x" @click="onClear">x</div>
  </div>
</template>

<script>
import DropDown from '../dropdown/DropDown.vue';
export default {
  name: 'GMapDropDown',
  components: {
    DropDown,
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
    direction: { type: String, default: 'auto' },
    useScrollLock: { type: Boolean, default: true },
    value: Number,
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
  padding-bottom: 2px;
}

.gmap-dropdown .dropdown-wrapper {
  height: 100%;
  width: 100%;
  background-color: white;
}

.gmap-dropdown .dropdown-wrapper .sdd-wrapper .input-wrapper {
  margin-top: -1px;
  height: calc(100% + 1px);
}

.gmap-dropdown .caret-down {
  border-top-color: black;
}

.gmap-dropdown .dd-button {
  color: black;
  text-align: center;
}

.gmap-dropdown .sdd-wrapper .dd-option {
  background-color: whitesmoke;
  color: black;
}

.gmap-dropdown .sdd-wrapper .dd-option:hover {
  border-color: transparent;
  box-shadow: none;
  background-color: rgb(190, 190, 190);
}

.gmap-dropdown .sdd-wrapper input,
.gmap-dropdown .sdd-wrapper button {
  background-color: white;
  color: black;
}

.gmap-dropdown .x {
  width: 2rem;
  font-size: 1.2rem;
}

.gmap-dropdown .x:hover {
  color: gray;
}
</style>