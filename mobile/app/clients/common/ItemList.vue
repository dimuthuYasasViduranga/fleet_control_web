<template>
  <GridLayout class="item-list" width="100%" columns="*, *, *, *, *, *" rows="3*, 3*, 2*">
    <GridLayout
      v-for="(item, index) in buttonList"
      :key="index"
      class="item-wrapper"
      width="100%"
      columns="*, *, *, *"
      rows="*, *"
      :col="(index % 3) * 2"
      :colSpan="2"
      :row="Math.floor(index / 3)"
    >
      <Button
        class="button item"
        :key="item.id"
        :text="item.name"
        :col="0"
        :colSpan="4"
        :row="0"
        :rowSpan="2"
        textTransform="capitalize"
        @tap="emitSelected(item)"
      />

      <Button
        v-if="item.count > 0"
        class="count-indicator"
        height="40"
        width="40"
        :col="3"
        :row="0"
        :text="item.count"
        @tap="emitSelected(item)"
      />
    </GridLayout>

    <GridLayout row="3" col="0" :colSpan="6" columns="*, *">
      <Button
        v-show="page > 0"
        class="button prev-button"
        text="Previous"
        col="0"
        textTransform="capitalize"
        @tap="prevPage"
      />

      <Button
        v-show="page < maxPage"
        class="button next-button"
        text="Next"
        col="1"
        textTransform="capitalize"
        @tap="nextPage"
      />
    </GridLayout>
  </GridLayout>
</template>

<script>
function enforceRange(min, max, value) {
  if (value > max) {
    return max;
  }

  if (value < min) {
    return min;
  }

  return value;
}

export default {
  name: 'items',
  props: {
    items: { type: Array, default: () => [] },
  },
  data() {
    return {
      page: 0,
      timeout: null,
    };
  },
  computed: {
    maxPage() {
      const itemCount = this.items.length;
      if (itemCount === 0) {
        return 0;
      }

      const max = Math.floor((itemCount - 1) / 6);
      return max;
    },
    buttonList() {
      const start = this.page * 6;
      return this.items.slice(start, start + 6);
    },
  },
  watch: {
    items() {
      this.page = 0;
    },
  },
  methods: {
    emitSelected(item) {
      this.$emit('select', item);
    },
    returnToDispatch() {
      this.$emit('idle', 'dispatch');
    },
    highlightClass(highlight) {
      if (highlight) {
        return 'highlight';
      }
      return '';
    },
    prevPage() {
      const prevPage = enforceRange(0, this.maxPage, this.page - 1);
      this.page = prevPage;
      this.emitPageChange(prevPage);
    },
    nextPage() {
      const nextPage = enforceRange(0, this.maxPage, this.page + 1);
      this.page = nextPage;
      this.emitPageChange(nextPage);
    },
    emitPageChange(page) {
      this.$emit('page', page);
    },
  },
};
</script>

<style scoped>
.item {
  font-size: 30;
}

.count-indicator {
  border-radius: 50%;
  background-color: cadetblue;
}

.item-list .next-button,
.item-list .prev-button {
  font-size: 30;
}
</style>
