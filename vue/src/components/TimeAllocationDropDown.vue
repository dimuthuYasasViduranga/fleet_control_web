<template>
  <div class="time-allocation-drop-down">
    <DropDown
      class="tc-drop-down"
      :class="group"
      :value="value"
      :options="timeCodeOptions"
      label="name"
      :placeholder="placeholder"
      :direction="direction"
      :disabled="disabled"
      :holdOpen="holdOpen"
      @change="onChange"
    >
      <template slot-scope="data">
        <div class="tc" :class="data.class">
          <div class="label">{{ data.name }}</div>
        </div>
      </template>
    </DropDown>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { attributeFromList } from '@/code/helpers';
import { DropDown } from 'hx-vue';

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
    placeholder: { type: String, default: 'Select' },
    disabled: { type: Boolean, deafult: false },
    holdOpen: { type: Boolean, default: false },
  },
  computed: {
    ...mapState('constants', {
      timeCodes: state => state.timeCodes,
      timeCodeGroups: state => state.timeCodeGroups,
    }),
    group() {
      const timeCodeGroupId = attributeFromList(this.timeCodes, 'id', this.value, 'groupId');
      const group = attributeFromList(this.timeCodeGroups, 'id', timeCodeGroupId, 'name') || '';
      return group.toLowerCase();
    },
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
.tc-drop-down.drop-down .dd-option {
  padding: 0;
}

.tc-drop-down,
.tc-drop-down .dd-option .tc {
  border-left: 10px solid #425866;
}

.tc-drop-down .dd-option .tc .label {
  padding: 0.2rem;
}

.tc-drop-down.ready,
.tc-drop-down .dd-option .tc.ready {
  border-left-color: green;
}

.tc-drop-down.process,
.tc-drop-down .dd-option .tc.process {
  border-left-color: gold;
}

.tc-drop-down.standby,
.tc-drop-down .dd-option .tc.standby {
  border-left-color: white;
}

.tc-drop-down.down,
.tc-drop-down .dd-option .tc.down {
  border-left-color: gray;
}
</style>