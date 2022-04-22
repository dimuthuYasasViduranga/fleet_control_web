<template>
  <div class="mass-logout-modal">
    <div class="title">Mass Logout Modal</div>
    <TimeAllocationDropDown
      :class="{ unchanged: !selectedTimeCodeId }"
      v-model="selectedTimeCodeId"
      :showAll="true"
      placeholder="Select Time Code"
    />

    <AssetSelector v-model="selectedAssetIds" :assets="assetsWithOperators" />

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
import { toLookup } from '@/code/helpers';

export default {
  name: 'MassLogoutModal',
  wrapperClass: 'mass-logout-modal-wrapper',
  components: {
    AssetSelector,
    TimeAllocationDropDown,
  },
  data: () => {
    return {
      selectedAssetIds: [],
      selectedTimeCodeId: null,
    };
  },
  computed: {
    ...mapState('deviceStore', {
      deviceAssignments: state => state.currentDeviceAssignments,
    }),
    ...mapState('constants', {
      assets: state => state.assets,
    }),
    assetsWithOperators() {
      const assetLoggedIn = toLookup(
        this.deviceAssignments,
        da => da.assetId,
        da => !!da.operatorId,
      );

      return this.assets.filter(a => assetLoggedIn[a.id]);
    },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onCancel() {
      this.close();
    },
    onSubmit() {
      const payload = {
        asset_ids: this.selectedAssetIds,
        time_code_id: this.selectedTimeCodeId,
      };

      this.$channel
        .push('mass logout', payload)
        .receive('ok', () => {
          this.$toaster.info(`Mass logout | ${payload.asset_ids.length} affected`);
          this.close();
        })
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to mass logout at this time'));
    },
  },
};
</script>

<style>
.mass-logout-modal-wrapper .modal-container {
  max-width: 70rem;
}

.mass-logout-modal .title {
  font-size: 2rem;
  text-align: center;
  margin-bottom: 0.25rem;
}

.mass-logout-modal .time-allocation-drop-down {
  margin: 2rem 0;
  width: 100%;
}

.mass-logout-modal .time-allocation-drop-down .dropdown-wrapper {
  width: 100%;
}

.mass-logout-modal .time-allocation-drop-down.unchanged {
  border: 1px solid orange;
}

.mass-logout-modal .actions {
  display: flex;
  width: 100%;
  margin-bottom: 0.25rem;
  border-bottom: 1px solid #677e8c;
}

.mass-logout-modal .actions button {
  width: 100%;
  margin: 0.1rem;
}

.mass-logout-modal .actions button:disabled {
  background-color: #333b41;
  color: #757575;
  cursor: default;
}
</style>