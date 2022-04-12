<template>
  <div class="global-actions-modal">
    <h2>Global Actions</h2>
    <button class="hx-btn" @click="onOpenMassTimeAllocationAssignment()">
      Mass Assign Time Codes
    </button>
    <button class="hx-btn" @click="onOpenMassLogout()">Mass Logout</button>
  </div>
</template>

<script>
import MassLogoutModal from './MassLogoutModal.vue';
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
    onOpenMassLogout() {
      this.$modal.create(MassLogoutModal);
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
  margin-top: 0.25rem;
  width: 100%;
}
</style>