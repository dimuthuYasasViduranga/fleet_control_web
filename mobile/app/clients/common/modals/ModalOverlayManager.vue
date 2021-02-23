<template>
  <GridLayout class="modal-overlay-manager">
    <!-- 
      might need to remove the v-for and replace it with a referencecs check and 
      explicit create/remove child (so that other components dont re-render for no reason)
     -->
    <ModalOverlay
      v-for="(modal, index) in modals"
      :key="index"
      v-bind="modal.modalProps"
      :component="modal.component"
      :props="modal.props"
      @close="onClose(modal, $event)"
    />
  </GridLayout>
</template>

<script>
import ModalOverlay from './ModalOverlay.vue';
export default {
  name: 'ModalOverlayManager',
  components: {
    ModalOverlay,
  },
  data: () => {
    return {
      modals: [],
    };
  },
  mounted() {
    this.$modalBus.on('modal:create', this.createModal);
    this.$modalBus.on('modal:close top', this.closeTop);
    this.$modalBus.onTerminate(this.closeAll);
  },
  methods: {
    createModal(comp, resolve, props, modalProps) {
      if (!comp || !resolve) {
        console.error['[ModalOverlayManager] missing component and or resolve callback'];
        return;
      }

      const modal = {
        component: comp,
        modalProps,
        resolve,
        props,
      };

      this.modals.push(modal);
    },
    onClose(modal, resp) {
      modal.resolve(resp);
      const index = this.modals.indexOf(modal);

      if (index !== -1) {
        this.modals.splice(index, 1);
      }
    },
    closeAll() {
      console.log('[ModalOverlayManager] Request to terminate all modals');
      const len = this.modals.length;

      for (let i = len - 1; i >= 0; i--) {
        this.modals[i].resolve(this.$modalBus.TERMINATE);
      }

      this.modals = [];
      console.log('[ModalOverlayManager] All modals closed');
    },
    closeTop() {
      if (this.modals.length > 0) {
        const modal = this.modals.pop();
        modal.resolve(this.$modalBus.TERMINATE);
      }
    },
  },
};
</script>