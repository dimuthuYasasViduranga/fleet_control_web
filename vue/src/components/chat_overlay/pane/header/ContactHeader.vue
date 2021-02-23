<template>
  <div class="contact-header">
    <SearchBar class="contact-search-bar" v-model="search" />
    <div class="live-feed">
      <button class="select" :class="liveFeedClass" @click="onLiveFeed">Live Feed</button>
    </div>
  </div>
</template>

<script>
import SearchBar from '../../../SearchBar.vue';

export default {
  name: 'ContactHeader',
  components: {
    SearchBar,
  },
  props: {
    highlightLiveFeed: { type: Boolean, default: false },
  },
  data: () => {
    return {
      search: '',
    };
  },
  computed: {
    liveFeedClass() {
      if (this.highlightLiveFeed === true) {
        return 'highlight';
      }
      return '';
    },
  },
  watch: {
    search(newText) {
      this.$emit('search-change', newText);
    },
  },
  methods: {
    onLiveFeed() {
      this.$emit('live-feed');
    },
  },
};
</script>

<style>
@import '../../../../assets/hxInput.css';

.contact-header .live-feed {
  height: 2rem;
  padding: 0.25rem;
}

.live-feed .select {
  width: 100%;
  height: 100%;
  border: 1px solid transparent;
  background-color: #425866;
  color: white;
  overflow: hidden;
  border: none;
  outline: none;
  cursor: pointer;
}

.live-feed .select:hover {
  box-shadow: none;
  background-color: #2c404c;
  transition: background 0.4s, border-color 0.4s, color 0.4s;
}

.live-feed .highlight {
  border: 2px solid #b6c3cc;
}

.contact-search-bar {
  height: 2rem;
}

.contact-search-bar.search-bar {
  margin: 0.5rem;
}
</style>