<template>
  <GridLayout class="dig-unit-home" width="100%" rows="*, 6*" columns="*">
    <!-- Load Unit Activity -->
    <ActivityBar row="0" :asset="asset" :activity="activity" />

    <GridLayout row="1" columns="2* 3* 4*">
      <!-- haul truck list (assigned to this activity.locationId) -->
      <ScrollView>
        <StackLayout class="haul-truck-list">
          <GridLayout
            height="100"
            columns="40 *"
            v-for="(haulDisp, index) in haulDispatches"
            :key="index"
            :class="{ selected: haulDisp.assetId === selectedHaulTruckId }"
            @tap="onHaulDispatchTap(haulDisp)"
          >
            <CenteredLabel col="0" height="100%" :text="`${index + 1}`" />
            <GridLayout col="1" rows="* *" class="haul-truck-item">
              <CenteredLabel row="0" class="name" :text="haulDisp.assetName" />
              <CenteredLabel row="1" class="distance" :text="formatDistance(haulDisp.distanceTo)" />
            </GridLayout>
          </GridLayout>
        </StackLayout>
      </ScrollView>

      <!-- Currently selected haul truck -->
      <AssetInfo
        v-if="selectedHaulTruckId"
        col="1"
        height="100%"
        :dispatch="selectedHaulDispatch"
        :locations="locations"
      />

      <!--  map -->
      <Map
        ref="map"
        :col="selectedHaulTruckId ? 2 : 1"
        colSpan="2"
        :showLegend="false"
        :showOptions="!selectedHaulTruckId"
        :showOthers="haulDispatches.map(hd => hd.assetName)"
        :trackStyler="customTrackStyler"
      />

      <StackLayout v-if="!online" col="0" colSpan="3" class="blocking-dim">
        <CenteredLabel class="offline-msg" text="Disabled while OFFLINE" />
      </StackLayout>
    </GridLayout>
  </GridLayout>
</template>

<script>
import { mapState } from 'vuex';
import { firstBy } from 'thenby';

import CenteredLabel from '../../../common/CenteredLabel.vue';
import Map from '../../../common/map/Map.vue';
import ActivityBar from './ActivityBar.vue';
import AssetInfo from './AssetInfo.vue';
import { attributeFromList, copyDate, toUtcDate } from '../../../code/helper';
import { haversineDistanceM } from '../../../code/distance';

const USER_SELECT_TIMEOUT = 100 * 1000;
const AUTO_SET_TIMEOUT = 10 * 1000;
const AUTO_UNSET_TIMEOUT = 5 * 1000;
const AUTO_SET_MAX_RECENCY = 5 * 60 * 1000;
const AUTO_SET_MIN_DISTANCE = 50;

function addHaulDispatchInfo(
  disp,
  assets,
  operators,
  deviceAssignments,
  loadUnitTrack,
  otherTracks,
) {
  const assignment = attributeFromList(deviceAssignments, 'assetId', disp.assetId) || {};
  const assetName = attributeFromList(assets, 'id', disp.assetId, 'name');
  const operatorName = attributeFromList(operators, 'id', assignment.operatorId, 'shortname');
  const track = attributeFromList(otherTracks, 'assetId', disp.assetId);

  const distanceTo = getDistanceTo(loadUnitTrack, track);
  const lastGPSAt = (track || {}).timestamp;

  return {
    assetId: disp.assetId,
    assetName,
    operatorId: assignment.operatorid || null,
    operatorName,
    distanceTo,
    lastGPSAt,
    loadId: disp.loadId,
    dumpId: disp.dumpId,
    nextId: disp.nextId,

    timestamp: copyDate(disp.timestamp),
  };
}

function getDistanceTo(loader, truck) {
  if (!loader || !truck) {
    return Infinity;
  }

  return haversineDistanceM(loader.position, truck.position);
}

