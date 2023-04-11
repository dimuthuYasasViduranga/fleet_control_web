<template>
  <modal
    class="asset-assignment"
    :show="show"
    @close="close()"
    @tran-close-end="setSelectedAsset(null)"
  >
    <div class="asset-assignment-info">
      <component
        :is="componentType"
        :asset="selectedAsset"
        :crossScale="0.4"
        @submit="onSubmit"
        @reset="onReset"
        @cancel="close()"
      />
    </div>
  </modal>
</template>

<script>
import Modal from '../modals/Modal.vue';

import AssignDefault from './AssignDefault.vue';
import AssignHaulTruck from './AssignHaulTruck.vue';
import AssignDigUnit from './AssignDigUnit.vue';

function toLocalAsset(asset) {
  if (!asset) {
    return;
  }
  return {
    id: asset.id,
    name: asset.name,
    typeId: asset.typeId,
    type: asset.type,
    operator: { ...asset.operator },
    activeTimeCodeId: asset.activeTimeAllocation.timeCodeId,
  };
}

export default {
  name: 'AssetAssignmentModal',
  components: {
    Modal,
    AssignDefault,
    AssignHaulTruck,
    AssignDigUnit,
  },
  data: () => {
    return {
      show: false,
      selectedAsset: {},
    };
  },
  computed: {
    fullAssets() {
      return this.$store.getters.fullAssets;
    },
    componentType() {
      switch ((this.selectedAsset || {}).type) {
        case 'Haul Truck':
          return AssignHaulTruck;
        case 'Excavator':
        case 'Loader':
          return AssignDigUnit;
      }
      return AssignDefault;
    },
  },
  created() {
    this.$eventBus.$on('asset-assignment-open', this.open);
  },
  methods: {
    close() {
      this.show = false;
    },
    open(assetId) {
      const asset = this.fullAssets.find(a => a.id === assetId);

      if (!asset) {
        console.error(`[AssetAssignModal] No asset matching id '${assetId}'`);
        this.setSelectedAsset(null);
        return;
      }

      this.setSelectedAsset(asset);
      this.show = true;
    },
    setSelectedAsset(asset) {
      this.selectedAsset = toLocalAsset(asset);
    },
    onReset() {
      this.open((this.selectedAsset || {}).id);
    },
    onSubmit(timeCodeId) {
      const asset = this.selectedAsset;
      if (asset && timeCodeId !== asset.activeTimeCodeId) {
        const allocation = {
          asset_id: asset.id,
          time_code_id: timeCodeId,
          start_time: Date.now(),
          end_time: null,
          deleted: false,
        };

        this.$channel.push('time-allocation:set', allocation);
      }

      this.close();
    },
  },
};
</script>

<style>
@import '../../assets/styles/hxInput.css';

.asset-assignment {
  font-family: 'GE Inspira Sans', sans-serif;
  color: #b6c3cc;
}

.asset-assignment .modal-container-wrapper {
  height: 100%;
  width: 100%;
  padding: 2rem 3rem;
}

.asset-assignment .modal-container {
  height: auto;
  max-width: 38rem;
}

.asset-assignment table {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
}

.asset-assignment .row {
  height: 3rem;
}

.asset-assignment .row .key {
  font-size: 2rem;
  width: 15rem;
}
</style>