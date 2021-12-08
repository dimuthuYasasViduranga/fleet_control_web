<template>
  <div class="mine-map">
    <div class="map-wrapper">
      <div class="gmap-map">
        <!-- buttons to attach -->
        <div style="display: none">
          <RecenterIcon class="recenter-control" tooltip="right" @click.native="reCenter" />
          <ResetZoomIcon class="reset-zoom-control" tooltip="right" @click.native="resetZoom" />
          <PolygonIcon
            class="geofence-control"
            tooltip="right"
            :highlight="!showAllGeofences"
            @click.native="toggleAllGeofences()"
          />
          <GmapAlertIcon
            class="alert-control"
            tooltip="right"
            :highlight="!showAlerts"
            @click.native="toggleShowAlerts()"
          />
          <GmapClusterIcon
            class="cluster-control"
            tooltip="right"
            :highlight="!useMapClusters"
            @click.native="toggleUseMapClusters()"
          />
          <GmapLabelIcon
            class="label-control"
            tooltip="right"
            :highlight="!showLabels"
            @click.native="toggleShowLabels()"
          />
          <GmapMyPositionIcon class="my-position-control" tooltip="left" />
          <RecenterIcon
            v-show="myLocation"
            class="my-position-recenter-control"
            label="Find My Location"
            tooltip="left"
            @click.native="recenterMyLocation()"
          />

          <div class="g-control asset-selector-control">
            <GMapDropDown
              :value="selectedAssetId"
              :items="assetOptions"
              label="fullname"
              :useScrollLock="true"
              placeholder="Find Asset"
              direction="down"
              @change="onFindAsset"
            />
          </div>
          <div class="g-control asset-type-filter-toggle">
            <Icon
              v-tooltip="{
                classes: ['google-tooltip'],
                trigger: 'hover',
                content: `Toggle Asset Filter`,
                placement: 'left',
              }"
              :class="{ highlight: showAssetFilter }"
              :icon="filterIcon"
              @click="showAssetFilter = !showAssetFilter"
            />
          </div>
          <div v-show="showAssetFilter" class="g-control asset-type-filter">
            <Icon
              v-tooltip="{
                classes: ['google-tooltip'],
                trigger: 'hover',
                content: `Show All`,
                placement: 'top',
              }"
              :icon="showIcon"
              @click="showAllAssetTypes()"
            />
            <Icon
              v-tooltip="{
                classes: ['google-tooltip'],
                trigger: 'hover',
                content: `Hide All`,
                placement: 'top',
              }"
              :icon="hideIcon"
              @click="hideAllAssetTypes()"
            />
            <Icon
              v-for="assetType in assetTypeIcons"
              :key="assetType.type"
              v-tooltip="{
                classes: ['google-tooltip'],
                trigger: 'hover',
                content: `Toggle ${assetType.type}`,
                placement: 'left',
              }"
              :class="{
                highlight: !shownAssetTypes.includes(assetType.type),
              }"
              :icon="assetType.icon"
              @click="onToggleAssetTypeVisibility(assetType.type)"
            />
          </div>
          <div class="debug-control" :class="{ show: debug }" @click="onDebugControl"></div>
        </div>
        <!-- GMap Element -->
        <GmapMap
          ref="gmap"
          :map-type-id="mapType"
          :center="center"
          :zoom="zoom"
          :options="{
            tilt: 0,
          }"
          @zoom_changed="zoomChanged"
          @dragstart="propogateEvent('dragstart')"
          @dragend="propogateEvent('dragend')"
        >
          <g-map-geofences :geofences="shownGeofences" @click="onGeofenceClick" />

          <gmap-circle
            v-for="(center, index) in loadingZones"
            :key="`loading-zone-${index}`"
            :center="center"
            :radius="digUnitLoadingRadius"
            :options="{
              clickable: false,
              zIndex: -10,
              strokeWeight: 0,
              fillColor: 'green',
              fillOpacity: 0.1,
            }"
          />

          <g-map-tracks
            :assets="assets"
            :showAlerts="showAlerts"
            :showLabel="showLabels"
            :clusterSize="useMapClusters ? trackClusterSize : 0"
            :selectedAssetId="selectedAssetId"
            :draggable="debug"
            @click="onAssetClick"
          />

          <g-map-my-position :value="myLocation" />

          <gmap-info-window
            class="info-window"
            :options="pUpOptions"
            :opened="pUpShow"
            :position="pUpPosition"
            @closeclick="pUpShow = false"
          >
            <div class="no-info" v-if="!selected">No information to show</div>

            <template v-else-if="selected.type === 'asset'">
              <AssetInfo :asset="selected.data" />
              <HaulTruckInfo v-if="selected.data.type === 'Haul Truck'" :asset="selected.data" />
              <DigUnitInfo
                v-if="['Excavator', 'Loader'].includes(selected.data.type)"
                :asset="selected.data"
              />
            </template>
            <GeofenceInfo v-else-if="selected.type === 'geofence'" :geofence="selected.data" />
          </gmap-info-window>
        </GmapMap>
      </div>
    </div>
  </div>
