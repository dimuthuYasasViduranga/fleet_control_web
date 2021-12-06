<template>
  <div class="gmap-geofences">
    <gmap-polygon
      v-for="geofence in geofences"
      :key="`geofence-${geofence.type}-${geofence.historyId}`"
      :path="getPath(geofence)"
      :options="geofenceOptions(geofence)"
      @click="click($event, geofence, 'click')"
      @rightclick="click($event, geofence, 'rightclick')"
    />
  </div>
</template>

<script>
function getGeofenceColor(colors, options, geofence, unselected) {
  const unselectedFillOpacity = options.unselectedOpacity || options.fillOpacity;
  const unselectedStrokeOpacity = options.unselectedOpacity || options.strokeOpacity;

  const fillColor = colors[geofence.type] || colors.default;
  const fillOpacity = unselected ? unselectedFillOpacity : options.fillOpacity;

  const strokeColor = fillColor;
  const strokeOpacity = unselected ? unselectedStrokeOpacity : options.strokeOpacity;
  const strokeWeight = options.strokeWeight;

  return {
    fillColor,
    fillOpacity,
    strokeColor,
    strokeOpacity,
    strokeWeight,
  };
}

function defaultColors() {
  return {
    parkup: 'red',
    maintenance: 'darkgrey',
    fuel_bay: 'orange',
    load: 'green',
    'load|dump': 'darkorange',
    dump: 'blue',
    closed: 'black',
    changeover_bay: 'darkred',
    obstruction: 'black',
    default: 'black',
  };
}

function defaultOptions() {
  return {
    unselectedOpacity: 0.25,

    fillOpacity: 0.5,
    strokeOpacity: 1,
    strokeWeight: 3,
  };
}

function parseGeofence(geofenceString) {
  if (typeof geofenceString === 'string') {
    return geofenceString
      .split('|')
      .map(chunk => chunk.split(','))
      .map(([lat, lng]) => {
        return { lat: parseFloat(lat), lng: parseFloat(lng) };
      });
  }
  return geofenceString;
}

function within(arr, key, value) {
  const index = arr.findIndex(e => e[key] === value);
  return index !== -1;
}

export default {
  title: 'GMapGeofences',
  components: {},
  props: {
    highlightPits: { type: Array, default: () => [] },
    geofences: { type: Array, default: () => [] },
    options: { type: Object, default: () => defaultOptions() },
    colors: { type: Object, default: () => defaultColors() },
  },
  data: () => {
    return {
      lastSelectedGeofence: null,
    };
  },
  watch: {
    geofences(newGeofences, oldGeofences) {
      if (!this) {
        return;
      }
      const last = this.lastSelectedGeofence;
      if (last === null) {
        return;
      }
      const withinOld = within(oldGeofences, 'hist_id', last.hist_id);
      const withinNew = within(newGeofences, 'hist_id', last.hist_id);

      if ((withinOld && withinNew) || (!withinOld && !withinNew)) {
        return;
      }

      if (withinOld && !withinNew) {
        this.$emit('deleted', last);
      } else if (withinNew && !withinOld) {
        this.$emit('added', last);
      }
    },
  },
  methods: {
    geofenceOptions(geofence) {
      let unselect;
      if (this.highlightPits.length === 0) {
        unselect = false;
      } else if (this.highlightPits.includes(geofence.hist_id)) {
        unselect = false;
      } else {
        unselect = true;
      }

      const colors = getGeofenceColor(this.colors, this.options, geofence, unselect);
      return colors;
    },
    getPath(location) {
      return parseGeofence(location.geofence);
    },
    click(event, geofence, clickType) {
      this.lastSelectedGeofence = geofence;
      const data = {
        geofence,
        click: event,
      };
      this.$emit(clickType, data);
    },
  },
};
</script>

<style>
</style>
