<template>
  <div class="pre-start-create-ticket-modal">
    <div class="title">{{ title }}</div>

    <div class="separator"></div>
    <template v-if="timestamp">
      <table>
        <tr>
          <td class="key">Last Updated</td>
          <td class="value">{{ formatDate(timestamp) }}</td>
        </tr>
      </table>

      <div class="separator"></div>
    </template>

    <table>
      <tr v-if="controlText">
        <td class="key">Control</td>
        <td class="value">{{ controlText }}</td>
      </tr>
      <tr v-if="controlComment">
        <td class="key">Comment</td>
        <td class="value">{{ controlComment }}</td>
      </tr>
      <tr>
        <td colspan="2"><div class="separator"></div></td>
      </tr>
      <tr>
        <td class="key">Reference</td>
        <td class="value">
          <input
            type="text"
            class="typeable"
            placeholder="--"
            v-model="localReference"
            :disabled="readonly"
          />
        </td>
      </tr>
      <tr>
        <td class="key">Details</td>
        <td class="value">
          <AutoSizeTextArea
            v-model="localDetails"
            placeholder="Extra information"
            :disabled="readonly"
          />
        </td>
      </tr>
      <tr>
        <td class="key">Status</td>
        <td class="value">
          <DropDown
            v-model="localStatusTypeId"
            label="name"
            :options="statusTypes"
            :disabled="readonly"
            placeholder="--"
          />
        </td>
      </tr>
    </table>

    <div class="separator"></div>

    <div v-if="!readonly" class="actions">
      <button class="hx-btn" @click="onSubmit()">{{ submitName }}</button>
      <button class="hx-btn" @click="close()">Cancel</button>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { DropDown } from 'hx-vue';
import AutoSizeTextArea from '@/components/AutoSizeTextArea.vue';
import { attributeFromList } from '@/code/helpers';
import { formatDateRelativeToIn } from '@/code/time';
export default {
  name: 'PreStartCreateTicketModal',
  wrapperClass: 'pre-start-create-ticket-modal-wrapper',
  components: {
    DropDown,
    AutoSizeTextArea,
  },
  props: {
    title: { type: String, default: 'Create Ticket' },
    submitName: { type: String, default: 'Create' },
    controlText: { type: String },
    controlComment: { type: String },
    timestamp: { type: Date },
    reference: { type: String },
    details: { type: String },
    statusTypeId: { type: [Number, String] },
  },
  data: () => {
    return {
      localReference: '',
      localDetails: '',
      localStatusTypeId: null,
    };
  },
  computed: {
    ...mapState('constants', {
      readonly: state => !state.permissions.fleet_control_edit_pre_start_tickets,
      statusTypes: state => state.preStartTicketStatusTypes,
    }),
  },
  mounted() {
    this.localReference = this.reference;
    this.localDetails = this.details;
    this.localStatusTypeId =
      this.statusTypeId || attributeFromList(this.statusTypes, 'name', 'raised', 'id');
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    formatDate(date) {
      return formatDateRelativeToIn(date, this.$timely.current.timezone);
    },
    onSubmit() {
      this.close({
        reference: this.localReference,
        details: this.localDetails,
        statusTypeId: this.localStatusTypeId,
      });
    },
  },
};
</script>

<style>
.pre-start-create-ticket-modal-wrapper .modal-container {
  max-width: 40rem;
}

.pre-start-create-ticket-modal .title {
  font-size: 2rem;
  text-align: center;
}

.pre-start-create-ticket-modal .separator {
  height: 1rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #677e8c;
}

.pre-start-create-ticket-modal table {
  width: 100%;
  table-layout: fixed;
}

.pre-start-create-ticket-modal tr {
  height: 3rem;
}

.pre-start-create-ticket-modal tr .key {
  font-size: 1.75rem;
  width: 11rem;
  text-transform: capitalize;
}

.pre-start-create-ticket-modal tr .value {
  font-size: 1.4rem;
}

.pre-start-create-ticket-modal tr input,
.pre-start-create-ticket-modal tr .auto-size-text-area,
.pre-start-create-ticket-modal tr .drop-down {
  width: 100%;
}

.pre-start-create-ticket-modal .drop-down .v-select {
  height: 2.5rem;
  text-transform: capitalize;
}

.pre-start-create-ticket-modal .actions {
  display: flex;
  width: 100%;
}

.pre-start-create-ticket-modal .actions button {
  width: 100%;
  height: 2.5rem;
  margin: 0.1rem;
  font-size: 1.25rem;
}
</style>