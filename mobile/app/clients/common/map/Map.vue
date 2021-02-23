<template>
  <GridLayout class="map" width="100%" columns="*, *, *, *, *" rows="*, *, *, *, *, *, *">
    <MapView
      :colSpan="5"
      :rowSpan="7"
      :latitude="position.latitude"
      :longitude="position.longitude"
      :zoom="zoom.level"
      :bearing="orientation.bearing"
      :tilt="orientation.tilt"
      :padding="padding"
      :minZoom="zoom.min"
      :maxZoom="zoom.max"
      @mapReady="onMapReady"
      @cameraChanged="onCameraChange"
    />

    <!-- Destination Selector -->
    <DestinationSelector
      v-show="showDestinationSelector && !show.legend && !show.options"
      row="0"
      col="1"
      colSpan="3"
      :value="clusterPath.targetId"
      :distance="clusterPath.distance"
      :locations="locations"
      :haulTruckDispatch="haulTruckDispatch"
      @change="onDestinationChange"
    />

    <!-- Buttons for the legend -->
    <Toggle
      v-show="showLegend"
      row="0"
      col="0"
      class="map-btn"
      :value="show.legend"
      :circular="true"
      :options="[
        { id: false, text: 'show legend' },
        { id: true, text: 'hide legend' },
      ]"
      textTransform="capitalize"
      @input="toggleShowLegend"
    />

    <Toggle
      v-show="canShowLegend"
      row="1"
      col="0"
      class="map-btn"
      :value="show.geofences"
      :circular="true"
      :options="options.geofence"
      textTransform="capitalize"
      @input="toggleShowGeofences"
    />

    <!-- Buttons for options -->
    <Toggle
      v-show="showOptions"
      row="0"
      col="4"
      class="map-btn"
      :value="show.options"
      :circular="true"
      :options="[
        { id: false, text: 'show options' },
        { id: true, text: 'hide options' },
      ]"
      textTransform="capitalize"
      @input="toggleShowOptions"
    />

    <Button
      v-show="canShowOptions"
      row="0"
      col="3"
      class="map-btn"
      textTransform="capitalize"
      text="Recenter"
      @tap="onRecenter"
    />

    <Button
      v-show="canShowOptions"
      row="0"
      col="2"
      class="map-btn"
      textTransform="capitalize"
      text="Reset Zoom"
      @tap="onResetZoom"
    />

    <Button
      v-show="canShowOptions"
      row="0"
      col="1"
      class="map-btn"
      textTransform="capitalize"
      text="Reset Bearing"
      @tap="onResetBearing"
    />

    <Toggle
      v-show="canShowOptions"
      row="1"
      col="4"
      class="map-toggle"
      :value="mapType"
      :options="options.mapType"
      @input="setMapType"
    />

    <Toggle
      v-show="canShowOptions"
      row="2"
      col="4"
      class="map-toggle"
      :value="follow"
      :options="options.follow"
      @input="setFollow"
    />

    <Toggle
      v-show="canShowOptions"
      row="3"
      col="4"
      class="map-toggle"
      :value="useTilt"
      :options="options.tilt"
      @input="setTilt"
    />

    <DropDown
      v-show="canShowOptions"
      row="4"
      col="4"
      class="map-btn"
      :value="gpsSource"
      :options="gpsSources"
      textTransform="capitalize"
      @input="onGpsSourceChange"
    />

    <CenteredLabel
      v-show="error"
      row="6"
      col="1"
      colSpan="3"
      class="map-error"
      :text="error"
      horizontalAlignment="center"
    />
  </GridLayout>
</template>

<script>
const Google = com.google.android.gms.maps;
const Color = require('tns-core-modules/color').Color;
const ImageSource = require('tns-core-modules/image-source/image-source');
import DropDown from '../DropDown.vue';
import Toggle from '../Toggle.vue';
import CenteredLabel from '../CenteredLabel.vue';
import DestinationSelector from './DestinationSelector.vue';
import { attributeFromList } from '../../code/helper';
import { getCameraUpdate } from './map.js';
import { ShapeManager, defaultMarkerOpts } from './shapeManager.js';
import { toColor } from './bitmap';

const INDICATOR_SIZE = 120;
const MIN_OLD_AGE = 60 * 1000;
const MAX_STOP_SPEED = 0.2;
const FOLLOW_TILT = 60;
const DEFAULT_ZOOM = 15;

const MAP_TYPE = {
  NONE: 0,
  NORMAL: 1,
  SATELLITE: 2,
  TERRAIN: 3,
  HYBRID: 4,
};

