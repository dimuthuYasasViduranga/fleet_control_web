import Vue from 'vue';
const TERM_PAYLOAD = 'TERMINATE';

import ModalWrapper from '@/components/modals/ModalWrapper.vue';

class ModalInstance {
  constructor(instance, onRemove) {
    this.instance = instance;
    instance.$on('close', resp => this.close(resp));

    this._onRemove = onRemove;
    this._onClose = () => null;
    this._onAnyClose = () => null;
    this._onTerminate = () => null;
    this._onError = () => null;
  }

  close(resp) {
    if (!this.instance) {
      this._onError(resp);
      return;
    }

    if (resp === TERM_PAYLOAD) {
      this._onTerminate(resp);
    } else {
      this._onClose(resp);
    }
    this._onAnyClose(resp);
    this._onRemove(this);
  }

  onClose(callback) {
    this._onClose = callback;
    return this;
  }

  onAnyClose(callback) {
    this._onAnyClose = callback;
    return this;
  }

  onTerminate(callback) {
    this._onTerminate = callback;
    return this;
  }

  onError(callback) {
    this._onError = callback;
    return this;
  }
}

class Modal {
  constructor(store) {
    this.openModals = [];
    this.TERMINATE = TERM_PAYLOAD;
    this.store = store;
  }

  create(component, componentProps = {}, options = {}) {
    // create a div to mount over
    const modalElement = document.createElement('div');
    (document.fullscreenElement || document.body).appendChild(modalElement);

    // mount component and listen to the close event
    const modal = new Vue({
      ...ModalWrapper,
      propsData: { component, componentProps, ...options },
    });
    modal.$store = this.store;
    modal.$mount(modalElement);

    const modalInstance = new ModalInstance(modal, m => this.handleRemove(m));

    this.openModals.push(modalInstance);

    return modalInstance;
  }

  handleRemove(modalInstance) {
    if (modalInstance && modalInstance.instance) {
      modalInstance.instance.$destroy();
      modalInstance.instance.$el.remove();
      modalInstance.instance = null;
    }
    this.openModals = this.openModals.filter(m => m !== modalInstance);
  }

  closeAll() {
    this.openModals.forEach(modal => modal.close(TERM_PAYLOAD));
    this.openModals = [];
  }
}

export default new Modal();
