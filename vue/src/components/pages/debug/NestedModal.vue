<template>
  <div class="nested-modal">
    <div class="answer">Current Answer: {{ answer || '--' }}</div>
    <button class="hx-btn" @click="openConfirmModal()">Change Answer</button>
  </div>
</template>

<script>
import ConfirmModal from '@/components/modals/ConfirmModal.vue';
export default {
  name: 'NestedModal',
  wrapperClass: 'nested-modal-wrapper',
  data: () => {
    return {
      answer: '',
    };
  },
  methods: {
    onClose(resp) {
      this.$emit('close', resp);
    },
    openConfirmModal() {
      this.$modal.create(ConfirmModal, { title: 'Select Answer' }).onClose(resp => {
        this.answer = resp;
      });
    },
  },
};
</script>

<style>
@import '../../../assets/hxInput.css';

.nested-modal-wrapper .modal-container {
  max-width: 32rem;
}
</style>