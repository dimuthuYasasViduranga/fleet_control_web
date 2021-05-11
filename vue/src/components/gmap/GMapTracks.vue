<template>
  <div class="gmap-tracks">
    <gmap-cluster :gridSize="clusterSize" :zoomOnClick="zoomOnClick">
      <template v-if="!draggable">
        <div v-for="asset in assetsWithTracks" :key="asset.id">
          <gmap-custom-marker
            :class="getMarkerClass(asset)"
            class="gmap-track"
            :marker="asset.track.position"
            alignment="center"
          >
            <div v-if="showAlerts && asset.alert" class="alert">
              <Icon
                v-tooltip="{
                  content: asset.alert.text,
                  classes: ['google-tooltip'],
                  delay: { show: 10, hide: 100 },
                }"
                :style="`stroke: ${asset.alert.stroke || 'black'}; fill: ${
                  asset.alert.fill || 'orangered'
                }`"
                :icon="alertIcon"
                @click.native="onTrackClick(asset, $event)"
              />
            </div>
            <div v-if="showLabel && asset.name" class="label">
              <span>{{ asset.name }}</span>
            </div>

            <component
              :is="getMarker(asset)"
              :scale="1"
              :rotation="asset.track.velocity.heading"
              @click.native="onTrackClick(asset, $event)"
            />
          </gmap-custom-marker>
        </div>
      </template>
      <template v-else>
        <gmap-marker
          v-for="(asset, index) in assetsWithTracks"
          :key="`asset-marker-${index}`"
          :position="asset.track.position"
          :options="{
            clickable: true,
          }"
          :draggable="true"
          @click="onMarkerClick(asset)"
          @dragend="onDragEnd(asset, $event)"
        />
      </template>
    </gmap-cluster>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { gmapApi } from 'gmap-vue';
import GmapCluster from 'gmap-vue/dist/components/cluster';
import GmapCustomMarker from 'vue2-gmap-custom-marker';
import DefaultMarker from './markers/DefaultMarker.vue';
import HaulTruckMarker from './markers/HaulTruckTopDownMarker.vue';
import ExcavatorMarker from './markers/ExcavatorTopDownMarker.vue';
import WaterCartMarker from './markers/WaterCartTopDownMarker.vue';
import LoaderMarker from './markers/LoaderTopDownMarker.vue';
import ScraperMarker from './markers/ScraperTopDownMarker.vue';
import DrillMarker from './markers/DrillTopDownMarker.vue';
import DozerMarker from './markers/DozerTopDownMarker.vue';
import GraderIcon from './markers/GraderTopDownMarker.vue';
import FloatIcon from './markers/FloatTopDownMarker.vue';
import ServiceVehicleIcon from './markers/ServiceVehicleTopDownMarker.vue';
import LightingPlantIcon from './markers/LightingPlantTopDownMarker.vue';
import LightVehicleIcon from './markers/LightVehicleTopDownMarker.vue';

import AlertIcon from '@/components/icons/Alert.vue';

const ICONS = {
  'Haul Truck': HaulTruckMarker,
  Excavator: ExcavatorMarker,
  Watercart: WaterCartMarker,
  Loader: LoaderMarker,
  Scraper: ScraperMarker,
  Scratchy: ExcavatorMarker,
  Drill: DrillMarker,
  Dozer: DozerMarker,
  Grader: GraderIcon,
  Float: FloatIcon,
  'Service Vehicle': ServiceVehicleIcon,
  'Lighting Plant': LightingPlantIcon,
  'Light Vehicle': LightVehicleIcon,
};

function createMockTrack(track, position, timestamp = new Date()) {
  const lat = position.lat || 0;
  const lng = position.lng || 0;
  const alt = position.alt || 0;
  const invalid = lat && lng && alt;

  return {
    name: track.name,
    user_id: track.userId,
    position: {
      lat,
      lng,
      alt: track.position.alt,
    },
    speed_ms: track.velocity.speed,
    heading: track.velocity.heading,
    timestamp,
    valid: !invalid,
  };
}

export default {
  title: 'GMapTracks',
  components: {
    Icon,
    GmapCluster,
    GmapCustomMarker,
    DefaultMarker,
    HaulTruckMarker,
    ExcavatorMarker,
    WaterCartMarker,
    LoaderMarker,
    ScraperMarker,
    DrillMarker,
    DozerMarker,
    GraderIcon,
  },
  props: {
    assets: { type: Array, default: () => [] },
    draggable: { type: Boolean, default: false },
    showAlerts: { type: Boolean, default: false },
    showLabel: { type: Boolean, default: false },
    clusterSize: { type: Number, default: 0 },
    zoomOnClick: { type: Boolean, default: true },
    selectedAssetId: { type: Number, default: null },
  },
  data: () => {
    return {
      alertIcon: AlertIcon,
    };
  },
  computed: {
    google: gmapApi,
    assetsWithTracks() {
      return this.assets.filter(a => a.track);
    },
  },
  methods: {
    getMarker(asset) {
      return ICONS[asset.type] || DefaultMarker;
    },
    getMarkerClass(asset) {
      if (!this.selectedAssetId) {
        return;
      }

      return this.selectedAssetId === asset.id ? 'selected' : 'not-selected';
    },
    onTrackClick(asset, event) {
      event.stopPropagation();
      this.$emit('click', asset);
    },
    onMarkerClick(asset) {
      this.$emit('click', asset);
    },
    onDragEnd(asset, { latLng }) {
      const position = { lat: latLng.lat(), lng: latLng.lng() };
      const mockTrack = createMockTrack(asset.track, position);
      this.$channel.push('track:set track', mockTrack);
    },
  },
};
</script>

<style>
.tooltip.google-tooltip {
  display: block;
  z-index: 10000;
  font-family: Roboto, Arial, sans-serif;
}

.tooltip.google-tooltip .tooltip-inner {
  background: white;
  color: black;
  padding: 5px 10px 4px;
}

.gmap-track .alert {
  z-index: 1000;
  position: absolute;
  top: 0;
  left: 0;
  margin: 7%;
}

.gmap-track .alert svg {
  stroke-width: 1.5;
}

.gmap-track .label {
  display: flex;
  flex-direction: row;
  flex-wrap: nowrap;
  align-content: space-between;
  justify-content: center;
  z-index: 1010;
  position: absolute;
  top: -0.75rem;
  margin: 0 auto;
  width: 100%;
  text-align: center;
}

.gmap-track .label span {
  font-size: 1.1rem;
  background-color: rgba(128, 128, 128, 0.719);
  color: white;
  white-space: nowrap;
}
</style>
