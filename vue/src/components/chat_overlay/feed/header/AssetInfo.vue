<template>
  <div class="asset-info">
    <div class="line line-1">
      <div class="status" :class="statusColor">{{ status }}</div>
      <div class="acknowledged" :class="acknowledgedColor">{{ acknowledged }}</div>
      <div class="radio-number">Radio: {{ device.radioNumber || '--' }}</div>
    </div>
    <div class="line line-2">
      <div class="time-allocation">
        <div class="time-code" :class="{ 'orange-text': false }">
          {{ activeAllocationName || 'Unknown Task' }}
        </div>
        <Icon class="edit-icon" :icon="editIcon" @click="onEdit" v-tooltip="{ content: 'Edit' }" />
      </div>
      <div class="run">
        {{ run }}
        <Icon class="edit-icon" :icon="editIcon" @click="onEdit" v-tooltip="{ content: 'Edit' }" />
      </div>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { attributeFromList, toFullName } from '../../../../code/helpers';
import EditIcon from '../../../icons/Edit.vue';

export default {
  name: 'AssetInfo',
  components: {
    Icon,
  },
  props: {
    device: { type: Object, default: null },
  },
  data: () => {
    return {
      editIcon: EditIcon,
    };
  },
  computed: {
    operatorName() {
      return this.device.operatorFullName || 'No Operator';
    },
    activeAllocation() {
      return this.device.activeTimeAllocation;
    },
    activeAllocationName() {
      return (this.activeTimeAllocation || {}).timeCode;
    },
    status() {
      if (this.device.present) {
        return 'Online';
      }
      return 'Offline';
    },
    statusColor() {
      switch (this.status) {
        case 'Online':
          return 'green-text';
        default:
          return 'grey-text';
      }
    },
    acknowledged() {
      if (this.device.acknowledged) {
        return 'Acknowledged';
      }
      return 'Unacknowledged';
    },
    acknowledgedColor() {
      if (this.device.acknowledged) {
        return 'green-text';
      }
      return 'orange-text';
    },
    loadLocation() {
      const locations = this.$store.state.loadLocations;
      return attributeFromList(locations, 'id', this.device.loadId, 'name');
    },
    dumpLocation() {
      const locations = this.$store.state.dumpLocations;
      return attributeFromList(locations, 'id', this.device.dumpId, 'name');
    },
    run() {
      const load = this.loadLocation;
      const dump = this.dumpLocation;

      return !load || !dump ? 'Unassigned' : `${load} \u27f9 ${dump}`;
    },
  },
  methods: {
    onEdit() {
      this.$eventBus.$emit('asset-assignment-open', this.device);
    },
  },
};
</script>

<style>
.asset-info {
  overflow: hidden;
  display: flex;
  flex-direction: column;
  text-align: center;
}

.asset-info .line {
  height: 1.6rem;
  padding: 0.25rem 0;
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  width: 100%;
}

.asset-info .time-allocation,
.asset-info .run {
  display: flex;
}

.asset-info .edit-icon {
  cursor: pointer;
  margin-left: 0.5rem;
  width: 0.8rem;
  height: 0.8rem;
}

.asset-info .red {
  color: red;
}

.asset-info .grey {
  color: grey;
}

.asset-info .green {
  color: green;
}
</style>