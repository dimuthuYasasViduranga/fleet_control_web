<template>
  <div>
    <loading :isLoading="true" />
    <div class="message">{{ message }}</div>
  </div>
</template>

<script>
import loading from 'hx-layout/Loading.vue';

export default {
  name: 'LoadingModal',
  wrapperClass: 'loading-modal',
  components: {
    loading,
  },
  props: {
    message: { type: String, default: '' },
  },
  computed: {
    noUnderscore() {
      return this.errorMessage.replaceAll('_', ' ');
    },
  },
};
</script>

<style>
.loading-modal .modal-container-wrapper {
  height: 90%;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.loading-modal .modal-container {
  height: auto;
  min-width: 20rem;
  width: 0;
  display: flex;
  flex-direction: column;
}

.loading-modal .message {
  min-width: 5rem;
  margin: auto;
  font-size: 1.5rem;
  user-select: none;
  text-align: center;
}

.loading-modal .loading-wrapper {
  height: 8rem;
  margin-bottom: 1rem;
}

.loading-modal .loading-wrapper svg {
  width: 100%;
  height: 100%;
}

.loading-modal .message.error {
  color: red;
  text-decoration: underline;
}
</style>