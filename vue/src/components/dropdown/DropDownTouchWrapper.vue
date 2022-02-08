<template>
  <div class="drop-down-touch-wrapper" @click.stop="onClose()" @wheel.prevent>
    <div class="container" @click.stop @keyup.esc="onClose()">
      <div class="actions">
        <button type="button" class="vs__clear" @click.stop="onClose()">
          close
          <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
            <path
              d="M6.895455 5l2.842897-2.842898c.348864-.348863.348864-.914488 0-1.263636L9.106534.261648c-.348864-.348864-.914489-.348864-1.263636 0L5 3.104545 2.157102.261648c-.348863-.348864-.914488-.348864-1.263636 0L.261648.893466c-.348864.348864-.348864.914489 0 1.263636L3.104545 5 .261648 7.842898c-.348864.348863-.348864.914488 0 1.263636l.631818.631818c.348864.348864.914773.348864 1.263636 0L5 6.895455l2.842898 2.842897c.348863.348864.914772.348864 1.263636 0l.631818-.631818c.348864-.348864.348864-.914489 0-1.263636L6.895455 5z"
            />
          </svg>
        </button>
      </div>

      <div class="vs__dropdown-menu">
        <div class="search-wrapper">
          <input
            v-if="searchable"
            ref="search"
            class="vs__search"
            :placeholder="placeholder"
            :value="search"
            @input="onSearchChange"
          />
        </div>
        <PerfectScrollbar class="options" @wheel.stop>
          <div
            class="option-wrapper vs__dropdown-option"
            v-for="(option, index) in options"
            :key="index"
            @click="onSelect(option)"
          >
            <slot name="option" v-bind="normalizeOptionForSlot(option)">
              {{ getOptionLabel(option) }}
            </slot>
          </div>
        </PerfectScrollbar>
      </div>
    </div>
  </div>
</template>

<script>
import { PerfectScrollbar } from 'vue2-perfect-scrollbar';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';

export default {
  name: 'DropDownTouchWrapper',
  components: {
    PerfectScrollbar,
  },
  props: {
    keyLabel: { type: String, default: 'label' },
    search: { type: String, default: '' },
    searchable: { type: Boolean, default: true },
    options: { type: Array, default: () => [] },
    placeholder: { type: String },
    filter: { type: Function },
  },
  mounted() {
    if (this.searchable) {
      this.$refs.search.focus();
    }
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSelect(option) {
      this.$emit('select', option);
      this.onClose();
    },
    onSearchChange(event) {
      this.$emit('search', event.target.value);
    },
    normalizeOptionForSlot(option) {
      return typeof option === 'object' ? option : { [this.keyLabel]: option };
    },
    getOptionLabel(option) {
      return typeof option === 'object' ? option[this.keyLabel] : option;
    },
  },
};
</script>

<style>
.drop-down-touch-wrapper {
  line-height: 2rem;
  font-size: 1.25rem;
  padding: 2rem;
  position: fixed;
  height: 100vh;
  width: 100vw;
  top: 0;
  left: 0;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 999;
}

.drop-down-touch-wrapper .container {
  margin: auto !important;
  max-width: 30rem;
  padding: 1rem;
  background-color: #23343f;
}

.drop-down-touch-wrapper .vs__search {
  color: #b6c3cc;
  width: 100%;
  line-height: 2rem;
  padding: 0 0.5rem;
  background-color: #1a2931;
  border: 1px solid #677e8c;
}

.drop-down-touch-wrapper .options {
  margin-top: 1rem;
  overflow-x: auto;
  max-height: 80vh;
}

.drop-down-touch-wrapper .options .option-wrapper {
  cursor: pointer;
  padding: 0.5rem 0;
  border-bottom: 1px solid #1a2931;
}

.drop-down-touch-wrapper .actions button {
  font-size: 1rem;
  float: right;
  color: gray;
  fill: gray;
  margin-bottom: 0.2rem;
}

.drop-down-touch-wrapper .actions button:hover {
  opacity: 0.5;
}
</style>