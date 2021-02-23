<template>
  <GridLayout class="nested-item-list" width="100%" rows="4*, *">
    <GridLayout row="0" columns="*, *, *" rows="*, *">
      <GridLayout
        columns="9*, *, *"
        rows="*, 2*"
        v-for="(item, index) in shownItems"
        :key="index"
        class="item-wrapper"
        :col="index % 3"
        :row="Math.floor(index / 3)"
      >
        <StackLayout row="0" rowSpan="2" colSpan="3">
          <Button
            class="button item"
            height="100%"
            :text="item.name"
            textTransform="capitalize"
            @tap="onSelect(item)"
          />
        </StackLayout>

        <Image
          v-if="showChildrenIndicator(item)"
          row="0"
          col="1"
          class="children-indicator"
          src="~/assets/images/list.png"
          stretch="aspectFit"
          horizontalAlignment="center"
        />
      </GridLayout>
    </GridLayout>
    <GridLayout row="1" columns="*, *, *, *">
      <Button
        class="button item-nav-btn top"
        text="top"
        col="0"
        @tap="onTop"
        :isEnabled="topEnabled"
      />
      <Button
        class="button item-nav-btn back"
        text="back"
        col="1"
        @tap="onBack"
        :isEnabled="backEnabled"
      />
      <Button
        class="button item-nav-btn prev"
        text="prev"
        col="2"
        @tap="onPrev"
        :isEnabled="prevEnabled"
      />
      <Button
        class="button item-nav-btn next"
        text="next"
        col="3"
        @tap="onNext"
        :isEnabled="nextEnabled"
      />
    </GridLayout>
  </GridLayout>
</template>

<script>
import { toTree } from '../code/tree.js';
import { chunkEvery } from '../code/helper.js';

const ITEM_ROWS = 2;
const ITEM_COLUMNS = 3;
const ITEMS_PER_PAGE = ITEM_ROWS * ITEM_COLUMNS;

function toLocalItems(items) {
  if (!items) {
    return [];
  }
  return items.map(item => {
    const children = items.filter(i => i.parentId === item.id);
    return {
      id: item.id,
      parentId: item.parentId,
      name: item.name,
      children,
    };
  });
}

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
  name: 'NestedItemList',
  props: {
    items: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      navigationButtons: [
        { id: 'top', text: 'Top' },
        { id: 'up', text: 'Up' },
        { id: 'prev', text: 'Prev' },
        { id: 'next', text: 'Next' },
      ],
      page: 0,
      parentId: null,
    };
  },
  computed: {
    localItems() {
      return toLocalItems(this.items);
    },
    level() {
      return this.localItems.filter(i => i.parentId === this.parentId);
    },
    pages() {
      return chunkEvery(this.level, ITEMS_PER_PAGE);
    },
    shownItems() {
      return this.pages[this.page] || [];
    },
    topEnabled() {
      return !!this.parentId;
    },
    backEnabled() {
      return !!this.parentId;
    },
    nextEnabled() {
      return this.pages.length > 0 && this.page < this.pages.length - 1;
    },
    prevEnabled() {
      return this.pages.length > 0 && this.page > 0;
    },
  },
  watch: {
    items: {
      immediate: true,
      handler(newItems) {
        this.setParent(null);
      },
    },
  },
  methods: {
    navButtonTap(button) {
      this.$emit('navigation', button.id);
    },
    showChildrenIndicator(item) {
      return item && item.children.length > 0;
    },
    setParent(id) {
      this.page = 0;
      this.parentId = id;
    },
    onSelect(item) {
      const originalItem = this.items.find(i => i.id === item.id);
      if (item.children.length === 0) {
        this.$emit('select', originalItem);
      } else {
        this.setParent(item.id);
        this.$emit('down', originalItem);
      }
    },
    onTop() {
      this.setParent(null);
    },
    onBack() {
      const parent = this.items.find(item => item.id === this.parentId);
      if (parent) {
        this.setParent(parent.parentId);
      }
    },
    onPrev() {
      const prevPage = enforceRange(0, this.pages.length, this.page - 1);
      this.$emit('pageChange', prevPage, this.page);
      this.page = prevPage;
    },
    onNext() {
      const nextPage = enforceRange(0, this.pages.length, this.page + 1);
      this.$emit('pageChange', nextPage, this.page);
      this.page = nextPage;
    },
  },
};
</script>

<style>
.item-nav-btn[isEnabled='false'] {
  background-color: dimgray;
  opacity: 0.6;
}

.item {
  font-size: 28;
}

.item-nav-btn {
  font-size: 20;
}
</style>