export default {
  name: 'DigUnitHome',
  components: {
    Map,
    CenteredLabel,
    AssetInfo,
    ActivityBar,
  },
  props: {
    asset: { type: Object, default: null },
    operator: { type: Object, default: null },
    activity: { type: Object, default: {} },
  },
  data: () => {
    return {
      selectedHaulTruckId: null,
      allowAutoUpdateAfter: Date.now(),
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
      locations: state => state.locations,
    }),
    ...mapState('location', {
      loadUnitTrack: state => state.serverLocation,
      otherTracks: state => state.otherLocations,
    }),
    deviceAssignments() {
      return this.$store.state.deviceAssignments;
    },
    online() {
      return this.$store.state.connection.isConnected;
    },
    haulDispatches() {
      return this.$store.state.digUnit.haulDispatches
        .filter(hd => hd.digUnitId === this.asset.id)
        .map(hd =>
          addHaulDispatchInfo(
            hd,
            this.assets,
            this.operators,
            this.deviceAssignments,
            this.loadUnitTrack,
            this.otherTracks,
          ),
        )
        .sort(firstBy(a => a.distanceTo || Infinity).thenBy('assetName'));
    },
    selectedHaulDispatch() {
      return this.haulDispatches.find(hd => hd.assetId === this.selectedHaulTruckId);
    },
  },
  watch: {
    haulDispatches(dispatches) {
      // if the selected asset is removed, clear the selection id
      const now = Date.now();
      const selectedId = this.selectedHaulTruckId;

      const closeAsset = dispatches.find(d => {
        return (
          d.lastGPSAt &&
          now - d.lastGPSAt.getTime() < AUTO_SET_MAX_RECENCY &&
          d.distanceTo < AUTO_SET_MIN_DISTANCE
        );
      });

      // prevent really fast updates
      if (now > this.allowAutoUpdateAfter) {
        // if there is a close asset, and it is not the selected one
        if (closeAsset && closeAsset.assetId != selectedId) {
          console.log(`[DigUnit] Auto set to asset ${closeAsset.assetName}`);
          this.selectedHaulTruckId = closeAsset.assetId;
          this.setAutoUpdateAfter(AUTO_SET_TIMEOUT);
          return;
        }

        // if there is no close asset and there is one set
        if (!closeAsset && selectedId) {
          console.log('[DigUnit] Auto unset asset');
          this.selectedHaulTruckId = null;
          this.setAutoUpdateAfter(AUTO_UNSET_TIMEOUT);
          return;
        }
      }

      // if asset not longer assigned
      if (selectedId && !dispatches.find(d => d.assetId === selectedId)) {
        this.selectedHaulTruckId = null;
      }
    },
  },
  methods: {
    setAutoUpdateAfter(ms) {
      this.allowAutoUpdateAfter = Date.now() + ms;
    },
    onHaulDispatchTap(dispatch) {
      if (this.selectedHaulTruckId == dispatch.assetId) {
        console.log('[DigUnit] User unselected asset');
        this.selectedHaulTruckId = null;
      } else {
        console.log(`[DigUnit] User selected ${dispatch.assetName}`);
        this.selectedHaulTruckId = dispatch.assetId;
      }
      this.setAutoUpdateAfter(USER_SELECT_TIMEOUT);
      this.$refs.map.redraw(true);
    },
    customTrackStyler(type, track) {
      if (type === 'myLocation') {
        return null;
      }

      const color = track.assetId === this.selectedHaulTruckId ? 'blue' : 'green';
      const icon = track.velocity.speed < 0.2 ? 'Circle' : 'Heading';

      return { icon: `~/assets/markers/${icon}Icon.png`, color };
    },
    formatDistance(distance) {
      if (distance === Infinity) {
        return '';
      }

      if (distance > 1000) {
        const km = distance / 1000;
        return `(${km.toFixed(1)} km)`;
      }

      return `(${Math.trunc(distance)} m)`;
    },
  },
};
</script>

<style>
.dig-unit-home .blocking-dim {
  background-color: rgba(66, 66, 66, 0.767);
}

.dig-unit-home .blocking-dim .offline-msg {
  font-size: 30;
}

.dig-unit-home .haul-truck-list {
  border-color: gray;
  border-width: 0;
  border-right-width: 0.5;
}

/* styled to look like a button */
.dig-unit-home .haul-truck-item {
  background-color: #d6d7d7;
  border-radius: 3;
  margin: 1;
}

.dig-unit-home .selected .haul-truck-item {
  background-color: lightslategray;
}

.dig-unit-home .selected .haul-truck-item .centered-label {
  color: white;
}

.dig-unit-home .haul-truck-item .name {
  font-size: 28;
}

.dig-unit-home .haul-truck-item .distance {
  font-size: 20;
}

.dig-unit-home .haul-truck-item .centered-label {
  color: #0c1419;
}

.dig-unit-home .map .map-btn,
.dig-unit-home .map .dropdown-btn,
.dig-unit-home .map .dropdown-btn-ellipses {
  font-size: 16;
}

.dig-unit-home .map .map-toggle .toggle-btn {
  font-size: 14;
}
</style>