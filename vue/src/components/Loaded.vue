<template>
  <div class="loaded">
    <template v-if="showLoading">
      <loading :isLoading="true" />
    </template>
    <template v-else>
      <slot></slot>
    </template>
  </div>
</template>

<script>
import loading from 'hx-layout/Loading.vue';

export default {
  name: 'Loaded',
  components: {
    loading,
  },
  computed: {
    showLoading() {
      return this.$store.state.connection.isAlive !== true;
    },
  },
};
</script>

<style>
.loaded .loading-wrapper {
  display: flex;
  align-items: center;
}

.loaded .loading-wrapper svg {
  margin: auto;
  display: block;
  min-height: 15rem;
}
</style>