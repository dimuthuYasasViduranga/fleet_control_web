<template>
  <ScrollView class="nested-dropdown-modal" orientation="vertical">
    <StackLayout class="nested-dropdown-content">
      <NestedDropdownNode
        v-for="node in roots"
        :key="node.id"
        :node="node"
        :itemHeight="itemHeight"
        @itemSelect="onSelect"
      />
    </StackLayout>
  </ScrollView>
</template>

<script>
import { toTree } from '../../code/tree';
import NestedDropdownNode from './NestedDropdownNode.vue';

export default {
  name: 'NestedDropdownModal',
  components: {
    NestedDropdownNode,
  },
  props: {
    options: { type: Array, default: [] },
    selected: { type: Object, default: null },
    itemHeight: { type: Number, default: undefined },
  },
  computed: {
    roots() {
      return toTree(this.options);
    },
  },
  methods: {
    onSelect(element) {
      this.$emit('close', { selected: element });
    },
  },
};
</script>

<style>
.nested-dropdown-modal {
  background-color: white;
  width: 600;
}

.next-dropdown-content {
  padding: 25 50;
  margin-left: -60;
}
</style>