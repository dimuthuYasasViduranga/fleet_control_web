<template>
  <div class="confirm-modal">
    <h1 class="title">{{ title }}</h1>
    <div v-if="body" class="separator"></div>

    <p class="body">{{ body }}</p>
    <div class="answers">
      <button class="hx-btn ok" @click="onAnswer(ok)">{{ ok }}</button>
      <button class="hx-btn cancel" @click="onAnswer(cancel)">{{ cancel }}</button>
    </div>
  </div>
</template>

<script>
import Modal from './Modal.vue';

export default {
  name: 'ConfirmModal',
  wrapperClass: 'confirm-modal-wrapper',
  components: {
    Modal,
  },
  props: {
    title: { type: String, default: '' },
    body: { type: String, default: '' },
    ok: { type: String, default: 'ok' },
    cancel: { type: String, default: 'cancel' },
  },
  methods: {
    onAnswer(answer) {
      this.$emit('close', answer);
    },
  },
};
</script>

<style>
@import '../../assets/hxInput.css';

.confirm-modal-wrapper .modal-container {
  max-width: 32rem;
}
</style>

<style scoped>
h1 {
  margin: 0;
}

.separator {
  height: 1rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #677e8c;
}

.answers {
  display: flex;
  justify-content: flex-end;
}

.body {
  white-space: pre-line;
  font-size: 1.25rem;
}

.hx-btn {
  margin-left: 0.1rem;
  width: 6rem;
  text-transform: capitalize;
}
</style>