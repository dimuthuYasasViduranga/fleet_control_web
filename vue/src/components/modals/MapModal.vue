<template>
  <div class="map-modal">
    <MineMap ref="mine-map" />
  </div>
</template>

<script>
import MineMap from '@/components/pages/mine_map/MineMap.vue';

export default {
  name: 'MapModal',
  components: {
    MineMap,
  },
  props: {
    assetId: Number,
  },
  mounted() {
    if (!this.assetId) {
      return;
    }
    setTimeout(() => {
      this.$refs['mine-map'].$refs.map.onFindAsset(this.assetId);
    }, 100);
  },
};
</script>

<style>
.map-modal .modal-container {
  max-width: 32rem;
}

.map-modal .hxCard {
  background-color: transparent;
  border: none;
  padding: 0;
}

.map-modal .hxCard .hxCardHeader {
  display: none;
}

.map-modal .map-wrapper {
  padding: 0;
}
</style>