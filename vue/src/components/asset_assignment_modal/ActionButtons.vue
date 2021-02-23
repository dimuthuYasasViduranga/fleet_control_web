<template>
  <div class="action-buttons">
    <button class="hx-btn submit" @click="emit('submit')">Submit</button>
    <button class="hx-btn reset" @click="emit('reset')">Reset</button>
    <button class="hx-btn cancel" @click="emit('cancel')">Cancel</button>
  </div>
</template>

<script>
export default {
  name: 'ActionButtons',
  methods: {
    emit(event) {
      this.$emit(event);
    },
  },
};
</script>

<style scoped>
.action-buttons {
  display: flex;
  width: 100%;
}

.action-buttons .hx-btn {
  width: 100%;
  font-size: 1rem;
  margin: 0.1rem;
}
</style>