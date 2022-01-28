<template>
  <div class="mass-time-allocation-assignment-modal">
    <div class="title">Mass Time Allocation Assignment</div>
    <TimeAllocationDropDown
      v-model="selectedTimeCodeId"
      :showAll="true"
      placeholder="Select Time Code"
    />

    <AssetSelector v-model="selectedAssetIds" :assets="assets" />

    <div class="actions">
      <button
        class="hx-btn"
        :disabled="!selectedTimeCodeId || selectedAssetIds.length === 0"
        @click="onSubmit()"
      >
        Submit
      </button>
      <button class="hx-btn" @click="onCancel()">Cancel</button>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';

import AssetSelector from '@/components/chat_overlay/message_box/AssetSelector.vue';
import TimeAllocationDropDown from '@/components/TimeAllocationDropDown.vue';

export default {
  name: 'MassTimeAllocationAssignmentModal',
  wrapperClass: 'mass-time-allocation-assignment-modal-wrapper',
  components: {
    AssetSelector,
    TimeAllocationDropDown,
  },
  data: () => {
    return {
      selectedTimeCodeId: null,
      selectedAssetIds: [],
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
    }),
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onSubmit() {
      const payload = {
        asset_ids: this.selectedAssetIds,
        time_code_id: this.selectedTimeCodeId,
      };

      this.$channel
        .push('mass set allocations', payload)
        .receive('ok', () => {
          this.$toaster.info(`Mass Allocations | ${payload.asset_ids.length} affected`);
          this.close();
        })
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to set allocations at this time'));
    },
    onCancel() {
      this.close();
    },
  },
};
</script>

<style>
.mass-time-allocation-assignment-modal-wrapper .modal-container {
  max-width: 70rem;
}

.mass-time-allocation-assignment-modal .title {
  font-size: 2rem;
  text-align: center;
  margin-bottom: 0.25rem;
}

.mass-time-allocation-assignment-modal .time-allocation-drop-down {
  margin: 2rem 0;
  width: 100%;
}

.mass-time-allocation-assignment-modal .time-allocation-drop-down .dropdown-wrapper {
  width: 100%;
}

.mass-time-allocation-assignment-modal .actions {
  display: flex;
  width: 100%;
  margin-bottom: 0.25rem;
  border-bottom: 1px solid #677e8c;
}

.mass-time-allocation-assignment-modal .actions button {
  width: 100%;
  margin: 0.1rem;
}

.mass-time-allocation-assignment-modal .actions button:disabled {
  background-color: #333b41;
  color: #757575;
  cursor: default;
}
</style>