</template>

<script>
import { gmapApi } from 'gmap-vue';

import Icon from 'hx-layout/Icon.vue';
import HideIcon from '@/components/icons/Hide.vue';
import ShowIcon from '@/components/icons/Show.vue';
import FilterIcon from '@/components/icons/Filter.vue';

import GMapGeofences from '@/components/gmap/GMapGeofences.vue';
import GMapTracks from '@/components/gmap/GMapTracks.vue';
import GMapMyPosition from '@/components/gmap/GMapMyPosition.vue';
import GMapDropDown from '@/components/gmap/GMapDropDown.vue';
import RecenterIcon from '@/components/gmap/RecenterIcon.vue';
import ResetZoomIcon from '@/components/gmap/ResetZoomIcon.vue';
import PolygonIcon from '@/components/gmap/PolygonIcon.vue';
import GmapAlertIcon from '@/components/gmap/GmapAlertIcon.vue';
import GmapClusterIcon from '@/components/gmap/GmapClusterIcon.vue';
import GmapLabelIcon from '@/components/gmap/GmapLabelIcon.vue';
import GmapMyPositionIcon from '@/components/gmap/GmapMyPositionIcon.vue';

import { attachControl } from '@/components/gmap/gmapControls.js';
import { setMapTypeOverlay } from '@/components/gmap/gmapCustomTiles.js';

import AssetInfo from './info/AssetInfo.vue';
import HaulTruckInfo from './info/HaulTruckInfo.vue';
import DigUnitInfo from './info/DigUnitInfo.vue';
import GeofenceInfo from './info/GeofenceInfo.vue';
import { attributeFromList } from '@/code/helpers';

const DIG_UNIT_LOADING_RADIUS = 30;

function fromLatLng(latLng) {
  return {
    lat: latLng.lat(),
    lng: latLng.lng(),
  };
}

