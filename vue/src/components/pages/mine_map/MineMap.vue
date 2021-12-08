<template>
  <hxCard :title="title" :icon="icon">
    <Map
      ref="map"
      :assets="localAssets"
      :assetTypes="assetTypes"
      :activeLocations="activeLocations"
      :locations="locations"
      :icons="icons"
      :shownAssetTypes="shownAssetTypes"
      @dragstart="onDragStart()"
      @dragend="onDragEnd()"
      @toggle-asset-type-visibility="onToggleAssetTypeVisibility"
      @show-all-asset-types="onShowAllAssetTypes()"
      @hide-all-asset-types="onHideAllAssetTypes()"
    />
  </hxCard>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';

import PlantIcon from '../../icons/Map.vue';
import Map from './Map.vue';
import { uniq } from '@/code/helpers';

const STATIC_TYPES = ['parkup', 'maintenance', 'fuel_bay', 'changeover_bay'];
const CANNOT_ALERT_TYPES = ['Light Vehicle', 'Lighting Plant'];

function calculateAlert(asset, track) {
  if (CANNOT_ALERT_TYPES.includes(asset.type)) {
    return;
  }

  const locationType = ((track || {}).location || {}).type;
  const allocation = asset.activeTimeAllocation || {};

  if (!allocation.id) {
    return;
  }

  if ((allocation.name || '').toLowerCase().includes('emergency')) {
    return {
      text: 'Emergency',
      fill: 'orangered',
    };
  }

  if (STATIC_TYPES.includes(locationType)) {
    return;
  }

  if (allocation.name === 'No Task') {
    return {
      text: 'No Task Entered',
      fill: 'gold',
    };
  }

  if (!allocation.isReady) {
    let fill = 'gray';
    switch (allocation.groupName) {
      case 'Standby':
        fill = 'white';
        break;
      case 'Process':
        fill = 'gold';
        break;
    }

    return {
      text: `${allocation.groupName} - ${allocation.name}`,
      fill,
    };
  }
}

export default {
  name: 'MineMap',
  components: {
    hxCard,
    Map,
  },
  data: () => {
    return {
      title: 'Mine Map',
      icon: PlantIcon,
      dragging: false,
      localAssets: [],
      shownAssetTypes: [],
    };
  },
  computed: {
    ...mapState('constants', {
      icons: state => state.icons,
      locations: state => state.locations,
      assetTypes: state => state.assetTypes,
    }),
    ...mapState({
      haulDispatches: state => state.haulTruck.currentDispatches,
      digUnitActivities: state => state.digUnit.currentActivities,
      tracks: state => state.trackStore.tracks,
    }),
    haulTruckLocations() {
      const ids = this.haulDispatches.map(d => [d.loadId, d.dumpId, d.nextId]).flat();
      const uniqIds = uniq(ids);
      return this.locations.filter(l => uniqIds.includes(l.id));
    },
    digUnitLocations() {
      const ids = this.digUnitActivities.map(a => a.locationId);
      const uniqIds = uniq(ids);
      return this.locations.filter(l => uniqIds.includes(l.id));
    },
    activeLocations() {
      const staticLocations = this.locations.filter(l => STATIC_TYPES.includes(l.type));
      const haulLocations = this.haulTruckLocations;
      const digUnitLocations = this.digUnitLocations;

      return uniq(staticLocations.concat(haulLocations).concat(digUnitLocations));
    },
    assets() {
      const tracks = this.tracks;
      return this.$store.getters.fullAssets.map(fa => {
        const track = tracks.find(t => t.assetId === fa.id);

        const allocation = fa.activeTimeAllocation || {};
        const alert = calculateAlert(fa, track);

        return {
          id: fa.id,
          name: fa.name,
          type: fa.type,
          secondaryType: fa.secondaryType,
          operatorName: fa.operator.shortname,
          radioNumber: fa.radioNumber,
          deviceId: fa.deviceId,
          deviceUUID: fa.deviceUUID,
          allocation,
          alert,
          track,
        };
      });
    },
  },
  watch: {
    assets: {
      immediate: true,
      handler() {
        if (!this.dragging) {
          this.updateLocalAssets(this.assets);
        }
      },
    },
    assetTypes: {
      immediate: true,
      handler(assetTypes = []) {
        if (this.shownAssetTypes.length === 0) {
          this.shownAssetTypes = assetTypes.map(t => t.type);
        }
      },
    },
  },
  mounted() {
    this.updateLocalAssets(this.assets);
  },
  methods: {
    updateLocalAssets(assets = []) {
      this.localAssets = (assets || []).filter(a => this.shownAssetTypes.includes(a.type)).slice();
    },
    onDragStart() {
      this.dragging = true;
    },
    onDragEnd() {
      this.dragging = false;
    },
    onToggleAssetTypeVisibility(type) {
      if (this.shownAssetTypes.includes(type)) {
        this.shownAssetTypes = this.shownAssetTypes.filter(t => t !== type);
      } else {
        this.shownAssetTypes = this.shownAssetTypes.concat([type]);
      }

      this.updateLocalAssets(this.assets);
    },
    onHideAllAssetTypes() {
      this.shownAssetTypes = [];
      this.updateLocalAssets(this.assets);
    },
    onShowAllAssetTypes() {
      this.shownAssetTypes = this.assetTypes.map(a => a.type);
      this.updateLocalAssets(this.assets);
    },
  },
};
</script>

<style>
@import '../../../assets/googleMaps.css';
.map_wrapper {
  padding-bottom: 2rem;
}
</style>
