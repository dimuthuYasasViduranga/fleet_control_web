<template>
  <StackLayout class="nested-dropdown-node">
    <StackLayout class="node-wrapper" orientation="horizontal">
      <Image class="arrow" :src="arrowSrc" :height="itemHeight / 3" />
      <Button
        class="item"
        :text="node.value"
        :height="itemHeight"
        @tap="onSelect"
        textAlignment="left"
      />
    </StackLayout>

    <template v-if="isOpen">
      <NestedDropdownNode
        v-for="child in node.children"
        :key="child.id"
        :node="child"
        :itemHeight="itemHeight"
        @itemSelect="onPropogateItemSelect"
        @headingSelect="onPropogateHeadingSelect"
      />
    </template>
  </StackLayout>
</template>

<script>
const ARROW_DOWN = '~/assets/images/arrowDown.png';
const ARROW_RIGHT = '~/assets/images/arrowRight.png';
const LINE = '~/assets/images/line.png';

export default {
  name: 'NestedDropdownNode',
  props: {
    node: { type: Object, default: () => ({}) },
    itemHeight: { type: Number, default: 70 },
  },
  data: () => {
    return {
      isOpen: false,
    };
  },
  computed: {
    arrowSrc() {
      if (this.node.children.length === 0) {
        return LINE;
      }
      return this.isOpen ? ARROW_DOWN : ARROW_RIGHT;
    },
  },
  methods: {
    onSelect() {
      if ((this.node.children || []).length === 0) {
        this.$emit('itemSelect', this.node);
      } else {
        this.toggleShow();
        this.$emit('headingSelect', this.node);
      }
    },
    toggleShow() {
      this.isOpen = !this.isOpen;
    },
    onPropogateItemSelect(node) {
      this.$emit('itemSelect', node);
    },
    onPropogateHeadingSelect(node) {
      this.$emit('headingSelect', node);
    },
  },
};
</script>

<style>
.nested-dropdown-node {
  margin-left: 40;
}

.nested-dropdown-node .item {
  z-index: 0;
  background-color: white;
  margin-left: 0;
  width: 100%;
}
</style>