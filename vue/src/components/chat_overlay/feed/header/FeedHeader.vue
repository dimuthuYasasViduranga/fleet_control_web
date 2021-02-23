<template>
  <div class="feed-header">
    <div class="feed-filter-wrapper">
      <FeedFilter @search-change="$emit('search-change', $event)" />
    </div>
    <div v-if="selectedDevice" class="asset-info-wrapper">
      <AssetInfo :device="selectedDevice" />
    </div>
  </div>
</template>

<script>
import FeedFilter from './FeedFilter.vue';
import AssetInfo from './AssetInfo.vue';

export default {
  name: 'FilterHeader',
  components: {
    FeedFilter,
    AssetInfo,
  },
  props: {
    selectedDevice: { type: Object, default: null },
  },
  methods: {
    emitScroll(level) {
      this.$eventBus.$emit('feed-scroll', level);
    },
  },
};
</script>

<style>
.feed-header {
  width: 100%;
  display: flex;
  flex-direction: column;
}

.feed-filter-wrapper {
  flex: 1 1 auto;
}

.asset-info-wrapper {
  flex: 1 1 auto;
  border-bottom: solid 2px #425866;
}
</style>