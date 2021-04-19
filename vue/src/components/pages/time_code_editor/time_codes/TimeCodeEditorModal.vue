<template>
  <modal class="time-code-editor-modal" :show="show" @close="close()">
    <table>
      <tr class="row">
        <td class="key">Code</td>
        <td class="value">
          <input
            v-tooltip="{
              trigger: 'manual',
              show: !!takenBy.id,
              content: `Code taken by '${takenBy.name}'`,
            }"
            class="typeable"
            :class="{ error: (showValidation && validationErrors.includes('code')) || takenBy.id }"
            v-model="localTimeCode.code"
            placeholder="Name"
            type="text"
            autocomplete="off"
          />
        </td>
      </tr>
      <tr class="row">
        <td class="key">Name</td>
        <td class="value">
          <input
            class="typeable"
            :class="{ error: showValidation && validationErrors.includes('name') }"
            v-model="localTimeCode.name"
            placeholder="Name"
            type="text"
            autocomplete="off"
          />
        </td>
      </tr>
      <tr class="row">
        <td class="key">Group</td>
        <td class="value">
          <DropDown
            v-model="localTimeCode.groupId"
            :class="{ error: showValidation && validationErrors.includes('groupId') }"
            :searchable="false"
            :items="timeCodeGroups"
            label="name"
            :useScrollLock="false"
          />
        </td>
      </tr>
      <tr class="row">
        <td class="key">Category</td>
        <td class="value">
          <DropDown
            v-model="localTimeCode.categoryId"
            :searchable="false"
            :items="timeCodeCategories"
            label="name"
            :useScrollLock="false"
          />
        </td>
      </tr>
    </table>

    <div class="actions">
      <button class="hx-btn" @click="onConfirm">{{ confirmName }}</button>
      <button class="hx-btn" @click="onReset">Reset</button>
      <button class="hx-btn" @click="close">Cancel</button>
    </div>
  </modal>
</template>

<script>
import Modal from '../../../modals/Modal.vue';
import LoadingModal from '../../../modals/LoadingModal.vue';
import DropDown from '../../../dropdown/DropDown.vue';

const IN_TRANSIT_TIMEOUT = 3000;

const REQUIRED_FIELDS = ['name', 'code', 'groupId'];

function defaultObj() {
  return {
    id: null,
    code: '',
    name: '',
    groupId: null,
    categoryId: null,
  };
}

export default {
  name: 'TimeCodeEditorModal',
  components: {
    Modal,
    DropDown,
  },
  props: {
    timeCode: Object,
    show: { type: Boolean, default: false },
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    timeCodeCategories: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      inTransit: false,
      localTimeCode: defaultObj(),
      showValidation: false,
      originalCode: '',
    };
  },
  computed: {
    confirmName() {
      return this.localTimeCode.id ? 'Update' : 'Create';
    },
    validationErrors() {
      return REQUIRED_FIELDS.filter(f => !this.localTimeCode[f]);
    },
    takenBy() {
      return (
        this.timeCodes.find(
          tc => tc.code === this.localTimeCode.code && tc.code !== this.originalCode,
        ) || {}
      );
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
      this.localTimeCode = defaultObj();
      this.inTransit = false;
      this.$emit('close', resp);
    },
    onReset() {
      this.localTimeCode = { ...defaultObj(), ...(this.timeCode || {}) };
      this.originalCode = this.localTimeCode.code;
      this.showValidation = false;
    },
    onConfirm() {
      this.showValidation = true;

      if (this.validationErrors.length > 0 || this.codeTaken) {
        console.error('[TimeCodeEditorModal] Invalid time code');
        return;
      }

      const timeCode = this.localTimeCode;

      const payload = {
        id: timeCode.id,
        code: timeCode.code,
        name: timeCode.name,
        group_id: timeCode.groupId,
        category_id: timeCode.categoryId,
      };

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'Updating Time Code' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('update time code', payload)
        .receive('ok', () => {
          loading.close();
          this.$toaster.info(`Time Code ${timeCode.id ? 'Updated' : 'Created'}`);
          this.close();
        })
        .receive('error', resp => {
          loading.close();
          this.$toaster.error(resp.error);
        })
        .receive('timeout', () => {
          loading.close();
          this.$toaster.noComms('Unable to update time code');
        });
    },
  },
};
</script>

<style>
.time-code-editor-modal {
  font-family: 'GE Inspira Sans', sans-serif;
  color: #b6c3cc;
}

/* -------- modal config ------- */
.time-code-editor-modal .modal-container {
  height: auto;
  max-width: 35rem;
}

.time-code-editor-modal > .modal-container-wrapper {
  height: 100%;
  width: 100%;
  padding: 2rem 3rem;
}

/* ------- table ------------ */
.time-code-editor-modal table {
  width: 100%;
  border-collapse: collapse;
}

.time-code-editor-modal .row {
  height: 3rem;
}

.time-code-editor-modal .row .key {
  font-size: 2rem;
}

.time-code-editor-modal .row .value {
  padding-left: 2rem;
  font-size: 1.5rem;
  text-align: center;
}

.time-code-editor-modal .row .typeable {
  width: 100%;
}

.time-code-editor-modal .row .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
}

/* ---------- action buttons ------------ */
.time-code-editor-modal .actions {
  display: flex;
  padding-top: 1rem;
  justify-content: space-between;
}

.time-code-editor-modal .actions:first-child {
  margin-left: 0;
}

.time-code-editor-modal .actions:last-child {
  margin-right: 0;
}

.time-code-editor-modal .actions .hx-btn {
  width: 100%;
  margin: 0 0.1rem;
}

/* ----- validation highlighting ----- */
.time-code-editor-modal .typeable.error,
.time-code-editor-modal .dropdown-wrapper.error {
  transition: background 0.4s;
  background-color: darkred;
}
</style>