<template>
  <div class="excavator-info">
    <table>
      <tr>
        <th class="title" colspan="5">{{ title }}</th>
      </tr>
      <tr>
        <td class="heading">Operator</td>
        <td class="value">{{ asset.operatorFullname || '--' }}</td>
      </tr>
      <tr>
        <td class="heading">Location</td>
        <td class="value">{{ asset.track.location.name || '--' }}</td>
      </tr>
      <tr>
        <td class="heading">Speed (km/h)</td>
        <td class="value">{{ speed }}</td>
      </tr>
      <tr>
        <td class="heading">Heading</td>
        <td class="value">{{ heading }}&#176;</td>
      </tr>
      <tr>
        <td class="heading">Ignition</td>
        <td class="value" :class="ignitionClass">{{ ignition }}</td>
      </tr>
      <tr>
        <td class="heading">Time</td>
        <td class="value" :class="timestampClass">{{ timestamp }}</td>
      </tr>
    </table>
  </div>
</template>

<script>
import { todayRelativeFormat } from '../../../../code/time';
const MS_TO_KMH = 3.6;
const RECENCY = 10 * 60 * 1000; // 10 minutes
export default {
  name: 'ExcavatorInfo',
  props: {
    asset: { type: Object, required: true },
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
    ignition() {
      return this.asset.track.ignition ? 'On' : 'Off';
    },
    ignitionClass() {
      return this.asset.track.ignition ? 'green-text' : 'red-text';
    },
    timestamp() {
      const timestamp = this.asset.track.timestamp;
      return todayRelativeFormat(timestamp);
    },
    timestampClass() {
      const timestamp = this.asset.track.timestamp;
      const now = Date.now();

      if (now - timestamp.getTime() > RECENCY) {
        return 'red-text';
      }

      return '';
    },
  },
};
</script>

<style>
.excavator-info .title {
  border-bottom: solid 1px;
}

.excavator-info .heading {
  text-align: center;
}

.excavator-info .value {
  text-align: center;
}

.excavator-info td {
  padding: 0.2rem 0.75rem;
}
</style>