const GEOFENCE_COLOR = {
  closed: toGeoColor('black', 0.2),
  production: toGeoColor('green', 0.2),
  stockpile: toGeoColor('orange', 0.2),
  waste_stockpile: toGeoColor('chocolate', 0.2),
  waste_dump: toGeoColor('saddlebrown', 0.2),
  crusher: toGeoColor('blue', 0.2),
  fuel_bay: toGeoColor('yellow', 0.2),
  parkup: toGeoColor('red', 0.2),
  changeover_bay: toGeoColor('orangered', 0.2),
  maintenance: toGeoColor('gray', 0.2),
  rehab: toGeoColor('darkgreen', 0.2),
  DEFAULT: toGeoColor('black', 1),
};

const STATIC_GEOFENCE = ['parkup', 'fuel_bay', 'crusher', 'changeover_bay', 'maintenance'];

function toGeoColor(fillColor, fillOpacity) {
  return {
    fillColor,
    fillOpacity,
  };
}

function getIndicatorColor(track) {
  const now = Date.now();
  if (!track.timestamp) {
    return 'black';
  }
  if (track.timestamp.getTime() < now - MIN_OLD_AGE) {
    return 'gray';
  }
  if (track.velocity.speed < MAX_STOP_SPEED) {
    return 'red';
  }
  return 'blue';
}

function approxEqual(a, b, epsilon = 0.000001) {
  return Math.abs(a - b) < epsilon;
}

function shouldUpdateMarker(oldPos, newPos) {
  return !oldPos || (!approxEqual(oldPos.lat, newPos.lat) && !approxEqual(oldPos.lng, newPos.lng));
}

function geofenceToShape(geo) {
  const shapeId = `geofence-${geo.id}`;

  const path = geo.geofence.map(({ lat, lng }) => [lat, lng]);

  const { fillColor, fillOpacity } = GEOFENCE_COLOR[geo.type] || GEOFENCE_COLOR.DEFAULT;

  const opts = {
    strokeWidth: 1,
    strokeColor: 'black',
    fillColor,
    fillOpacity,
    meta: {
      shapeType: 'geofence',
      typeId: geo.typeId,
      type: geo.type,
      name: geo.name,
      id: geo.id,
    },
  };

  return {
    shapeId,
    path,
    opts,
  };
}

function arraysEqual(a, b) {
  if (a === b) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }

  const len = a.length;
  for (let i = 0; i < len; ++i) {
    if (a[i] !== b[i]) {
      return false;
    }
  }
  return true;
}

function parseDistance(distance) {
  return isNaN(distance) ? null : distance;
}

function defaultTrackStyler(type, track) {
  if (type === 'myLocation') {
    return {
      icon: '~/assets/markers/HeadingIcon.png',
      color: getIndicatorColor(track),
      scale: 1,
      visible: track.valid,
      rotation: track.velocity.heading,
      anchor: [0.5, 0.5],
      flat: true,
    };
  } else {
    return {
      icon: '~/assets/markers/HeadingIcon.png',
      color: getIndicatorColor(track),
      scale: 0.5,
      visible: true,
      rotation: track.velocity.heading,
      anchor: [0.5, 0.5],
      flat: true,
    };
  }
}

