<template>
  <div class="time-allocation-drop-down">
    <DropDown
      :value="value"
      :items="timeCodeOptions"
      label="name"
      :direction="direction"
      :useScrollLock="useScrollLock"
      @change="onChange"
    />
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { attributeFromList } from '@/code/helpers';
import DropDown from './dropdown/DropDown.vue';

export default {
  name: 'TimeAllocationDropDown',
  components: {
    DropDown,
  },
  props: {
    value: Number,
    allowedTimeCodeIds: { type: Array, default: () => [] },
    showAll: { type: Boolean, default: false },
    direction: { type: String, default: 'auto' },
    useScrollLock: { type: Boolean, default: false },
  },
  computed: {
    ...mapState('constants', {
      timeCodes: state => state.timeCodes,
      timeCodeGroups: state => state.timeCodeGroups,
    }),
    timeCodeOptions() {
      let timeCodes = this.timeCodes;

      if (!this.showAll) {
        timeCodes = timeCodes.filter(
          tc => this.allowedTimeCodeIds.includes(tc.id) || tc.id === this.value,
        );
      }

      const options = timeCodes.map(tc => {
        const groupName = attributeFromList(this.timeCodeGroups, 'id', tc.groupId, 'name') || '';
        return {
          id: tc.id,
          name: `${tc.code} - ${tc.name}`,
          class: groupName.toLowerCase(),
        };
      });

      options.sort((a, b) => a.name.localeCompare(b.name));
      return options;
    },
  },
  methods: {
    onChange(timeCodeId) {
      this.$emit('input', timeCodeId);
      this.$emit('change', timeCodeId);
    },
  },
};
</script>

<style>
.time-allocation-drop-down .dropdown-wrapper {
  height: 2rem;
}

.time-allocation-drop-down .dd-option,
.time-allocation-drop-down .dd-button-wrapper {
  border-left: 10px solid transparent;
}

.time-allocation-drop-down .dd-option.ready,
.time-allocation-drop-down .dd-button-wrapper.ready {
  border-left-color: green;
}

.time-allocation-drop-down .dd-option.process,
.time-allocation-drop-down .dd-button-wrapper.process {
  border-left-color: gold;
}

.time-allocation-drop-down .dd-option.standby,
.time-allocation-drop-down .dd-button-wrapper.standby {
  border-left-color: white;
}

.time-allocation-drop-down .dd-option.down,
.time-allocation-drop-down .dd-button-wrapper.down {
  border-left-color: gray;
}
</style>