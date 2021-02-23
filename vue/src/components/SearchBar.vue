<template>
  <div class="search-bar">
    <input class="search typeable" type="text" :placeholder="placeholder" v-model="localText" />
    <div v-if="showClear" class="close-x-wrapper" @click="clear">
      <div class="close-x">x</div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SearchBar',
  props: {
    text: { type: String, default: '' },
    placeholder: { type: String, default: 'Search' },
    showClear: { type: Boolean, default: true },
  },
  model: {
    event: 'change',
  },
  data: () => {
    return {
      localText: '',
    };
  },
  watch: {
    text: {
      immediate: true,
      handler(newText) {
        if (!newText) {
          this.localText = '';
        } else {
          this.localText = newText;
        }
      },
    },
    localText: {
      immediate: true,
      handler(newText) {
        this.emitText(newText);
      },
    },
  },
  methods: {
    clear() {
      this.emitText('');
      this.localText = '';
      this.$emit('clear');
    },
    emitText(value) {
      this.$emit('change', value);
    },
  },
};
</script>

<style>
.search-bar {
  height: 2rem;
  display: flex;
  height: 100%;
}

.search-bar .close-x-wrapper {
  display: flex;
  align-items: center;
  padding: 0 0.5rem;
  border-bottom: 1px solid #677e8c;
  cursor: pointer;
  user-select: none;
}

.search-bar .close-x {
  color: #b6c3cc;
}

.search-bar .search {
  resize: none;
  overflow: hidden;
  width: 100%;
  height: 100%;
}

.search-bar .search::-ms-clear {
  display: none;
}
</style>