<template>
  <div
    ref="dd-container"
    class="sdd-wrapper"
    :class="{ open: showDropdown, closed: !showDropdown }"
  >
    <div class="dd-button-wrapper" :class="selectedItem.class" @click="openDropdown">
      <span class="dd-button">{{ selectedName }}</span>
    </div>
    <div
      v-show="showDropdown"
      ref="dd-context"
      class="fixed-div"
      :style="`top: ${top}; bottom: ${bottom}; width: ${width}; left: ${left}`"
      @wheel.stop
    >
      <ul class="dd-option-list">
        <span
          class="dd-option"
          v-for="option in results"
          :key="option[keyName]"
          :class="getOptionClasses(option)"
          @click="selectOption(option)"
        >
          {{ option[label] }}
        </span>

        <span v-if="noResults" class="dd-option">No Results</span>
      </ul>
    </div>
    <div v-if="showDropdown" class="click-intercept" @click="closeDropdown" @wheel="onWheel"></div>
    <template v-if="showDropdown">
      <div v-if="searchable" class="input-wrapper">
        <input
          :class="{ 'dd-input-active': showDropdown }"
          class="dd-typeable"
          placeholder="select"
          type="text"
          :value="search"
          @input="onInputChange"
        />
        <button class="x-button" @click="clearSearch">x</button>
      </div>
    </template>
  </div>
</template>

<script>
import { attributeFromList } from '../../code/helpers';
import fuzzysort from 'fuzzysort';

function toPx(val) {
  return `${val}px`;
}
export default {
  name: 'StandardDropdown',
  props: {
    placeholder: { type: String, default: 'Select' },
    keyName: { type: String, default: 'id' },
    label: { type: String, default: 'name' },
    selectedLabel: String,
    items: { type: Array, default: () => [] },
    maxItems: { type: Number, default: Infinity },
    autofocus: { type: Boolean, default: true },
    searchable: { type: Boolean, default: true },
    direction: { type: String, default: 'auto' },
    useScrollLock: { type: Boolean, default: true },
    value: [Number, String],
  },
  data: () => {
    return {
      showDropdown: false,
      search: '',
      results: [],
      originalPos: { x: 0, y: 0 },
      windowPercentage: {
        vertical: 0,
      },
      left: null,
      bottom: null,
      top: null,
      width: null,
    };
  },
  computed: {
    selectedItem() {
      return attributeFromList(this.items, this.keyName, this.value) || {};
    },
    selectedName() {
      return this.selectedItem[this.selectedLabel || this.label] || this.placeholder;
    },
    noResults() {
      return this.results.length === 0;
    },
    extendUp() {
      if (this.direction === 'up') {
        return true;
      }
      if (this.direction === 'down') {
        return false;
      }

      return this.windowPercentage.vertical > 0.5;
    },
  },
  beforeDestroy() {
    this.disableScrollLock();
  },
  methods: {
    onWheel() {
      this.closeDropdown();
    },
    openDropdown() {
      this.setWindowPercentage();
      window.addEventListener('resize', this.setWindowPercentage);

      setTimeout(() => {
        const ddContainer = this.$refs['dd-container'].getBoundingClientRect();
        this.width = toPx(ddContainer.width);

        if (this.extendUp) {
          const bottom = window.innerHeight - window.scrollX - ddContainer.top;
          this.bottom = toPx(bottom);
          this.top = null;
        } else {
          const top = ddContainer.top + ddContainer.height;
          this.bottom = null;
          this.top = toPx(top);
        }

        this.left = toPx(ddContainer.left);
      });

      // Set default results if nothing has been set
      if (this.results === null) {
        this.results = this.items;
      }
      this.enableScrollLock();
      this.showDropdown = true;
      this.filterResults();

      if (this.autofocus) {
        this.focus();
      }
    },
    closeDropdown() {
      this.search = '';
      this.showDropdown = false;
      this.disableScrollLock();
      window.removeEventListener('resize', this.setWindowPercentage);
    },
    onInputChange(event) {
      this.search = event.target.value;
      this.filterResults();
    },
    filterResults() {
      if (!this.search) {
        this.results = this.items.slice(0, this.maxItems);
      } else {
        this.results = fuzzysort
          .go(this.search, this.items, { limit: this.maxItems, key: this.label })
          .map(r => r.obj);
      }
    },
    selectOption(option) {
      if (option.disabled) {
        return;
      }

      this.modelEmit(option);
      this.closeDropdown();
    },
    modelEmit(selection) {
      const data = {
        selected: selection,
        search: this.search,
      };
      this.$emit('input', data);
    },
    getOptionClasses(option) {
      const isHighlighted = option[this.keyName] === this.value;
      const disabled = option.disabled;
      const extraClass = option.class;
      return {
        'dd-option-highlight': isHighlighted && !disabled,
        'dd-option-disabled': disabled,
        [extraClass]: true,
      };
    },
    clearSearch() {
      this.search = '';
      this.results = this.items.slice(0, this.maxItems);
      this.focus();
    },
    enableScrollLock() {
      if (this.useScrollLock) {
        // Set the return position
        this.originalPos = {
          x: window.pageXOffset,
          y: window.pageYOffset,
        };

        const curWidth = document.body.getBoundingClientRect().right;
        const bodyStyle = document.body.style;
        bodyStyle.position = 'fixed';
        bodyStyle.top = `${-this.originalPos.y}px`;
        bodyStyle.left = `${-this.originalPos.x}px`;
        bodyStyle.width = `${curWidth}px`;
      }
    },
    disableScrollLock() {
      if (this.useScrollLock) {
        const body = document.body.style;
        body.position = '';
        body.top = '';
        body.left = '';
        body.width = '';
        window.scrollTo(this.originalPos.x, this.originalPos.y);
      }
    },
    focus() {
      setTimeout(() => {
        const input = document.getElementsByClassName('dd-input-active')[0];
        if (input) {
          input.focus();
        }
      });
    },
    setWindowPercentage() {
      const yPos = this.$el.getBoundingClientRect().top;
      const yMax = window.innerHeight;
      const verticalPercent = yPos / yMax;

      this.windowPercentage = {
        vertical: verticalPercent,
        horizontal: 0,
      };
    },
  },
};
</script>

