<template>
  <hxCard ref="page" class="asset-overview-page" :hideTitle="true">
    <Icon class="fullscreen-toggle" :icon="fullscreenIcon" @click="toggleFullscreen()" />
    <div class="controls">Controls go here</div>
    <div class="asset-tiles">
      <div>Apple</div>
      <div>Banans</div>
    </div>
  </hxCard>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';

import { isElementFullscreen, requestFullscreen, exitFullscreen } from '@/code/fullscreen';

import FullscreenIcon from '@/components/icons/Fullscreen.vue';

export default {
  name: 'AssetOverviewPage',
  components: {
    hxCard,
    Icon,
  },
  data: () => {
    return {
      fullscreenIcon: FullscreenIcon,
      isFullscreen: false,
    };
  },
  mounted() {
    document.addEventListener('fullscreenchange', this.onFullscreenChange, false);
  },
  beforeDestroy() {
    document.removeEventListener('fullscreenchange', this.onFullscreenChange);
  },
  methods: {
    toggleFullscreen() {
      const page = this.$refs.page;

      if (!page) {
        console.error('[AssetOverview] Unable to enter fullscreen');
        return;
      }

      const pageEl = page.$el;
      this.isFullscreen ? exitFullscreen(pageEl) : requestFullscreen(pageEl);
    },
    onFullscreenChange() {
      this.isFullscreen = isElementFullscreen();
    },
  },
};
</script>

<style>
.asset-overview-page .fullscreen-toggle {
  cursor: pointer;
  position: absolute;
  right: 0;
  margin-top: 1rem;
  margin-right: 1rem;
}

.asset-overview-page .fullscreen-toggle:hover {
  opacity: 0.5;
}
</style>