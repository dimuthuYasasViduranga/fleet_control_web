<template>
  <div class="traversal-map">
    <div class="map-wrapper">
      <div class="gmap-map">
        <div style="display: none">
          <PolygonIcon
            ref="geofence-control"
            tooltip="right"
            :highlight="!showLocations"
            @click.native="toggleShowLocations()"
          />
          <div ref="asset-type-selector-control" class="g-control asset-type-selector-control">
            <GMapDropDown
              :value="selectedAssetTypeId"
              :options="assetTypes"
              label="type"
              placeholder="Set Asset Type"
              direction="down"
              @change="onSelectAssetType"
            />
          </div>
          <div ref="reset-markers" class="g-control reset-markers" @click="resetMarkers()">
            Reset Markers
          </div>
          <div ref="alert-control" class="g-control alert-control">
            <div v-if="journey.distance === Infinity || journey.distance == null">No Route</div>
            <div v-else>Distance: ~{{ (journey.distance / 1000).toFixed(1) }} km</div>
          </div>
        </div>
        <GmapMap
          ref="gmap"
          :map-type-id="mapType"
          :center="{ lat: 0, lng: 0 }"
          :zoom="zoom"
          @zoom_changed="zoomChanged"
          :options="{
            tilt: 0,
          }"
        >
          <g-map-geofences
            v-if="showLocations"
            :geofences="locations"
            :options="{ zIndex: -1, fillOpacity: 0.2, strokeOpacity: 0.2 }"
          />

          <!-- draw markers -->
          <gmap-marker
            v-for="marker in [markerEnd, markerStart]"
            :key="`marker-${marker.name}`"
            :position="marker.position"
            :options="{
              clickable: true,
            }"
            :icon="marker.icon"
            :draggable="true"
            @drag="onMarkerDrag(marker, $event)"
            @dragend="onMarkerDragEnd(marker, $event)"
          />

          <GMapLabel
            v-for="[marker, loc] in [
              [markerEnd, markerEndLocation],
              [markerStart, markerStartLocation],
            ]"
            :key="`label-${marker.name}`"
            :position="marker.position"
          >
            <div v-if="loc" class="label">
              {{ loc.extendedName }}
            </div>
          </GMapLabel>

          <!-- draw the graph as polylines -->
          <gmap-polyline
            v-for="(poly, index) in routePolylines"
            :key="`polyline-${index}`"
            :path="poly.path"
            :options="{
              strokeColor: 'black',
              strokeWeight: 6,
              icons: poly.icons,
            }"
          />

          <!-- draw route as polyline -->
          <gmap-polyline
            :path="journey.path"
            :options="{
              strokeColor: journey.color,
              strokeWeight: journey.width,
              strokeOpacity: journey.opacity,
              zIndex: 5,
            }"
          />

          <!-- debug node ids -->
          <!-- <GMapLabel v-for="v in graph.getVerticesList()" :key="v.id" :position="v.data">
            {{ v.id }}
          </GMapLabel> -->
        </GmapMap>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { gmapApi } from 'gmap-vue';
import GMapGeofences from '@/components/gmap/GMapGeofences.vue';
import PolygonIcon from '@/components/gmap/PolygonIcon.vue';
import GMapDropDown from '@/components/gmap/GMapDropDown.vue';
import GMapLabel from '@/components/gmap/GMapLabel.vue';

import { setMapTypeOverlay } from '@/components/gmap/gmapCustomTiles';
import { attachControl } from '@/components/gmap/gmapControls';
import { fromRestrictedRoute, fromRoute } from '@/code/truck_routes/graph';
import { coordsObjsToCoordArrays, locationFromPoint } from '@/code/truck_routes/turfHelpers';
import turf from '@/code/truck_routes/turf';
import { graphToSegments, segmentsToPolylines } from './common';
import { JourneySelector } from '@/code/truck_routes/journey_selector.js';

const DRAG_UPDATE_INTERVAL = 50;
const ROUTE_USED_COLOR = 'darkred';
const ROUTE_USED_OPACITY = 1;
const ROUTE_WIDTH = 10;
const START_ICON_URL = `http://maps.google.com/mapfiles/kml/paddle/go.png`;
const END_ICON_URL = `http://maps.google.com/mapfiles/kml/paddle/stop.png`;

function createLocationToVerticesLookup(locations, graph) {
  if (!graph || locations.length === 0) {
    return {};
  }

  const vertices = graph.getVerticesList().map(v => {
    return {
      point: turf.point([v.data.lng, v.data.lat]),
      data: {
        id: v.id,
        vertexId: v.data.vertexId,
        lat: v.data.lat,
        lng: v.data.lng,
      },
    };
  });
  return locations.reduce((acc, l) => {
    const coords = coordsObjsToCoordArrays(l.geofence);
    const polygon = turf.polygon([coords]);
    acc[l.id] = vertices.filter(v => turf.booleanWithin(v.point, polygon)).map(v => v.data);
    return acc;
  }, {});
}

function edgesToSegments(graph, edgeIds) {
  const edgeLookup = edgeIds.reduce((acc, id) => {
    acc[id] = true;
    return acc;
  }, {});

  return graphToSegments(graph)
    .map(s => {
      const aId = s.edges.find(e => e.endVertexId === s.vertexBId)?.data?.edgeId;
      const bId = s.edges.find(e => e.endVertexId === s.vertexAId)?.data?.edgeId;

      const e1 = edgeLookup[aId];
      const e2 = edgeLookup[bId];

      if (!e1 && !e2) {
        return;
      }

      if (e1 && !e2) {
        s.direction = 'positive';
      } else if (!e1 && e2) {
        s.direction = 'negative';
      }

      return s;
    })
    .filter(s => s);
}

