<template>
  <table class="assign-time-allocation">
    <tr class="row allocation">
      <td class="key">Allocation</td>
      <td class="value">
        <TimeAllocationDropDown
          :value="value"
          :allowedTimeCodeIds="allowedTimeCodeIds"
          :useScrollLock="false"
          @input="update"
        />
        <Icon
          v-if="noTaskTimeCodeId"
          v-tooltip="'Clear'"
          :icon="crossIcon"
          :scale="crossScale"
          @click="update(noTaskTimeCodeId)"
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

export default {
  name: 'AssignTimeAllocation',
  components: {
    TimeAllocationDropDown,
    Icon,
  },
  props: {
    value: { type: Number },
    assetTypeId: { type: Number },
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
      const assetTypeId = this.assetTypeId;
      return this.$store.getters['constants/fullTimeCodes']
        .filter(tc => tc.assetTypeIds.includes(assetTypeId))
        .map(tc => tc.id);
    },
    noTaskTimeCodeId() {
      return (this.timeCodes.find(tc => tc.name === 'No Task') || {}).id;
    },
  },
  methods: {
    update(value) {
      this.$emit('input', value);
    },
  },
};
</script>

<style>
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
  width: 100%;
}

.assign-time-allocation .row .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
}
</style>