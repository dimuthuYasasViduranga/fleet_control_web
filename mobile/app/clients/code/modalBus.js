import Vue from 'nativescript-vue';

const TERM_EVENT = 'modal:terminate';
const TERM_PAYLOAD = 'TERMINATE';

// this is to give similar functionality to a promise but not in the same way
class ModalReturn {
  constructor(promise) {
    this._onClose = () => null;
    this._onAnyClose = () => null;
    this._onError = () => null;
    this._onTerminate = () => null;

    promise
      .then(resp => {
        if (resp === TERM_PAYLOAD) {
          this._onTerminate(resp);
        } else {
          this._onClose(resp);
        }
        this._onAnyClose(resp);
      })
      .catch(error => {
        console.error(error);
        this._onError(error);
      });
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

export class ModalBus {
  constructor() {
    this.TERMINATE = TERM_PAYLOAD;
    this._bus = new Vue();
  }

  get bus() {
    return this._bus;
  }

  open(component, props, allowOuterClose) {
    return new ModalReturn(
      new Promise(resolve => {
        this._bus.$emit('modal:create', component, resolve, props, allowOuterClose);
      }),
    );
  }

  closeTop() {
    console.log('[ModalBus] close top');
    this._bus.$emit('modal:close top');
  }

  closeAll() {
    console.log('[ModalBus] close all');
    this._bus.$emit(TERM_EVENT, TERM_PAYLOAD);
  }

  on(event, callback) {
    this._bus.$on(event, callback);
  }

  send(event, payload) {
    this._bus.$emit(event, payload);
  }

  onTerminate(callback) {
    this._bus.$on(TERM_EVENT, callback);
  }
}
