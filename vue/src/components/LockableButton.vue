<template>
  <span :class="lockedClass" @click="onClick">
    <slot></slot>
  </span>
</template>

<script>
export default {
  name: 'LockableButton',
  props: {
    lock: { type: Boolean, default: false },
  },
  computed: {
    lockedClass() {
      if (this.lock === true) {
        return 'lockable-btn-disabled';
      }
      return 'lockable-btn';
    },
  },
  methods: {
    onClick() {
      if (this.lock === false) {
        this.$emit('click');
      }
    },
  },
};
</script>

<style>
.lockable-btn {
  user-select: none;
  color: #007acc;
}

.lockable-btn:hover {
  color: #005c99;
  cursor: pointer;
}

.lockable-btn-disabled {
  user-select: none;
  color: grey;
}
</style>