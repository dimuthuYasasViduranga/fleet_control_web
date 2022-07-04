<template>
  <modal :show="show" class="message-editor-modal" @close="close()">
    <table>
      <tr class="row">
        <td class="key">Name</td>
        <td class="value">
          <input
            class="typeable"
            :class="{ error: showValidation && !typeValid }"
            v-model="localMessageType.type"
            placeholder="Name"
            type="text"
            autocomplete="off"
          />
        </td>
      </tr>
    </table>

    <div class="actions">
      <button class="hx-btn" @click="onUpdate()">{{ confirmName }}</button>
      <button v-if="localMessageType.id" class="hx-btn" @click="onOverride()">Override</button>
      <button class="hx-btn" @click="onReset">Reset</button>
      <button class="hx-btn" @click="close">Cancel</button>
    </div>
  </modal>
</template>

<script>
import Modal from '../../../modals/Modal.vue';
import LoadingModal from '../../../modals/LoadingModal.vue';
import ConfirmModal from '../../../modals/ConfirmModal.vue';

const IN_TRANSIT_TIMEOUT = 3000;

const OVERRIDE_WARNING = `Overriding a message type will update all previously submitted messages.

This should only be used to correct phrasing/spelling, and NOT change the intent of the message.

Are you sure you want to override the message?`;

function defaultObj() {
  return {
    id: undefined,
    type: '',
    deleted: false,
  };
}

export default {
  name: 'MessageEditorModal',
  components: {
    Modal,
  },
  props: {
    messageType: Object,
    show: { type: Boolean, default: false },
  },
  data: () => {
    return {
      inTransit: false,
      inTransitTimeout: null,
      requestError: '',
      localMessageType: defaultObj(),
      showValidation: false,
    };
  },
  computed: {
    typeValid() {
      return !!this.localMessageType.type;
    },
    confirmName() {
      return this.localMessageType.id ? 'Update' : 'Create';
    },
  },
  watch: {
    show(bool) {
      if (bool === true) {
        this.onReset();
      }
      this.showValidation = false;
    },
  },
  methods: {
    close(resp) {
      this.localMessageType = defaultObj();
      this.requireError = '';
      this.inTransit = false;
      this.$emit('close', resp);
    },
    onReset() {
      this.localMessageType = { ...defaultObj(), ...(this.messageType || {}) };
      this.requireError = '';
      this.showValidation = false;
    },
    onOverride() {
      this.$modal
        .create(ConfirmModal, { title: 'Override Message Type', body: OVERRIDE_WARNING })
        .onClose(answer => {
          if (answer === 'ok') {
            this.onUpdate(true);
          }
        });
    },
    onUpdate(override = false) {
      this.showValidation = true;

      if (!this.typeValid) {
        console.error('[MessageEditorModal] Invalid message type');
        return;
      }

      const messageType = this.localMessageType;

      const payload = {
        id: messageType.id,
        name: messageType.type,
        deleted: messageType.deleted,
        override,
      };

      this.onSubmit(payload);
    },
    onSubmit(payload) {
      this.inTransit = true;

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'Updating Message' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('operator-message:update-message-type', payload)
        .receive('ok', () => {
          this.inTransit = false;
          loading.close();
          this.close();
        })
        .receive('error', resp => {
          this.inTransit = false;
          loading.close();
          this.$toaster.error(resp.error);
        })
        .receive('timeout', () => {
          this.inTransit = false;
          loading.close();
          this.$toaster.noComms('Unable to update message');
        });
    },
  },
};
</script>

<style>
.message-editor-modal {
  font-family: 'GE Inspira Sans', sans-serif;
  color: #b6c3cc;
}

/* -------- modal config ------- */
.message-editor-modal .modal-container {
  height: auto;
  max-width: 35rem;
}

.message-editor-modal > .modal-container-wrapper {
  height: 100%;
  width: 100%;
  padding: 2rem 3rem;
}

/* ------- table ------------ */
.message-editor-modal table {
  width: 100%;
  border-collapse: collapse;
}

.message-editor-modal .row {
  height: 3rem;
}

.message-editor-modal .row .key {
  font-size: 2rem;
}

.message-editor-modal .row .value {
  padding-left: 2rem;
  font-size: 1.5rem;
  text-align: center;
}

.message-editor-modal .row .typeable {
  width: 100%;
}

/* ---------- action buttons ------------ */
.message-editor-modal .actions {
  display: flex;
  padding-top: 1rem;
  justify-content: space-between;
}

.message-editor-modal .actions:first-child {
  margin-left: 0;
}

.message-editor-modal .actions:last-child {
  margin-right: 0;
}

.message-editor-modal .actions .hx-btn {
  width: 100%;
  margin: 0 0.1rem;
}

/* ----- validation highlighting ----- */
.message-editor-modal .typeable.error {
  transition: background 0.4s;
  background-color: darkred;
}
</style>