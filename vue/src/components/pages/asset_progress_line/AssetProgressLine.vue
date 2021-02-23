<template>
  <div class="asset-progress-line-page">
    <hxCard title="Active Route" :icon="icon">
      <AssetProgressLineRow
        v-for="asset in activeAssets"
        :key="asset.id"
        :asset="asset"
        :icons="icons"
        :locations="locations"
        @click.native="onAssetClick(asset)"
      />
    </hxCard>

    <hxCard v-if="invalidPathAssets.length" title="Pathing issues" :icon="icon">
      <div class="wrapper">
        <div class="other-asset" v-bind:key="asset.id" v-for="asset in invalidPathAssets">
          <AssetIcon
            :asset="asset"
            :icons="icons"
            :locations="locations"
            @click.native="onAssetClick(asset)"
          />
        </div>
      </div>
    </hxCard>
    <hxCard v-if="unassignedAssets.length" title="Unassigned Assets" :icon="icon">
      <div class="wrapper">
        <div class="other-asset" v-bind:key="asset.id" v-for="asset in unassignedAssets">
          <AssetIcon
            :asset="asset"
            :icons="icons"
            :locations="locations"
            @click.native="onAssetClick(asset)"
          />
        </div>
      </div>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { firstBy } from 'thenby';
import hxCard from 'hx-layout/Card.vue';
import AssetProgressLineRow from './AssetProgressLineRow.vue';
import AssetIcon from './AssetIcon.vue';
import LineIcon from '../../icons/Line.vue';
import HaulTruckIcon from '../../icons/asset_icons/HaulTruck.vue';
import { attributeFromList } from '../../../code/helpers';
import { copyDate } from '../../../code/time';
function getLocationName(id, locations) {
  return attributeFromList(locations, 'id', id, 'name');
}
function formatDistance(distance) {
  let suffix = ' m';
  if (distance > 1000) {
    suffix = ' km';
    distance = distance / 1000;
  }
  return `${Math.round(distance)}${suffix}`;
}
function getDirection(track, info, clusters) {
  if (!track.velocity || !info.currentClusterId) {
    return null;
  }
  const heading = track.velocity.heading;
  const currentClusterId = info.currentClusterId;
  const loadClusterId = info.loadPath[0];
  const dumpClusterId = info.dumpPath[0];
  const angleToLoad = getClusterOffset(clusters, currentClusterId, loadClusterId);
  const angleToDump = getClusterOffset(clusters, currentClusterId, dumpClusterId);
  const opts = [
    { direction: 'load', heading: angleToLoad, diff: diffInHeading(heading, angleToLoad) },
    { direction: 'dump', heading: angleToDump, diff: diffInHeading(heading, angleToDump) },
  ];
  opts.sort((a, b) => a.diff - b.diff);
  return (opts.find(a => a.diff < 90) || {}).direction;
}
function getClusterOffset(clusters, id1, id2) {
  const cluster1 = attributeFromList(clusters, 'id', id1);
  const cluster2 = attributeFromList(clusters, 'id', id2);
  if (!cluster1 || !cluster2) {
    return 360;
  }
  return getHeading(cluster1, cluster2);
}
function getHeading(a, b) {
  const dy = b.north - a.north;
  const dx = b.east - a.east;
  const theta = Math.atan2(dy, dx);
  const xRefAngle = (theta * 180) / Math.PI; // [-180, 180]
  return 360 - ((xRefAngle + 270) % 360);
}
function diffInHeading(h1, h2) {
  const diff = Math.abs(h1 - h2);
  return diff > 180 ? 360 - diff : diff;
}
export default {
  name: 'AssetProgressLine',
  components: {
    hxCard,
    AssetIcon,
    AssetProgressLineRow,
  },
  data: () => {
    return {
      icon: LineIcon,
      haulTruckIcon: HaulTruckIcon,
      trucks: [],
    };
  },
  computed: {
    ...mapState('constants', {
      icons: state => state.icons,
      locations: state => state.locations,
      clusters: state => state.clusters,
    }),
    tracks() {
      return this.$store.state.trackStore.tracks;
    },
    assets() {
      const locations = this.locations;
      const clusters = this.clusters;
      const fullAssets = this.$store.getters.fullAssets.filter(
        fa => fa.type === 'Haul Truck' && fa.hasDevice === true,
      );
      const tracks = this.tracks;
      const assets = fullAssets.map(asset => {
        const track = tracks.find(t => t.assetId === asset.id) || {};
        const info = track.haulTruckInfo || {};
        const loadName = attributeFromList(this.locations, 'id', info.loadId, 'name');
        const dumpName = attributeFromList(this.locations, 'id', info.dumpId, 'name');
        const nextName = attributeFromList(this.locations, 'id', info.nextId, 'name');
        const direction = getDirection(track, info, clusters);
        const activeTimeAllocation = asset.activeTimeAllocation || {};
        const locationId = (track.location || {}).id;
        const [location, locationType] = attributeFromList(locations, 'id', locationId, [
          'name',
          'type',
        ]);
        return {
          id: asset.id,
          name: asset.name,
          type: asset.type,
          typeId: asset.typeId,
          activeTimeAllocation: {
            name: activeTimeAllocation.name,
            isReady: activeTimeAllocation.isReady,
          },
          present: asset.present,
          track: {
            location,
            locationType,
            timestamp: copyDate(track.timestamp),
          },
          currentLocation: (track.location || {}).name,
          // dispatch info
          loadId: info.loadId,
          loadName,
          dumpId: info.dumpId,
          dumpName,
          nextId: info.nextId,
          nextName,
          loadDistance: info.loadDistance,
          dumpDistance: info.dumpDistance,
          nextDistance: info.nextDistance,
          loadPath: info.loadPath,
          dumpPath: info.dumpPath,
          direction,
          timestamp: copyDate(track.timestamp),
        };
      });
      return assets;
    },
    activeAssets() {
      const assets = this.assets.filter(asset => {
        return asset.loadDistance != null && asset.dumpDistance != null;
      });
      assets.sort(firstBy('loadName').thenBy('dumpName').thenBy('name'));
      return assets;
    },
    invalidPathAssets() {
      return this.assets.filter(
        asset =>
          asset.loadName &&
          asset.dumpName &&
          (asset.loadDistance == null || asset.dumpDistance == null),
      );
    },
    unassignedAssets() {
      return this.assets.filter(asset => !asset.loadName && !asset.dumpName);
    },
  },
  methods: {
    onAssetClick(asset) {
      this.$eventBus.$emit('asset-assignment-open', asset.id);
    },
  },
};
</script>

<style>
.asset-progress-line-page .asset-icon {
  cursor: pointer;
}
.asset-progress-line-page .other-asset {
  position: relative;
  height: 4rem;
  width: 3rem;
}
.asset-progress-line-page .other-asset .hx-icon {
  width: 100%;
}
.asset-progress-line-page .other-asset .asset-name {
  width: 100%;
  text-align: center;
}
</style>