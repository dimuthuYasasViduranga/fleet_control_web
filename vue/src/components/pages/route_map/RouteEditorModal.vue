<template>
  <div class="route-editor-modal">
    <div ref="fullscreenable" class="container" :class="{ fullscreen: isFullscreen }">
      <div
        class="fullscreen-button"
        v-tooltip="{ content: isFullscreen ? 'Minimise' : 'Fullscreen', placement: 'left' }"
      >
        <Icon :icon="isFullscreen ? minimiseIcon : fullscreenIcon" @click="onToggleFullscreen()" />
      </div>
      <div class="stages">
        <button
          class="hx-btn"
          v-for="(stage, index) in stages"
          :key="index"
          :class="{ selected: stage === selectedStage }"
          @click="setStage(stage)"
        >
          {{ stage }}
        </button>
      </div>
      <div class="pane">
        <CreatorPane v-if="selectedStage === 'create'" />
        <RestrictionPane v-else-if="selectedStage === 'restrict'" />
        <ReviewPane v-else-if="selectedStage === 'review'" />
      </div>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';

import CreatorPane from './panes/CreatorPane.vue';
import RestrictionPane from './panes/RestrictionPane.vue';
import ReviewPane from './panes/ReviewPane.vue';

import FullscreenIcon from '@/components/icons/Fullscreen.vue';
import MinimiseIcon from '@/components/icons/Minimise.vue';

import { exitFullscreen, isElementFullscreen, requestFullscreen } from '@/code/fullscreen';

const STAGES = ['create', 'restrict', 'review'];

export default {
  name: 'RouteEditorModal',
  components: {
    Icon,
    CreatorPane,
    RestrictionPane,
    ReviewPane,
  },
  data: () => {
    return {
      isFullscreen: false,
      stages: STAGES,
      graph: null,
      selectedStage: STAGES[0],
      fullscreenIcon: FullscreenIcon,
      minimiseIcon: MinimiseIcon,
    };
  },
  mounted() {
    document.addEventListener('fullscreenchange', this.onFullscreenChange, false);
  },
  beforeDestroy() {
    document.removeEventListener('fullscreenchange', this.onFullscreenChange, false);
  },
  methods: {
    outerClickIntercept(payload) {
      // this can be used to prompt that you will lose some data
      console.log('---- click');
    },
    onFullscreenChange() {
      this.isFullscreen = isElementFullscreen();
    },
    setStage(stage) {
      this.selectedStage = stage;
    },
    onToggleFullscreen() {
      const area = this.$refs['fullscreenable'];

      if (!area) {
        console.error('[GeofenceEditorModal] No area found. Cannot enter fullscreen');
      }

      this.isFullscreen ? exitFullscreen(area) : requestFullscreen(area);
    },
  },
};
</script>

<style>
.route-editor-modal .modal-container-wrapper > .modal-container {
  height: auto;
}

.route-editor-modal .modal-container-wrapper {
  height: 100%;
  width: 100%;
  padding: 4rem 6rem;
  overflow-y: auto;
}

/* fullscreen container wrapper */

.route-editor-modal > .container {
  display: flex;
  flex-direction: column;
  height: 100%;
  width: 100%;
}

.route-editor-modal > .container.fullscreen {
  background-color: #23343f;
  padding: 2rem;
  overflow-y: auto;
}

/* stage/pane buttons */
.route-editor-modal .stages {
  display: flex;
}

.route-editor-modal .stages > button {
  width: 100%;
  margin: 0 0.1rem;
  text-transform: capitalize;
  opacity: 0.9;
}

.route-editor-modal .stages > button.selected {
  border-color: #b6c3cc;
  opacity: 1;
}

/* fullscreen button */
.route-editor-modal .fullscreen-button {
  cursor: pointer;
  height: 2rem;
  width: 2rem;
  float: right;
  align-self: flex-end;
  margin-right: -1.5rem;
  margin-top: -1.5rem;
  margin-bottom: 0.25rem;
}

.route-editor-modal .fullscreen-button:hover {
  opacity: 0.5;
}
</style>