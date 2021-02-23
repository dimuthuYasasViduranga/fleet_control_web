<template>
  <div class="message-editor">
    <MessageEditorModal :show="showEditModal" :messageType="pendingType" @close="onEditorClose" />
    <button class="hx-btn" @click="onSetEdit()">Create New</button>
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No Time Codes to show"
      :data="localMessageTypes"
      :show-caption="false"
      :show-filter="true"
      sort-by="code"
    >
      <table-column cell-class="table-cel" label="Name" show="type" />
      <table-column cell-class="table-cel icon-cel">
        <template slot-scope="row">
          <div class="edit-wrapper">
            <toggle-button
              :sync="true"
              :value="!row.deleted"
              :width="70"
              :css-colors="true"
              @input="onToggleRow(row)"
              :labels="{ checked: 'Enabled', unchecked: 'Disabled' }"
            />
            <Icon
              v-if="!row.deleted"
              v-tooltip="'Edit'"
              class="edit-icon"
              :icon="editIcon"
              @click="onSetEdit(row)"
            />
          </div>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import MessageEditorModal from './MessageEditorModal.vue';
import ConfirmModal from '../../../modals/ConfirmModal.vue';

import { ToggleButton } from 'vue-js-toggle-button';

import EditIcon from '@/components/icons/Edit.vue';

import { firstBy } from 'thenby';

const DELETE_CONFIRM_BODY = `Are you sure you want to disable this message type?
\nUsers will no longer be presented with this option`;

export default {
  name: 'MessageEditor',
  components: {
    Icon,
    TableComponent,
    TableColumn,
    MessageEditorModal,
    ToggleButton,
  },
  props: {
    messageTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      editIcon: EditIcon,
      showEditModal: false,
      pendingType: null,
    };
  },
  computed: {
    localMessageTypes() {
      return this.messageTypes
        .map(m => {
          return {
            id: m.id,
            type: m.type,
            deleted: m.deleted,
          };
        })
        .sort(firstBy('deleted').thenBy('type'));
    },
  },
  methods: {
    onSetEdit(row) {
      this.showEditModal = true;

      const type = row || {};
      this.pendingType = {
        id: type.id,
        type: type.type,
        deleted: type.deleted,
      };
    },
    onToggleRow(row) {
      const type = row || {};
      this.pendingType = {
        id: type.id,
        type: type.type,
        deleted: !type.deleted,
      };

      if (row.deleted === false) {
        this.$modal
          .create(ConfirmModal, { title: 'Disable Message?', body: DELETE_CONFIRM_BODY })
          .onClose(answer => {
            if (answer === 'ok') {
              this.onToggleDeleted();
            }
          });
      } else {
        this.onToggleDeleted();
      }
    },
    onToggleDeleted() {
      const payload = {
        id: this.pendingType.id,
        name: this.pendingType.type,
        deleted: this.pendingType.deleted,
      };

      this.$channel
        .push('update operator message type', payload)
        .receive('ok', () => {
          this.pendingType = null;
        })
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to update message'));
    },
    onDelete(row) {
      this.showEditModal = false;

      const type = row || {};
      this.pendingType = {
        id: type.id,
        type: type.type,
      };
    },
    onConfirmDelete(answer) {
      if (answer !== 'ok') {
        this.pendingType = null;
        return;
      }

      const payload = {
        id: this.pendingType.id,
        type: this.pendingType.type,
        deleted: true,
      };

      this.$channel
        .push('update operator message type', payload)
        .receive('ok', () => {
          this.pendingType = null;
        })
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to update message'));
    },
    onEditorClose() {
      this.pendingType = null;
      this.showEditModal = false;
    },
  },
};
</script>

<style>
.message-editor .icon-cel {
  width: 2rem;
  height: 3.5rem;
}

.message-editor .edit-wrapper {
  display: flex;
  margin: 0.5rem;
}

.message-editor .edit-icon {
  cursor: pointer;
  padding-top: 2px;
  height: 1.2rem;
}

.message-editor .edit-icon:hover {
  stroke: orange;
}
</style>