<template>
  <hxCard
    ref="page"
    class="asset-overview-page"
    :class="{ fullscreen: isFullscreen }"
    :hideTitle="true"
  >
    <Icon
      v-tooltip="{ content: 'Toggle Fullscreen', placement: 'left' }"
      class="fullscreen-toggle"
      :icon="fullscreenIcon"
      @click="toggleFullscreen()"
    />
    <div class="controls">
      <div class="asset-type-selector">
        <button
          class="hx-btn"
          v-for="(assetType, index) in selectedAssetTypes"
          :key="index"
          :class="{ 'not-selected': !assetType.selected }"
          @click="assetType.selected = !assetType.selected"
        >
          {{ assetType.type }}
        </button>

        <button
          class="hx-btn"
          :class="{ selected: selectedAssetTypes.every(assetType => assetType.selected) }"
          @click="setAssetTypeSelection"
        >
          All
        </button>

        <button class="hx-btn" @click="clearAssetTypeSelection">clear</button>
      </div>
    </div>
    <div class="asset-tiles" :class="{ enlarge: isFullscreen || true }">
      <AssetTile v-for="(asset, index) in fullAssets" :key="index" :asset="asset" />
    </div>
  </hxCard>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';

import AssetTile from '../location_assignment/dnd/asset_tile/AssetTile.vue';

import FullscreenIcon from '@/components/icons/Fullscreen.vue';

import { attributeFromList } from '@/code/helpers';

function toLocalFullAsset(asset, dispatches, activities) {
  const localAsset = {
    id: asset.id,
    name: asset.name,
    type: asset.type,
    typeId: asset.typeId,
    secondaryType: asset.secondaryType,
    operator: asset.operator,
    activeTimeAllocation: asset.activeTimeAllocation,
    radioNumber: asset.radioNumber,
    hasDevice: asset.hasDevice,
    present: asset.present,
    synced: true,
    updatedExternally: false,
  };

  if (localAsset.type === 'Haul Truck') {
    return addHaulTruckInfo(localAsset, dispatches);
  }

  if (localAsset.secondaryType === 'Dig Unit') {
    return addDigUnitInfo(localAsset, activities);
  }

  return localAsset;
}

function addDigUnitInfo(digUnit, activities) {
  const activity = attributeFromList(activities, 'assetId', digUnit.id) || {};
  digUnit.activity = { ...activity };
  return digUnit;
}

function addHaulTruckInfo(haulTruck, dispatches) {
  const dispatch = attributeFromList(dispatches, 'assetId', haulTruck.id) || {};
  haulTruck.dispatch = {
    digUnitId: dispatch.digUnitId || null,
    loadId: dispatch.loadId || null,
    dumpId: dispatch.dumpId || null,
    acknowledged: dispatch.acknowledged || false,
  };
  return haulTruck;
}

export default {
  name: 'AssetOverviewPage',
  components: {
    hxCard,
    Icon,
    AssetTile,
  },
  data: () => {
    return {
      fullscreenIcon: FullscreenIcon,
      isFullscreen: false,
      selectedAssetTypes: [],
    };
  },
  computed: {
    ...mapState('constants', {
      assetTypes: state => state.assetTypes,
    }),
    ...mapState({
      haulTruckDispatches: state => state.haulTruck.currentDispatches,
      digUnitActivities: state => state.digUnit.currentActivities,
    }),
    fullAssets() {
      const allowedTypes = this.selectedAssetTypes.filter(at => at.selected).map(at => at.type);
      return this.$store.getters.fullAssets
        .filter(a => allowedTypes.includes(a.type))
        .map(a => toLocalFullAsset(a, this.haulTruckDispatches, this.digUnitActivities));
    },
  },
  mounted() {
    this.selectedAssetTypes = this.assetTypes.map(at => ({ type: at.type, selected: true }));
  },
  methods: {
    toggleFullscreen() {
      this.isFullscreen = !this.isFullscreen;
    },
    clearAssetTypeSelection() {
      this.selectedAssetTypes.forEach(t => (t.selected = false));
    },
    setAssetTypeSelection() {
      this.selectedAssetTypes.forEach(t => (t.selected = true));
    },
  },
};
</script>

<style>
.asset-overview-page.fullscreen {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  margin: 0;
  z-index: 101;
}

.asset-overview-page .fullscreen-toggle {
  cursor: pointer;
  position: absolute;
  right: 0;
  margin-top: 1rem;
  margin-right: 1rem;
}

.asset-overview-page .fullscreen-toggle:hover {
  opacity: 0.5;
}

/* asset type selector */
.asset-overview-page .asset-type-selector {
  width: 100%;
  display: flex;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.asset-overview-page .asset-type-selector .hx-btn {
  height: 3rem;
  margin: 0.05rem 0;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
}

.asset-overview-page .asset-type-selector .hx-btn.not-selected {
  opacity: 0.5;
}

.asset-overview-page .asset-tiles {
  display: flex;
  flex-wrap: wrap;
}

.asset-overview-page .asset-tile {
  /* background-color: transparent; */
}

/* make the full screen tiles bigger */
.asset-overview-page .asset-tiles.enlarge .asset-tile {
  width: 10rem;
  height: 10rem;
}
</style>