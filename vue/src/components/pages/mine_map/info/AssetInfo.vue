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
      <tr>
        <td class="heading">
          <div v-if="allocName" class="alloc-color" :class="allocColorClass"></div>
          <span>Allocation</span>
        </td>
        <td class="value">{{ allocName || '--' }}</td>
      </tr>
    </table>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import EditIcon from '@/components/icons/Edit.vue';
import { attributeFromList } from '@/code/helpers';
import { formatDateRelativeToIn } from '../../../../code/time';

const MS_TO_KMH = 3.6;
const RECENCY = 10 * 60 * 1000; // 10 minutes

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
    allocColorClass() {
      return (this.allocation.groupName || '').toLowerCase();
    },
    timestamp() {
      const timestamp = this.asset.track.timestamp;
      const tz = this.$timely.current.timezone;
      return formatDateRelativeToIn(timestamp, tz);
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
  methods: {
    onEdit() {
      this.$eventBus.$emit('asset-assignment-open', this.asset.id);
    },
  },
};
</script>

<style>
@import '../../../../assets/textColors.css';
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