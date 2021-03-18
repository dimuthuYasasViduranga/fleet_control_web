<template>
  <div class="select-modal">
    <SearchBar v-if="useSearch" v-model="searchText" />
    <div class="items">
      <div
        class="item"
        v-for="item in filteredItems"
        :key="item[keyName]"
        :class="{ highlight: item[keyName] === highlight, [item.class]: true }"
        @click="onItemClick(item)"
      >
        {{ item[label] }}
      </div>
    </div>
  </div>
</template>

<script>
import fuzzysort from 'fuzzysort';
import SearchBar from '@/components/SearchBar.vue';

function toItem(value, key, label) {
  if (['string', 'number'].includes(typeof value)) {
    return {
      [key]: value,
      [label]: value,
    };
  }
  return value;
}

export default {
  name: 'SelectModal',
  wrapperClass: 'select-modal-wrapper',
  components: {
    SearchBar,
  },
  props: {
    highlight: { type: [String, Number] },
    options: { type: Array, default: () => [] },
    label: { type: String, default: 'name' },
    keyName: { type: String, default: 'id' },
    useSearch: { type: Boolean, default: true },
  },
  data: () => {
    return {
      searchText: '',
    };
  },
  computed: {
    items() {
      return this.options.map(o => toItem(o, this.keyName, this.label));
    },
    filteredItems() {
      if (!this.searchText) {
        return this.items;
      }
      return fuzzysort.go(this.searchText, this.items, { key: this.label }).map(r => r.obj);
    },
  },
  methods: {
    onItemClick(item) {
      this.$emit('close', item);
    },
  },
};
</script>

<style>
</style>

<style>
.select-modal-wrapper .modal-container {
  max-width: 32rem;
}

.select-modal .search-bar {
  height: 2.5rem;
  font-size: 1.5rem;
}

.select-modal .items {
  margin-top: 1rem;
}

.select-modal .item {
  font-size: 1.4rem;
  cursor: pointer;
  height: 2rem;
  line-height: 2rem;
  padding: 0.2rem;
}

.select-modal .item:hover,
.select-modal .item.highlight {
  background-color: #09819c;
  color: #b6c3cc;
}
</style>