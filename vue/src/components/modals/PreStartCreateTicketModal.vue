<template>
  <div class="pre-start-create-ticket-modal">
    <div v-if="controlText" class="control-info">
      <div class="control-text">{{ controlText }}</div>
      <div class="control-comment">{{ controlComment }}</div>
    </div>

    <table>
      <tr>
        <td class="key">Reference</td>
        <td class="value">
          <input type="text" class="typeable" v-model="reference" />
        </td>
      </tr>
      <tr>
        <td class="key">Details</td>
        <td class="value">
          <AutoSizeTextArea v-model="details" />
        </td>
      </tr>
      <tr>
        <td class="key">Status Type</td>
        <td class="value">
          <DropDown v-model="statusTypeId" :items="statusTypes" />
        </td>
      </tr>
    </table>

    <div class="actions">
      <button class="hx-btn" @click="onCreate()">Create</button>
      <button class="hx-btn" @click="onClose()">Cancel</button>
    </div>
  </div>
</template>

<script>
import DropDown from '@/components/dropdown/DropDown.vue';
import AutoSizeTextArea from '@/components/AutoSizeTextArea.vue';
import { attributeFromList } from '@/code/helpers';
export default {
  name: 'PreStartCreateTicketModal',
  wrapperClass: 'pre-start-create-ticket-modal-wrapper',
  components: {
    DropDown,
    AutoSizeTextArea,
  },
  props: {
    controlText: { type: String },
    controlComment: { type: String },
  },
  data: () => {
    return {
      reference: '',
      details: '',
      statusTypeId: null,
    };
  },
  computed: {
    statusTypes() {
      return this.$store.state.constants.preStartTicketStatusTypes;
    },
  },
  mounted() {
    this.statusTypeId = attributeFromList(this.statusTypes, 'name', 'raised', 'id');
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
  },
};
</script>

<style>
.pre-start-create-ticket-modal-wrapper .modal-container {
  max-width: 32rem;
}

.pre-start-create-ticket-modal table {
  width: 100%;
  table-layout: fixed;
}

.pre-start-create-ticket-modal tr .key {
  width: 11rem;
}

.pre-start-create-ticket-modal tr input,
.pre-start-create-ticket-modal tr .auto-size-text-area,
.pre-start-create-ticket-modal tr .dropdown-wrapper {
  width: 100%;
}

.pre-start-create-ticket-modal .dropdown-wrapper {
  height: 2.5rem;
  text-transform: capitalize;
}
</style>