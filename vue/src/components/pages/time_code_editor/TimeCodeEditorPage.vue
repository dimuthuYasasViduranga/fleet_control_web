<template>
  <div class="time-code-editor-page">
    <hxCard style="width: auto" title="Time Code Editors" :icon="nestedListIcon">
      <div class="mode-selector">
        <button
          class="hx-btn"
          v-for="(mode, index) in [
            'time codes',
            'time code groups',
            'time code tree',
            'time code tree matrix',
          ]"
          :key="index"
          :class="{ selected: mode === selectedMode }"
          @click="setMode(mode)"
        >
          {{ mode }}
        </button>
      </div>
      <TimeCodeEditor
        v-if="selectedMode === 'time codes'"
        :readonly="readonly"
        :timeCodes="timeCodes"
        :timeCodeGroups="timeCodeGroups"
        :timeCodeCategories="timeCodeCategories"
      />
      <TimeCodeGroupEditor
        v-else-if="selectedMode === 'time code groups'"
        :readonly="readonly"
        :timeCodeGroups="timeCodeGroups"
      />
      <TimeCodeTreeEditor
        v-else-if="selectedMode === 'time code tree'"
        :readonly="readonly"
        :timeCodeGroups="timeCodeGroups"
        :assetTypes="assetTypes"
      />
      <TimeCodeTreeMatrix
        v-else
        :timeCodes="timeCodes"
        :timeCodeTreeElements="timeCodeTreeElements"
        :assetTypes="assetTypes"
      />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import NestedListIcon from '@/components/icons/NestedList.vue';

import TimeCodeTreeEditor from './time_code_tree/TimeCodeTreeEditor.vue';
import TimeCodeGroupEditor from './time_code_groups/TimeCodeGroupEditor.vue';
import TimeCodeEditor from './time_codes/TimeCodeEditor.vue';
import TimeCodeTreeMatrix from './time_code_tree/TimeCodeTreeMatrix.vue';

export default {
  name: 'TimeCodeEditorPage',
  components: {
    hxCard,
    TimeCodeEditor,
    TimeCodeGroupEditor,
    TimeCodeTreeEditor,
    TimeCodeTreeMatrix,
  },
  data: () => {
    return {
      nestedListIcon: NestedListIcon,
      selectedMode: 'time code tree',
    };
  },
  computed: {
    ...mapState('constants', {
      readonly: state => !state.permissions.can_edit_time_codes,
      timeCodes: state => state.timeCodes,
      timeCodeGroups: state => state.timeCodeGroups,
      timeCodeTreeElements: state => state.timeCodeTreeElements,
      timeCodeCategories: state => state.timeCodeCategories,
      assetTypes: state => state.assetTypes,
    }),
  },
  methods: {
    setMode(mode) {
      this.selectedMode = mode;
    },
  },
};
</script>

<style>
@import '../../../assets/styles/hxInput.css';

/* -------- mode selector ------- */
.time-code-editor-page .mode-selector {
  margin-bottom: 1rem;
}

.time-code-editor-page .mode-selector .hx-btn {
  width: 12rem;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
  text-transform: capitalize;
}

.time-code-editor-page .mode-selector .hx-btn.selected {
  background-color: #2c404c;
  border: 1px solid #898f94;
}
</style>