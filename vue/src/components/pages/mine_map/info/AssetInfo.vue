<template>
  <div class="asset-info">
    <table class="info-table">
      <tr>
        <th class="title" colspan="5">
          <div class="title-wrapper">
            <div class="name">{{ title }}</div>
            <Icon class="edit-modal-icon" :icon="editIcon" @click="onEdit" />
          </div>
        </th>
      </tr>
      <tr>
        <td class="heading">Operator</td>
        <td class="value">{{ asset.operatorName || '--' }}</td>
      </tr>
      <tr>
        <td class="heading">Location</td>
        <td class="value">{{ asset.track.location.name || '--' }}</td>
      </tr>
      <tr>
        <td class="heading">Speed (km/h)</td>
        <td class="value">{{ speed }}</td>
      </tr>
      <tr v-if="horizontalAccuracy != null">
        <td class="heading">GPS Accuracy</td>
        <td class="value">{{ horizontalAccuracy }}m</td>
      </tr>
      <tr>
        <td class="heading">Heading</td>
        <td class="value">{{ heading }}&#176; ({{ headingToCompass(heading) }})</td>
      </tr>
      <tr>
        <td class="heading">Ignition</td>
        <td class="value" :class="ignitionClass">{{ ignition }}</td>
      </tr>
      <tr>
        <td class="heading">Last GPS ({{ gpsSource }})</td>
        <td v-if="ago < agoSwitch" class="value" :class="agoClass">{{ formatAgo(ago) }}</td>
        <td v-else class="value red-text">{{ timestamp }}</td>
      </tr>
      <tr>
        <td class="heading">Radio</td>
        <td class="value">{{ asset.radioNumber || '--' }}</td>
      </tr>
      <tr>
        <td class="heading">
          <div v-if="allocName" class="alloc-color" :class="allocColorClass"></div>
          <span>Allocation</span>
        </td>
        <td class="value">
          <div>{{ allocName || '--' }}</div>
          <div v-if="allocDuration">{{ allocDuration }}</div>
        </td>
      </tr>
    </table>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import EditIcon from '@/components/icons/Edit.vue';
import { formatDateRelativeToIn, formatSeconds, formatSecondsRelative } from '@/code/time';

const MS_TO_KMH = 3.6;
const SECONDS_IN_DAY = 24 * 3600;
const AGO_SWITCH = 60 * 60 * 1000; // 1 hour
const AGO_MAX = 2 * 60 * 1000; // 2 minutes
const AGO_WARN = 30 * 1000; // 30 seconds

const COMPASS_COORDS = [
  [0, 22.5, 'N'],
  [22.5, 67.5, 'NE'],
  [67.5, 112.5, 'E'],
  [112.5, 157.5, 'SE'],
  [157.5, 202.5, 'S'],
  [202.5, 247.5, 'SW'],
  [247.5, 292.5, 'W'],
  [292.5, 337.5, 'NW'],
  [337.5, 360, 'N'],
];

function bearingToCompass(bearing) {
  return (COMPASS_COORDS.find(([min, max]) => bearing >= min && bearing <= max) || [])[2];
}

export default {
  name: 'HaulTruckInfo',
  components: {
    Icon,
  },
  props: {
    asset: { type: Object, required: true },
  },
  data: () => {
    return {
      editIcon: EditIcon,
      agoSwitch: AGO_SWITCH,
    };
  },
  computed: {
    title() {
      const name = this.asset.name;
      const type = this.asset.type;

      if (type) {
        return `${name} (${type})`;
      }

      return name;
    },
    speed() {
      return (this.asset.track.velocity.speed * MS_TO_KMH).toFixed(1);
    },
    heading() {
      return this.asset.track.velocity.heading.toFixed(0);
    },
    horizontalAccuracy() {
      const acc = (this.asset.track.accuracy || {}).horizontal;

      if (acc > 0) {
        return Math.round(acc);
      }
      return acc;
    },
    ignition() {
      switch (this.asset.track.ignition) {
        case true:
          return 'On';
        case false:
          return 'Off';
        default:
          return '--';
      }
    },
    ignitionClass() {
      return this.asset.track.ignition ? 'green-text' : 'red-text';
    },
    allocation() {
      return this.asset.allocation || {};
    },
    allocName() {
      return this.allocation.name;
    },
    allocDuration() {
      const startTime = this.allocation.startTime;
      if (!startTime) {
        return '';
      }

      const duration = Math.trunc((this.$everySecond.timestamp - startTime.getTime()) / 1000);
      const days = Math.trunc(duration / SECONDS_IN_DAY);
      if (days === 1) {
        return '(> 1 Day)';
      }
      if (days > 1) {
        return `(> ${days} Days)`;
      }
      return formatSeconds(duration, '(%HH:%MM:%SS)');
    },
    allocColorClass() {
      return (this.allocation.groupName || '').toLowerCase();
    },
    timestamp() {
      const timestamp = this.asset.track.timestamp;
      const tz = this.$timely.current.timezone;
      return formatDateRelativeToIn(timestamp, tz);
    },
    ago() {
      const ago = this.$everySecond.timestamp - this.asset.track.timestamp.getTime();
      return ago < 0 ? 0 : ago;
    },
    agoClass() {
      if (this.ago < AGO_WARN) {
        return 'green-text';
      }

      if (this.ago < AGO_MAX) {
        return 'orange-text';
      }

      return 'red-text';
    },
    gpsSource() {
      return this.asset?.track?.source;
    },
  },
  methods: {
    onEdit() {
      this.$eventBus.$emit('asset-assignment-open', this.asset.id);
    },
    formatAgo(ago) {
      return formatSecondsRelative(Math.trunc(ago / 1000));
    },
    headingToCompass(bearing) {
      return bearingToCompass(bearing);
    },
  },
};
</script>

<style>
@import '../../../../assets/styles/textColors.css';
</style>

<style scoped>
table {
  width: 100%;
}

.title {
  border-bottom: solid 1px;
}

.title-wrapper {
  width: 100%;
  display: flex;
}

.title-wrapper .name {
  width: 95%;
}

.title-wrapper .edit-modal-icon {
  cursor: pointer;
  height: 1rem;
  width: 1rem;
  stroke: black;
}

.heading {
  display: flex;
  justify-content: center;
}

.value {
  text-align: center;
}

td {
  padding: 0.2rem 0.75rem;
}

.allocation-table {
  margin-bottom: 0.2rem;
}

.alloc-color {
  width: 0.5rem;
  height: 0.75rem;
  margin-top: 0.1rem;
  margin-right: 0.3rem;
  border: 0.1px solid gray;
}

.alloc-color.ready {
  background-color: green;
}

.alloc-color.process {
  background-color: gold;
}

.alloc-color.standby {
  background-color: white;
}

.alloc-color.down {
  background-color: gray;
}
</style>