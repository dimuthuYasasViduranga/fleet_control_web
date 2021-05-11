<template>
  <hxCard :title="title" :icon="icon">
    <Map
      :assets="localAssets"
      :activeLocations="activeLocations"
      :locations="locations"
      @dragstart="onDragStart()"
      @dragend="onDragEnd()"
    />
  </hxCard>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import loading from 'hx-layout/Loading.vue';

import PlantIcon from '../../icons/Map.vue';
import Map from './Map.vue';

const STATIC_TYPES = ['parkup', 'maintenance', 'fuel_bay', 'changeover_bay'];
const CANNOT_ALERT_TYPES = ['Light Vehicle', 'Lighting Plant'];

function calculateAlert(asset, track) {
  if (CANNOT_ALERT_TYPES.includes(asset.type)) {
    return;
  }

  const locationType = ((track || {}).location || {}).type;
  const allocation = asset.activeTimeAllocation || {};

  if (!allocation.id) {
    return {
      text: 'Allocation not set',
      fill: 'purple',
    };
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
    loading,
    Map,
  },
  data: () => {
    return {
      title: 'Mine Map',
      icon: PlantIcon,
      dragging: false,
      localAssets: [],
    };
  },
  computed: {
    locations() {
      return this.$store.state.constants.locations;
    },
    haulTruckLocations() {
      // returns all the location ids currently being used
      const ids = this.$store.state.haulTruck.currentDispatches
        .map(d => {
          return [d.loadId, d.dumpId, d.nextId];
        })
        .flat();
      const uniqIds = Array.from(new Set(ids));
      return this.locations.filter(l => uniqIds.includes(l.id));
    },
    activeLocations() {
      const locations = this.locations;

      const staticLocations = this.locations.filter(l => STATIC_TYPES.includes(l.type));
      const haulLocations = this.haulTruckLocations;

      return staticLocations.concat(haulLocations);
    },
    tracks() {
      return this.$store.state.trackStore.tracks;
    },
    assets() {
      const tracks = this.tracks;
      return this.$store.getters.fullAssets
        .filter(fa => fa.hasDevice)
        .map(fa => {
          const track = tracks.find(t => t.assetId === fa.id);

          const allocation = fa.activeTimeAllocation || {};
          const alert = calculateAlert(fa, track);

          return {
            id: fa.id,
            name: fa.name,
            type: fa.type,
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
      handler(assets) {
        if (!this.dragging) {
          this.localAssets = (this.assets || []).slice();
        }
      },
    },
  },
  methods: {
    onDragStart() {
      this.dragging = true;
    },
    onDragEnd() {
      this.dragging = false;
    },
  },
};
</script>

<style>
@import '../../../assets/googleMaps.css';
.map_wrapper {
  padding-bottom: 2rem;
}

select {
  width: 8em;
  height: 1.55em;
  color: #0c1419;
  background-color: #ededed;
  border-style: none;
  text-align: center;
  margin: 0.1em;
}
</style>
