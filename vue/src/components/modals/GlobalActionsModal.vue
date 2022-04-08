<template>
  <div class="global-actions-modal">
    <h2>Global Actions</h2>
    <button class="hx-btn" @click="onOpenMassTimeAllocationAssignment()">
      Mass Assign Time Codes
    </button>
  </div>
</template>

<script>
import MassTimeAllocationAssignmentModal from './MassTimeAllocationAssignmentModal.vue';
export default {
  name: 'GlobalActionsModal',
  wrapperClass: 'global-actions-modal-wrapper',
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onOpenMassTimeAllocationAssignment() {
      this.$modal.create(MassTimeAllocationAssignmentModal);
    },
  },
};
</script>

<style>
.global-actions-modal-wrapper .modal-container {
  max-width: 32rem;
}

.global-actions-modal h2 {
  text-align: center;
}

.global-actions-modal > button {
  width: 100%;
}
</style>