export default {
  name: 'TraversalMap',
  components: {
    GMapGeofences,
    PolygonIcon,
    GMapDropDown,
    GMapLabel,
  },
  props: {
    assetTypes: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    route: { type: Object },
  },
  data: () => {
    return {
      mapType: 'satellite',
      zoom: 0,
      markerStart: {
        name: 'start',
        position: { lat: 0, lng: 0 },
        icon: START_ICON_URL,
        pendingPosition: null,
      },
      markerEnd: {
        name: 'end',
        position: { lat: 0, lng: 0 },
        icon: END_ICON_URL,
        pendingPosition: null,
      },
      showLocations: true,
      selectedAssetTypeId: null,
    };
  },
  computed: {
    google: gmapApi,
    ...mapState('constants', {
      mapManifest: state => state.mapManifest,
      defaultCenter: ({ mapCenter }) => ({ lat: mapCenter.latitude, lng: mapCenter.longitude }),
      defaultZoom: state => state.mapZoom,
    }),
    graph() {
      if (!this.selectedAssetTypeId) {
        return fromRoute(this.route);
      }
      return fromRestrictedRoute(this.route, this.selectedAssetTypeId);
    },
    locationToVerticesLookup() {
      return createLocationToVerticesLookup(this.locations, this.graph);
    },
    segments() {
      return edgesToSegments(this.graph, this.route?.elementIds || []);
    },
    routePolylines() {
      const segments = segmentsToPolylines(this.segments);
      segments.forEach(s => s.icons.forEach(i => (i.icon.fillColor = 'gray')));
      return segments;
    },
    markerStartLocation() {
      return locationFromPoint(this.locations, this.markerStart.position);
    },
    markerEndLocation() {
      return locationFromPoint(this.locations, this.markerEnd.position);
    },
    journeySelector() {
      return new JourneySelector(this.graph, this.locations);
    },
    journey() {
      const source = {
        type: 'position',
        value: this.markerStart.position,
      };

      const destination = {
        type: 'position',
        value: this.markerEnd.position,
      };

      const selector = this.journeySelector;
      const route = selector.between(source, destination);

      if (!route) {
        return;
      }

      return {
        path: route.spatialPath,
        color: ROUTE_USED_COLOR,
        opacity: ROUTE_USED_OPACITY,
        width: ROUTE_WIDTH,
        vertices: route.vertexPath,
        distance: route.totalDistance,
      };
    },
  },
  mounted() {
    this.reCenter();
    this.resetZoom();
    this.resetMarkers();

    this.gPromise().then(map => {
      // set greedy mode so that scroll is enabled anywhere on the page
      map.setOptions({ gestureHandling: 'greedy' });
      attachControl(map, this.google, this.$refs['geofence-control'], 'LEFT_TOP');
      attachControl(map, this.google, this.$refs['asset-type-selector-control'], 'TOP_LEFT');
      attachControl(map, this.google, this.$refs['reset-markers'], 'TOP_LEFT');
      attachControl(map, this.google, this.$refs['alert-control'], 'BOTTOM');
      setMapTypeOverlay(map, this.google, this.mapManifest);
    });
  },
  methods: {
    gPromise() {
      return this.$refs.gmap.$mapPromise;
    },
    reCenter() {
      this.moveTo(this.defaultCenter);
    },
    moveTo(latLng) {
      this.gPromise().then(map => map.panTo(latLng));
    },
    zoomChanged(zoomLevel) {
      this.zoom = zoomLevel;
    },
    resetZoom() {
      this.zoom = this.defaultZoom;
    },
    resetMarkers() {
      this.gPromise().then(map => {
        const center = {
          lat: map.center.lat(),
          lng: map.center.lng(),
        };
        this.markerStart.position = {
          lat: center.lat,
          lng: center.lng - 0.01,
        };
        this.markerEnd.position = { lat: center.lat, lng: center.lng + 0.01 };
      });
    },
    toggleShowLocations() {
      this.showLocations = !this.showLocations;
    },
    onMarkerDrag(marker, event) {
      if (!marker.interval) {
        marker.interval = setInterval(() => {
          if (marker.pendingPosition) {
            marker.position = marker.pendingPosition;
          }
        }, DRAG_UPDATE_INTERVAL);
      }
      marker.pendingPosition = { lat: event.latLng.lat(), lng: event.latLng.lng() };
    },
    onMarkerDragEnd(marker, event) {
      marker.interval = clearInterval(marker.interval);
      marker.position = { lat: event.latLng.lat(), lng: event.latLng.lng() };
    },
    onSelectAssetType(assetTypeId) {
      this.selectedAssetTypeId = assetTypeId;
    },
  },
};
</script>

<style >
.traversal-map {
  height: 60vh;
}
.traversal-map .map-wrapper {
  position: relative;
  height: 100%;
  width: 100%;
}

.traversal-map .gmap-map {
  height: 100%;
  width: 100%;
}

.traversal-map .gmap-map .vue-map-container {
  height: 100%;
}

/* asset selector */
.traversal-map .g-control .asset-type-selector-control {
  display: flex;
  background-color: white;
}

.traversal-map .g-control .asset-type-selector-control:hover {
  background-color: white;
}

.traversal-map .g-control .asset-type-selector-control .gmap-dropdown {
  width: 20rem;
}

/* labels */
.traversal-map .g-map-label .label {
  background-color: rgba(255, 255, 255, 0.85);
  color: black;
  padding: 5px;
  white-space: nowrap;
}

/* alert */
.traversal-map .g-control .alert-control {
  padding: 0 0.25rem;
}
</style>