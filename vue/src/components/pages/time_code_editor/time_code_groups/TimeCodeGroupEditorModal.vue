<template>
  <modal class="time-code-group-editor-modal" :show="show" @close="close()">
    <table>
      <tr class="row">
        <td class="key">Name</td>
        <td class="value">{{ localGroup.name }}</td>
      </tr>
      <tr class="row">
        <td class="key">Alias</td>
        <td class="value">
          <input
            id="name"
            class="typeable"
            v-model="localGroup.alias"
            placeholder="Alias"
            type="text"
            autocomplete="off"
          />
        </td>
      </tr>
    </table>

    <div class="actions">
      <button class="hx-btn" @click="onConfirm">Update</button>
      <button class="hx-btn" @click="onReset">Reset</button>
      <button class="hx-btn" @click="close">Cancel</button>
    </div>
  </modal>
</template>

<script>
import Modal from '../../../modals/Modal.vue';
import LoadingModal from '../../../modals/LoadingModal.vue';

const IN_TRANSIT_TIMEOUT = 3000;

function defaultGroup() {
  return {
    id: null,
    name: '',
    alias: '',
  };
}

export default {
  name: 'TimeCodeGroupEditorModal',
  components: {
    Modal,
  },
  props: {
    group: Object,
    show: { type: Boolean, default: false },
  },
  data: () => {
    return {
      inTransit: false,
      localGroup: defaultGroup(),
    };
  },
  watch: {
    show(bool) {
      if (bool === true) {
        this.onReset();
      }
    },
  },
  methods: {
    close(resp) {
      this.localGroup = defaultGroup();
      this.inTransit = false;
      this.$emit('close', resp);
    },
    onReset() {
      this.localGroup = { ...defaultGroup(), ...(this.group || {}) };
    },
    onConfirm() {
      const group = this.localGroup;

      const payload = {
        id: group.id,
        alias: group.alias,
      };

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'Updating Time Code Group' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('time-code:update-group', payload)
        .receive('ok', () => {
          loading.close();
          this.close();
        })
        .receive('error', resp => {
          loading.close();
          this.$toaster.error(resp.error);
        })
        .receive('timeout', () => {
          loading.close();
          this.$toaster.noComms('Unable to update time code group');
        });
    },
  },
};
</script>

<style>
.time-code-group-editor-modal {
  font-family: 'GE Inspira Sans', sans-serif;
  color: #b6c3cc;
}

/* -------- modal config ------- */
.time-code-group-editor-modal .modal-container {
  height: auto;
  max-width: 35rem;
}

.time-code-group-editor-modal > .modal-container-wrapper {
  height: 100%;
  width: 100%;
  padding: 2rem 3rem;
}

/* ------- table ------------ */
.time-code-group-editor-modal table {
  width: 100%;
  border-collapse: collapse;
}

.time-code-group-editor-modal .row {
  height: 3rem;
}

.time-code-group-editor-modal .row .key {
  font-size: 2rem;
}

.time-code-group-editor-modal .row .value {
  padding-left: 2rem;
  font-size: 1.5rem;
  text-align: center;
}

.time-code-group-editor-modal .row .typeable {
  width: 100%;
}

/* ---------- action buttons ------------ */
.time-code-group-editor-modal .actions {
  display: flex;
  padding-top: 1rem;
  justify-content: space-between;
}

.time-code-group-editor-modal .actions:first-child {
  margin-left: 0;
}

.time-code-group-editor-modal .actions:last-child {
  margin-right: 0;
}

.time-code-group-editor-modal .actions .hx-btn {
  width: 100%;
  margin: 0 0.1rem;
}
</style>