<style>
.click-intercept {
  position: fixed;
  top: 0;
  left: 0;
  bottom: 0;
  right: 0;
  height: 100%;
  width: 100%;
  z-index: 2;
}

.sdd-wrapper {
  display: inline-block;
  position: relative;
  width: calc(100% + 1rem);
  height: 100%;
  padding-right: 1rem;
}

.sdd-wrapper .fixed-div {
  position: fixed;
  cursor: default;
  min-width: 8rem;
  z-index: 4;
  z-index: 100;
}

.sdd-wrapper .dd-button-wrapper {
  display: grid;
  height: 100%;
  width: calc(100% + 1rem);
  padding-right: 1rem;
}

.sdd-wrapper .dd-button {
  overflow: hidden;
  white-space: nowrap;
  margin: auto 0;
  color: white;
  text-align: left;
  padding-left: 0.75rem;
}

.sdd-wrapper .input-wrapper {
  position: absolute;
  display: flex;
  flex-direction: row;
  top: 0;
  height: 100%;
  width: 100%;
  min-width: 8rem;
  z-index: 3;
}

.sdd-wrapper .dd-select {
  width: 100%;
  height: 100%;
  overflow-wrap: break-word;
  overflow: hidden;
  color: white;
  display: inline-block;
  border: 1px solid transparent;
  border-radius: 0 !important;
  box-shadow: none;
  font: inherit;
  min-height: 1.5rem;
  -webkit-font-smoothing: antialiased;
  cursor: pointer;
  text-align: left;
  text-decoration: none;
  text-transform: none;
  background-color: transparent;
}

.sdd-wrapper .button-overflow {
  overflow: hidden;
  white-space: nowrap;
  word-break: break-all;
  width: 100%;
}

.sdd-wrapper .x-button {
  border: none;
  background-color: #425866;
  font-size: 1rem;
  color: #b6c3cc;
  cursor: pointer;
  width: 30px;
}

.sdd-wrapper .dd-typeable {
  border: none;
  width: calc(100% - 30px);
  background-color: #425866;
  color: #b6c3cc;
  padding-left: 0.25rem;
  padding-bottom: 0.2rem;
  font-size: 1rem;
}

.sdd-wrapper .input-wrapper ::placeholder {
  color: #b6c3cc;
}

.sdd-wrapper .clear-option {
  color: transparent;
  background-color: transparent;
}

.sdd-wrapper .dd-select:focus,
.sdd-wrapper .dd-typeable,
.sdd-wrapper .x-button {
  outline: none;
}

.sdd-wrapper .dd-option-list {
  display: block;
  list-style: none;
  border: 1px solid #b6c3cc;
  margin: 0;
  padding: 0;
  width: 100%;
  min-width: 8rem;
  max-height: 20rem;
  overflow-x: hidden;
  overflow-y: auto;
  bottom: 0;
  left: 0;
}

.sdd-wrapper .dd-options {
  display: block;
  position: absolute;
  width: 100%;
  min-width: 8rem;
  z-index: 3;
}

.sdd-wrapper .dd-option {
  padding: 0.2rem 0.65rem;
  display: flex;
  background-color: #23343f;
  align-items: center;
  text-align: left;
  color: white;
}

.sdd-wrapper .dd-option:hover,
.sdd-wrapper .dd-option-highlight {
  background-color: #09819c;
}

.sdd-wrapper .dd-option-disabled {
  color: grey;
}

.sdd-wrapper .dd-option-disabled:hover {
  background-color: #23343f;
}
</style>
