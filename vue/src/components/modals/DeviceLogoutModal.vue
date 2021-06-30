<template>
  <div class="device-logout-modal">
    <h1 class="title">Select Exception</h1>
    <div>
      <TimeAllocationDropDown v-model="localTimeCodeId" :allowedTimeCodeIds="allowedTimeCodeIds" />
    </div>
    <div class="actions">
      <button class="hx-btn ok" :disabled="!localTimeCodeId" @click="onOk">Logout</button>
      <button class="hx-btn cancel" @click="onClose()">Cancel</button>
    </div>
  </div>
</template>

<script>
import DropDown from '@/components/dropdown/DropDown.vue';
import TimeAllocationDropDown from '@/components/TimeAllocationDropDown.vue';

export default {
  name: 'DeviceLogoutModal',
  wrapperClass: 'device-logout-modal-wrapper',
  components: {
    TimeAllocationDropDown,
  },
  props: {
    timeCodeId: { type: Number, default: null },
    allowedTimeCodeIds: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      localTimeCodeId: null,
    };
  },
  mounted() {
    if (this.timeCodeId && this.allowedTimeCodeIds.includes(this.timeCodeId)) {
      this.localTimeCodeId = this.timeCodeId;
    }
  },
  methods: {
    onClose(resp) {
      this.$emit('close', resp);
    },
    onOk() {
      this.onClose({ timeCodeId: this.localTimeCodeId });
    },
  },
};
</script>

<style>
@import '../../assets/hxInput.css';

.device-logout-modal-wrapper .modal-container {
  height: auto;
  max-width: 32rem;
}

.device-logout-modal .title {
  font-size: 2rem;
  text-align: center;
}

.device-logout-modal .actions {
  display: flex;
  width: 100%;
  margin-top: 1rem;
}

.device-logout-modal .actions .hx-btn {
  width: 100%;
  font-size: 1rem;
  margin: 0.1rem;
}

.device-logout-modal .actions .hx-btn[disabled] {
  opacity: 0.5;
  cursor: default;
}

.device-logout-modal .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
  font-size: 1.25rem;
}
</style>