export default {
  name: 'Map',
  components: {
    Icon,
    GMapDropDown,
    GMapGeofences,
    GMapTracks,
    GMapMyPosition,
    AssetInfo,
    HaulTruckInfo,
    DigUnitInfo,
    GeofenceInfo,
    RecenterIcon,
    ResetZoomIcon,
    PolygonIcon,
    GmapAlertIcon,
    GmapClusterIcon,
    GmapLabelIcon,
    GmapMyPositionIcon,
  },
  props: {
    assets: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
    activeLocations: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
    shownAssetTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      // dynamic map properties
      mapType: 'satellite',
      showAllGeofences: false,
      showAlerts: true,
      useMapClusters: false,
      showAssetFilter: false,
      showLabels: true,
      defaults: {
        zoom: 0,
        center: {
          lat: 0,
          lng: 0,
        },
      },

      center: {
        lat: 0,
        lng: 0,
      },
      zoom: 0,

      // popup settings
      pUpShow: false,
      pUpOptions: {
        pixelOffset: {
          width: 0,
          height: -25,
        },
      },
      pUpPosition: null,
      selected: null,

      // track properties
      trackClusterSize: 35,
      digUnitLoadingRadius: DIG_UNIT_LOADING_RADIUS,
      debug: false,
      hideIcon: HideIcon,
      showIcon: ShowIcon,
      filterIcon: FilterIcon,
    };
  },
  computed: {
    google: gmapApi,
    mapManifest() {
      return this.$store.state.constants.mapManifest;
    },
    shownGeofences() {
      if (this.showAllGeofences) {
        return this.locations.filter(l => l.type !== 'closed');
      }
      return this.activeLocations;
    },
    selectedAssetId() {
      if (this.selected && this.selected.type === 'asset') {
        return this.selected.data.id;
      }
      return null;
    },
    assetTypeIcons() {
      const icons = this.$store.state.constants.icons || {};

      return this.assetTypes
        .map(t => {
          return {
            type: t.type,
            icon: icons[t.type] || icons.Unknown,
          };
        })
        .sort((a, b) => (a.type || '').localeCompare(b.type || ''));
    },
    assetOptions() {
      return this.assets.map(a => {
        const fullname = a.type ? `${a.name} (${a.type})` : a.name;
        return {
          id: a.id,
          name: a.name,
          type: a.type,
          fullname,
        };
      });
    },
    myLocation() {
      return this.$geolocation.position;
    },
    loadingZones() {
      return this.assets
        .filter(a => a.secondaryType === 'Dig Unit' && a.track?.position)
        .map(a => a.track?.position);
    },
  },
  watch: {
    assets(newAssets) {
      const selected = this.selected;
      if (selected && selected.type === 'asset') {
        const assetId = selected.data.id;
        // find the asset within the new assets (in case the track has moved)
        const asset = newAssets.find(a => a.id === assetId);

        if (asset) {
          this.selected = {
            type: 'asset',
            data: asset,
          };
          if (this.pUpShow === true) {
            this.openPopup(asset.track.position);
          }
        } else {
          this.closePopup();
        }
      }
    },
  },
  mounted() {
    const center = this.$store.state.constants.mapCenter;
    this.defaults.center = {
      lat: center.latitude,
      lng: center.longitude,
    };

    this.defaults.zoom = this.$store.state.constants.mapZoom;

    this.reCenter();
    this.resetZoom();

    this.gPromise().then(map => {
      // set greedy mode so that scroll is enabled anywhere on the page
      map.setOptions({ gestureHandling: 'greedy' });

      attachControl(map, this.google, '.recenter-control', 'LEFT_TOP');
      attachControl(map, this.google, '.reset-zoom-control', 'LEFT_TOP');
      attachControl(map, this.google, '.geofence-control', 'LEFT_TOP');
      attachControl(map, this.google, '.alert-control', 'LEFT_TOP');
      attachControl(map, this.google, '.cluster-control', 'LEFT_TOP');
      attachControl(map, this.google, '.label-control', 'LEFT_TOP');
      attachControl(map, this.google, '.asset-type-filter-toggle', 'LEFT_TOP');
      attachControl(map, this.google, '.asset-type-filter', 'LEFT_TOP');
      attachControl(map, this.google, '.my-position-control', 'RIGHT_BOTTOM');
      attachControl(map, this.google, '.my-position-recenter-control', 'RIGHT_BOTTOM');
      attachControl(map, this.google, '.asset-selector-control', 'TOP_LEFT');
      attachControl(map, this.google, '.debug-control', 'LEFT_BOTTOM');
      setMapTypeOverlay(map, this.google, this.mapManifest);
    });
  },
  methods: {
    gPromise() {
      return this.$refs.gmap.$mapPromise;
    },
    closePopup() {
      this.pUpShow = false;
      this.selected = null;
    },
    openPopup(position) {
      if (position) {
        this.pUpPosition = position;
      }
      this.pUpShow = true;
    },
    recenterMyLocation() {
      if (!this.myLocation) {
        return;
      }

      this.moveTo(this.myLocation.position);
    },
    reCenter() {
      this.moveTo(this.defaults.center);
    },
    moveTo(latLng) {
      this.gPromise().then(map => map.panTo(latLng));
    },
    zoomChanged(zoomLevel) {
      this.zoom = zoomLevel;
    },
    propogateEvent(topic) {
      this.$emit(topic);
    },
    resetZoom() {
      this.zoom = this.defaults.zoom;
    },
    toggleAllGeofences() {
      this.showAllGeofences = !this.showAllGeofences;
    },
    toggleShowAlerts() {
      this.showAlerts = !this.showAlerts;
    },
    toggleUseMapClusters() {
      this.useMapClusters = !this.useMapClusters;
    },
    toggleShowLabels() {
      this.showLabels = !this.showLabels;
    },
    onGeofenceClick({ geofence, click }) {
      const selected = this.selected;
      if (selected && selected.type === 'geofence' && selected.data.id === geofence.id) {
        this.selected = null;
        this.closePopup();
      } else {
        this.selected = {
          type: 'geofence',
          data: geofence,
        };

        this.openPopup(fromLatLng(click.latLng));
      }
    },
    onAssetClick(asset) {
      const selected = this.selected;
      if (!asset.track) {
        this.selected = null;
        this.closePopup();
      } else if (selected && selected.type === 'asset' && selected.data.id === asset.id) {
        this.closePopup();
      } else {
        this.selected = {
          type: 'asset',
          data: asset,
        };
        this.openPopup(asset.track.position);
      }
    },
    onFindAsset(assetId) {
      const asset = attributeFromList(this.assets, 'id', assetId);

      if (asset) {
        this.onAssetClick(asset);
      } else {
        this.closePopup();
      }
    },
    onDebugControl() {
      const proposedMode = !this.debug ? 'mock' : 'normal';
      this.$channel
        .push('track:set mode', proposedMode)
        .receive('ok', () => {
          this.debug = !this.debug;
          console.log(`[MineMap] Debug set to ${this.debug}`);
        })
        .receive('error', error => console.error(error))
        .receive('timeout', () => console.error('request timed out'));
    },
    onToggleAssetTypeVisibility(type) {
      this.$emit('toggle-asset-type-visibility', type);
    },
    showAllAssetTypes() {
      this.$emit('show-all-asset-types');
    },
    hideAllAssetTypes() {
      this.$emit('hide-all-asset-types');
    },
  },
};
</script>

