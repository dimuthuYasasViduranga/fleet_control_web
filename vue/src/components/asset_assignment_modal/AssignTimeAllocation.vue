<template>
  <table class="assign-time-allocation">
    <tr class="row allocation">
      <td class="key">Allocation</td>
      <td class="value">
        <TimeAllocationDropDown
          v-model="asset.activeTimeCodeId"
          :allowedTimeCodeIds="allowedTimeCodeIds"
          :useScrollLock="false"
        />
        <Icon
          v-if="noTaskTimeCodeId"
          v-tooltip="'Clear'"
          :icon="crossIcon"
          :scale="crossScale"
          @click="onClearAllocation"
        />
      </td>
    </tr>
  </table>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import TimeAllocationDropDown from '../TimeAllocationDropDown.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import { firstBy } from 'thenby';

export default {
  name: 'AssignTimeAllocation',
  components: {
    TimeAllocationDropDown,
    Icon,
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    crossScale: { type: Number, default: 1 },
  },
  data: () => {
    return {
      crossIcon: ErrorIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      timeCodes: state => state.timeCodes,
    }),
    allowedTimeCodeIds() {
      const assetTypeId = this.asset.typeId;
      return this.$store.getters['constants/fullTimeCodes']
        .filter(tc => tc.assetTypeIds.includes(assetTypeId))
        .map(tc => tc.id);
    },
    noTaskTimeCodeId() {
      return (this.timeCodes.find(tc => tc.name === 'No Task') || {}).id;
    },
  },
  methods: {
    onClearAllocation() {
      this.asset.activeTimeCodeId = this.noTaskTimeCodeId;
    },
  },
};
</script>

<style>
.assign-time-allocation {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
}

.assign-time-allocation .row {
  height: 3rem;
}

.assign-time-allocation .row .key {
  width: 11rem;
  font-size: 2rem;
}

.assign-time-allocation .row .value {
  display: flex;
  font-size: 1.5rem;
  text-align: center;
}

.assign-time-allocation .hx-icon {
  height: 2.5rem;
  width: 2.5rem;
  cursor: pointer;
}

.assign-time-allocation .hx-icon:hover {
  stroke: red;
}

.assign-time-allocation .row .time-allocation-drop-down {
  width: calc(100% - 2rem);
}

.assign-time-allocation .row .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
}
</style>