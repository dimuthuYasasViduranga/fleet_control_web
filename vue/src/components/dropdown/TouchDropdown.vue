<template>
  <div class="touch-wrapper">
    <div class="dd-button-wrapper" :class="selectedItem.class" @click="openDropdown">
      <span class="dd-button">{{ selectedName }}</span>
    </div>
    <transition name="modal">
      <div class="modal-mask" v-show="showDropdown" @click="closeDropdown">
        <div class="modal-wrapper">
          <div class="modal-container" @click.stop>
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
            <span
              class="dd-option"
              v-for="option in results"
              :key="option[keyName]"
              :class="getClasses(option)"
              @click="selectOption(option)"
            >
              {{ option[label] }}
            </span>

            <span v-if="noResults" class="dd-option">No Results</span>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import { attributeFromList } from '../../code/helpers';
import { orderedFuzzySort } from '@/code/sort.js';

export default {
  name: 'TouchDropdown',
  props: {
    placeholder: { type: String, default: 'Select' },
    keyName: { type: String, default: 'id' },
    label: { type: String, default: 'name' },
    selectedLabel: String,
    items: { type: Array, default: () => [] },
    maxItems: { type: Number, default: Infinity },
    autofocus: { type: Boolean, default: true },
    searchable: { type: Boolean, default: true },
    useScrollLock: { type: Boolean, default: true },
    value: [Number, String],
  },
  data() {
    return {
      showDropdown: false,
      search: '',
      results: null,
      originalPos: { x: 0, y: 0 },
      oldHash: location.hash,
      oldOnPopState: window.onpopstate,
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
      if (this.results !== null && this.results.length === 0) {
        return true;
      }
      return false;
    },
  },
  methods: {
    openDropdown() {
      this.enableScrollLock();
      this.enableBackButton();

      if (this.results === null) {
        this.results = this.items;
      }
      this.showDropdown = true;
      this.filterResults();

      // set focus if required
      if (this.autofocus) {
        this.focus();
      }
    },
    closeDropdown() {
      this.search = '';
      this.showDropdown = false;

      this.disableBackButton();
      this.disableScrollLock();
    },
    enableScrollLock() {
      if (this.useScrollLock) {
        // Set the return position
        this.originalPos = {
          x: window.pageXOffset,
          y: window.pageYOffset,
        };

        const curWidth = document.body.getBoundingClientRect().right;
        const body = document.body.style;
        body.position = 'fixed';
        body.top = `${-this.originalPos.y}px`;
        body.left = `${-this.originalPos.x}px`;
        body.width = `${curWidth}px`;
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
    onInputChange(event) {
      this.search = event.target.value;
      this.filterResults();
    },
    filterResults() {
      if (!this.search) {
        this.results = this.items.slice(0, this.maxItems);
      } else {
        this.results = orderedFuzzySort(this.search, this.items, {
          limit: this.maxItems,
          key: this.label,
        });
      }
    },
    selectOption(option) {
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
    getClasses(option) {
      const isSelected = option[this.keyName] === this.value;
      const extraClass = option.class;
      return {
        'dd-option-highlight': isSelected,
        [extraClass]: true,
      };
    },
    clearSearch() {
      this.search = '';
      this.results = this.items.slice(0, this.maxItems);
      this.focus();
    },
    focus() {
      setTimeout(() => {
        const input = document.getElementsByClassName('dd-input-active')[0];
        if (input) {
          input.focus();
        }
      });
    },
    pushHistory(newHash) {
      if (history.pushState) {
        history.pushState(null, null, newHash);
      } else {
        location.hash = newHash;
      }
    },
    enableBackButton() {
      const newHash = this.oldHash + '-dd-active';
      this.pushHistory(newHash);

      window.onpopstate = () => {
        this.closeDropdown();
      };
    },
    disableBackButton() {
      window.onpopstate = this.oldOnPopState;
      this.pushHistory(this.oldHash);
    },
  },
};
</script>

<style>
@import '../../assets/hxInput.css';

/* ----------------------- mobile dropdown -------------------*/

.touch-wrapper {
  display: inline-block;
  position: relative;
  width: calc(100% + 1rem);
  height: 100%;
  padding-right: 1rem;
}

.touch-wrapper .dd-button-wrapper {
  display: grid;
  height: 100%;
  width: calc(100% + 1rem);
  padding-right: 1rem;
}

.touch-wrapper .dd-button {
  overflow: hidden;
  white-space: nowrap;
  margin: auto 0;
  color: white;
  text-align: left;
  padding-left: 0.75rem;
}

.touch-wrapper .dd-typeable {
  width: 100%;
  font-size: 1.5rem;
}

.touch-wrapper .input-wrapper {
  flex-direction: row;
  display: flex;
}

.touch-wrapper .x-button {
  border: none;
  background-color: transparent;
  font-size: 2em;
  color: #b6c3cc;
  cursor: pointer;
}

.touch-wrapper .dd-select {
  width: 100%;
  height: 100%;
  color: white;
  display: inline-block;
  overflow: hidden;
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

.touch-wrapper .dd-option {
  font-size: 1.4rem;
  min-height: 2em;
  padding: 0.6667rem;
  display: flex;
  background-color: #23343f;
  color: #b6c3cc;
  align-items: center;
  text-align: left;
}

.touch-wrapper .dd-option:hover,
.touch-wrapper .dd-option-highlight {
  background-color: #09819c;
  color: #b6c3cc;
}

.touch-wrapper .modal-mask {
  position: fixed;
  z-index: 9998;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  transition: opacity 0.3s ease;
  overflow: auto;
}

.touch-wrapper .modal-wrapper {
  vertical-align: middle;
  padding: 10% 10%;
  width: 100%;
}

.touch-wrapper .modal-container {
  width: 100%;
  height: 100%;
  margin: 0px auto;
  padding: 5px 5px;
  background-color: #23343f;
  border-radius: 2px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.33);
  transition: all 0.3s ease;
}

/* ---------------------- modal transitions -----------------------*/
.touch-wrapper .modal-enter {
  opacity: 0;
}

.touch-wrapper .modal-leave-active {
  opacity: 0;
}

.touch-wrapper .modal-enter .modal-container,
.touch-wrapper .modal-leave-active .modal-container {
  -webkit-transform: scale(1.1);
  transform: scale(1.1);
}
</style>