<style>
.mine-map .map-wrapper {
  position: relative;
  height: 800px;
  width: 100%;
  padding-bottom: 3em;
}

.mine-map .gmap-map {
  height: 100%;
  width: 100%;
}

.map-wrapper .gmap-map .vue-map-container {
  height: 100%;
}

.grey-out {
  filter: grayscale(75%);
}

.asset-selector-control {
  display: flex;
  background-color: white;
}

.asset-selector-control:hover {
  background-color: white;
}

.asset-selector-control .gmap-dropdown {
  width: 20rem;
}

.asset-type-filter-toggle {
  margin: 0;
  width: 38px;
  height: 38px;
}

.asset-type-filter-toggle .hx-icon {
  width: 100%;
  height: 100%;
  padding: 5px 0;
}

.asset-type-filter-toggle .hx-icon svg {
  stroke: black;
}

.asset-type-filter {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  align-content: center;
  justify-content: space-between;
  width: 84px;
  margin-left: -1px;
  margin-right: -1px;
  height: auto;
}



.asset-type-filter-toggle .hx-icon:hover,
.asset-type-filter-toggle .hx-icon.highlight,
.asset-type-filter .hx-icon:hover,
.asset-type-filter .hx-icon.highlight {
  background-color: rgb(189, 189, 189);
}

.asset-type-filter .hx-icon svg {
  stroke: black;
}

@media screen and (max-width: 560px) {
  .asset-selector-control {
    display: none;
  }
}

/* special invisible debug control */
.mine-map .g-control[g-position='LEFT_BOTTOM'] {
  background-color: transparent;
  box-shadow: none;
  --webkit-box-shadow: none;
  width: 1rem;
  height: 1rem;
}

.mine-map .debug-control {
  background-color: transparent;
  width: 100%;
  height: 100%;
}

.mine-map .debug-control.show {
  background-color: grey;
}

/* ------ dim all other assets when one is selected ------- */
.mine-map .not-selected {
  opacity: 0.6 !important;
}

@media screen and (max-width: 820px) {
  .mine-map .map-wrapper {
    padding-left: 2rem;
    padding-right: 2rem;
  }
}
</style>
