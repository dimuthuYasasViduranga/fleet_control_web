<template>
  <Draggable v-if="!disabled">
    <slot></slot>
  </Draggable>
  <div v-else disabled><slot></slot></div>
</template>

<script>
import { Draggable } from 'vue-smooth-dnd';

export default {
  name: 'CustomDraggable',
  components: {
    Draggable,
  },
  props: {
    disabled: { type: Boolean, default: false },
  },
};
</script>