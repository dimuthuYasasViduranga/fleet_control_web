<template>
  <div class="confirm-modal">
    <h1 class="title">{{ title }}</h1>
    <div v-if="body" class="separator"></div>

    <p class="body">{{ body }}</p>
    <div v-if="actions.length === 0" class="answers">
      <button class="hx-btn ok" @click="onAnswer(ok)">{{ ok }}</button>
      <button class="hx-btn cancel" @click="onAnswer(cancel)">{{ cancel }}</button>
    </div>
    <div v-else class="actions">
      <button
        class="hx-btn"
        v-for="(action, index) in actions"
        :key="index"
        @click="onAnswer(action)"
      >
        {{ action }}
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ConfirmModal',
  wrapperClass: 'confirm-modal-wrapper',
  props: {
    title: { type: String, default: '' },
    body: { type: String, default: '' },
    ok: { type: String, default: 'ok' },
    cancel: { type: String, default: 'cancel' },
    actions: { type: Array, default: () => [] },
  },
  methods: {
    onAnswer(answer) {
      this.$emit('close', answer);
    },
  },
};
</script>

<style>
@import '../../assets/styles/hxInput.css';

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

.body {
  white-space: pre-line;
  font-size: 1.25rem;
}

.answers {
  display: flex;
  justify-content: flex-end;
}

.answers .hx-btn {
  margin-left: 0.1rem;
  width: 6rem;
  text-transform: capitalize;
}

.actions {
  display: flex;
  justify-content: flex-end;
}

.actions .hx-btn {
  margin-left: 0.1rem;
}
</style>