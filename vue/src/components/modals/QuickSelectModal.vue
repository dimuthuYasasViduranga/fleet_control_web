<template>
  <div class="quick-select-modal">
    <h1 v-if="title" class="title">{{ title }}</h1>
    <div class="item" v-for="(item, index) in items" :key="index" @click="onSelect(item)">
      {{ label ? item[label] : item }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'QuickSelectModal',
  wrapperClass: 'quick-select-modal-wrapper',
  props: {
    title: { type: String, default: '' },
    items: { type: Array, default: () => [] },
    label: { type: String, default: null },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onSelect(item) {
      this.close(item);
    },
  },
};
</script>

<style>
.quick-select-modal-wrapper .modal-container {
  max-width: 32rem;
}
</style>

<style scoped>
.title {
  text-align: center;
  border-bottom: 1px solid #677e8c;
  margin-bottom: 0.75rem;
}

.item {
  border-left: 1rem solid #212e36;
  cursor: pointer;
  user-select: none;
  height: 3rem;
  line-height: 3rem;
  width: 100%;
  margin: 0.5rem 0;
  padding: 0.2rem;
  padding-left: 1rem;
  font-size: 1.25rem;
  background-color: #41525e;
}

.item:hover {
  opacity: 0.5;
}
</style>