export default {
  name: 'Map',
  components: {
    DropDown,
    Toggle,
    CenteredLabel,
    DestinationSelector,
  },
  props: {
    geofences: { type: Array, default: () => [] },
    showDestinationSelector: { type: Boolean, default: false },
    showOptions: { type: Boolean, default: true },
    showLegend: { type: Boolean, default: true },
    showOthers: { type: [Array, Boolean], default: false },
    trackStyler: { type: Function, default: (_type, _track) => null },
  },
  data: () => {
    const center = {
      latitude: -32.847896,
      longitude: 116.0596581,
    };
    return {
      center,
      position: {
        latitude: center.latitude,
        longitude: center.longitude,
      },
      zoom: {
        level: DEFAULT_ZOOM,
        max: 22,
        min: 0,
      },
      orientation: {
        bearing: 0,
        tilt: 0,
      },
      padding: [5, 5, 5, 5],
      mapType: 'NORMAL',
      selectedRoute: { value: null, text: 'No Route' },
      show: {
        options: false,
        legend: false,
        geofences: true,
      },
      options: {
        follow: [
          { id: true, text: 'follow' },
          { id: false, text: 'free pan' },
        ],
        tilt: [
          { id: true, text: 'tilted' },
          { id: false, text: 'top down' },
        ],
        mapType: ['NORMAL', 'SATELLITE'],
        geofence: [
          { id: true, text: 'hide geofences' },
          { id: false, text: 'show geofences' },
        ],
      },
      follow: true,
      useTilt: false,
      shapeManager: null,
      mapView: null,
      gMap: null,
      error: null,
      clusterPath: {
        targetId: null,
        distance: null,
        clusterIds: [],
      },
      drawnLocations: {},
    };
  },
  computed: {
    ready() {
      return !!this.mapView;
    },
    clusters() {
      return this.$store.state.constants.clusters;
    },
    locations() {
      return this.$store.state.constants.locations.filter(l => l.geofence);
    },
    haulTruckDispatch() {
      return this.$store.state.haulTruck.dispatch;
    },
    shownGeofences() {
      return this.locations.filter(
        l => STATIC_GEOFENCE.includes(l.type) || l.id === this.clusterPath.targetId,
      );
    },
    gpsSource() {
      return this.$store.state.location.source;
    },
    gpsSources() {
      return this.$store.state.location.sources;
    },
    activeLocation() {
      return this.$store.getters['location/location'];
    },
    otherLocations() {
      return this.$store.state.location.otherLocations;
    },
    canShowOptions() {
      return this.showOptions && this.show.options;
    },
    canShowLegend() {
      return this.showLegend && this.show.legend;
    },
  },
  watch: {
    shownGeofences(geofences) {
      this.updateGeofences(geofences);
    },
    activeLocation(location) {
      this.updateMyLocation(location);
    },
    otherLocations(locations) {
      this.updateOtherLocations(locations);
    },
  },
  methods: {
    onMapReady(event) {
      // get key components of the map
      // mapView is https://developers.google.com/maps/documentation/android-sdk/reference/com/google/android/libraries/maps/GoogleMap
      this.mapView = event.object;
      this.gMap = event.object._gMap;

      // configure settings
      this.mapView.settings.mapToolbarEnabled = false;

      // create a shape manager to help with drawing
      this.shapeManager = new ShapeManager(this.mapView);

      this.redraw();
    },
    redraw(force = true) {
      this.updateGeofences(this.shownGeofences);
      this.updateMyLocation(this.activeLocation);
      this.updateOtherLocations(this.otherLocations, force);
    },
    toggleShowOptions() {
      this.show.options = !this.show.options;
      if (this.show.options === true) {
        this.show.legend = false;
      }
    },
    toggleShowLegend() {
      this.show.legend = !this.show.legend;
      if (this.show.legend === true) {
        this.show.options = false;
      }
    },
    toggleShowGeofences(bool) {
      if (!this.shapeManager) {
        console.error('[Map] Cannot toggle geofences. Shape manager nulled');
        return;
      }

      this.show.geofences = bool;
      if (this.ready) {
        this.shapeManager.setVisibilityBy(s => s.meta.shapeType === 'geofence', bool);
      }
    },
    onGpsSourceChange(source) {
      this.$store.commit('location/setSource', source);
      setTimeout(() => {
        this.updateMyLocation(this.activeLocation);
      });
    },
    onResetZoom() {
      this.moveTo({ zoom: DEFAULT_ZOOM });
    },
    onResetBearing() {
      this.moveTo({ bearing: 0 });
    },
    onRecenter() {
      if (this.activeLocation && this.activeLocation.valid === true) {
        const pos = this.activeLocation.position;
        const bearing = this.activeLocation.velocity.heading;

        const opts = {
          lat: pos.lat,
          lng: pos.lng,
          bearing,
        };
        this.moveTo(opts);
      }
    },
    setFollow(useFollow) {
      this.follow = useFollow;
      if (useFollow) {
        this.onRecenter();
      }
    },
    setTilt(useTilt) {
      this.useTilt = useTilt;
      const tilt = useTilt ? FOLLOW_TILT : 0;
      this.moveTo({ tilt });
    },
    onCameraChange({ camera }) {
      this.zoom.level = camera.zoom;
      this.orientation.bearing = camera.bearing;
      this.orientation.tilt = camera.tilt;
      this.position.latitude = camera.latitude;
      this.position.longitude = camera.longitude;
    },
    updateGeofences(geofences) {
      if (!this.ready) {
        return;
      }

      if (!this.shapeManager) {
        console.error('[Map] Cannot update geofences. Shape manager nulled');
        return;
      }

      // remove all locations
      this.shapeManager.clearBy(s => s.meta.shapeType === 'geofence');

      // create new geofences
      geofences.forEach(l => {
        const { shapeId, path, opts } = geofenceToShape(l);
        opts.visible = this.show.geofences;
        this.shapeManager.drawPolygon(shapeId, path, opts);
      });
    },
    updateMyLocation(track) {
      if (!this.ready || !track) {
        return;
      }

      if (!this.shapeManager) {
        console.error('[Map] Cannot update my location. Shape manager nulled');
        return;
      }

      // get the route information (async)
      this.setClusterPath(track);

      this.shapeManager.drawMarker(
        'myLocation',
        track.position,
        this.styleTrack('myLocation', track),
      );

      // if user is following self, center on track
      if (this.follow) {
        this.onRecenter();
      }

      // set a GPS error if there is no track for selected location source
      this.error = track.valid ? '' : `Trouble finding '${this.gpsSource}' location ...`;
    },
    updateOtherLocations(tracks, force = false) {
      if (!this.ready) {
        return;
      }

      if (!this.shapeManager) {
        console.error('[Map] Cannot update other locations. Shape manager nulled');
        return;
      }

      let toDraw = tracks.slice();
      const allowedOthers = this.showOthers;
      if (allowedOthers === false) {
        return;
      }

      if (Array.isArray(allowedOthers)) {
        toDraw = toDraw.filter(t => allowedOthers.includes(t.assetName));
      }

      const drawnLocations = this.drawnLocations;

      toDraw.forEach(track => {
        const oldPos = drawnLocations[track.assetName];
        if (force || shouldUpdateMarker(oldPos, track.position)) {
          drawnLocations[track.assetName] = track.position;
          this.shapeManager.drawMarker(
            track.assetName,
            track.position,
            this.styleTrack('other', track),
          );
        }
      });
    },
    setClusterPath(track) {
      if (!track || !track.valid) {
        console.error('[Map] Cannot set cluster path no valid position');
        return;
      }

      const locationId = this.clusterPath.targetId;

      if (!locationId) {
        this.clearClusterPath();
        return;
      }

      const payload = {
        position: track.position,
        location_id: locationId,
      };

      this.$channel
        .push('cluster:distance to', payload)
        .receive('ok', ({ distance, cluster_ids, location_id }) => {
          if (location_id !== locationId) {
            console.error('[Map] Distance to returned wrong location. Race condition found');
            return;
          }
          const oldIds = this.clusterPath.clusterIds;

          this.clusterPath = {
            targetId: locationId,
            distance: parseDistance(distance),
            clusterIds: cluster_ids,
          };

          // if ids equal, dont redraw (would be slow)
          if (arraysEqual(oldIds, cluster_ids)) {
            console.log('[Map] No changes in ids. No redraw');
            return;
          }

          // draw the cluster path
          const clusters = this.clusters;

          const path = cluster_ids
            .map(id => {
              const pos = (clusters[id] || {}).position;
              return pos ? [pos.lat, pos.lng] : null;
            })
            .filter(pos => pos);

          if (path.length < 2) {
            this.clearClusterPath();
          } else {
            if (this.shapeManager) {
              this.shapeManager.drawPolyline('clusterPath', path, {
                color: 'orange',
                width: 15,
                cap: 'round',
              });
            }
          }
        });
    },
    clearClusterPath() {
      if (!this.shapeManager) {
        console.error('[Map] Cannot clear cluster path. Shape manager nulled');
        return;
      }
      this.shapeManager.clearBy(s => s.shapeId === 'clusterPath');
    },
    onDestinationChange(locationId) {
      this.clusterPath.targetId = locationId;
      this.updateMyLocation(this.activeLocation);
    },
    setMapType(type = '') {
      this.mapType = type;
      const value = MAP_TYPE[type.toUpperCase()] || MAP_TYPE['NORMAL'];
      this.gMap.setMapType(value);
    },
    moveTo(opts = {}) {
      if (!this.gMap) {
        console.error('[Map] not ready to move');
        return;
      }

      const coord = {
        lat: this.position.latitude,
        lng: this.position.longitude,
        zoom: this.zoom.level,
        tilt: this.orientation.tilt,
        bearing: this.orientation.bearing,
      };

      const cameraUpdate = getCameraUpdate({ ...coord, ...opts });
      this.gMap.animateCamera(cameraUpdate);
    },
    styleTrack(type, track) {
      const customStyle = this.trackStyler(type, track) || {};
      return { ...defaultTrackStyler(type, track), ...customStyle };
    },
  },
};
</script>

<style >
.route-info .map-label {
  color: black;
}

.map .map-btn,
.map .route-selector .dropdown-btn,
.map .route-selector .dropdown-btn-ellipses {
  font-size: 22;
}

.map .map-toggle .toggle-btn {
  font-size: 18;
}

.map .map-error {
  background-color: rgba(102, 101, 101, 0.712);
  font-size: 24;
  color: black;
  border-radius: 15;
}
</style>