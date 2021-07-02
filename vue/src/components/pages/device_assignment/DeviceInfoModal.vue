<template>
  <div class="device-info-modal">
    <h1 class="title">Device '{{ device.formattedDeviceName }}' Details</h1>
    <div class="object-editor-wrapper">
      <ObjectEditor v-model="details" />
    </div>

    <div class="actions">
      <button class="hx-btn" @click="onReset">Reset</button>
      <button class="hx-btn" @click="onSubmit">Submit</button>
    </div>
  </div>
</template>

<script>
import LoadingModal from '../../modals/LoadingModal.vue';
import ObjectEditor from './ObjectEditor.vue';
export default {
  name: 'DeviceInfoModal',
  wrapperClass: 'device-info-modal-wrapper',
  components: {
    ObjectEditor,
  },
  props: {
    device: { type: Object, default: () => ({}) },
  },
  data: () => {
    return {
      details: {},
      newKey: null,
      newValue: null,
    };
  },
  watch: {
    device() {
      this.onReset();
    },
  },
  mounted() {
    this.onReset();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onAdd() {
      if (!this.newKey || !this.newValue) {
        return;
      }

      this.details = { ...this.details, [this.newKey]: this.newValue };
    },
    onReset() {
      this.details = JSON.parse(JSON.stringify(this.device.deviceDetails || {}));
    },
    onSubmit() {
      const deviceId = (this.device || {}).deviceId;

      if (!deviceId) {
        console.error('[DeviceInfo] No valid device id');
        return;
      }

      const payload = {
        device_id: deviceId,
        details: this.details || {},
      };

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'Updating device details' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('set device details', payload)
        .receive('ok', () => {
          loading.close();
          this.$toaster.info('Device details updated');
          this.onClose();
        })
        .receive('error', resp => {
          loading.close();
          this.$toaster.error(resp.error || 'Unable to update device details');
        })
        .receive('timeout', () => {
          loading.close();
          this.$toaster.noComms('Unable to update device details');
        });
    },
  },
};
</script>

<style>
.device-info-modal-wrapper .modal-container {
  max-width: 45rem;
}

.device-info-modal h1 {
  text-align: center;
}

.device-info-modal .object-editor-wrapper {
  margin: auto;
  width: 60%;
}

.device-info-modal .actions {
  margin-top: 1rem;
  display: flex;
  width: 100%;
  justify-content: space-between;
}

.device-info-modal .actions .hx-btn {
  width: 49%;
}
</style>