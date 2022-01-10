<template>
  <div class="route-map-page">
    <hxCard title="Route Map" :icon="lineIcon">
      <button class="hx-btn" @click="onOpenEditor()">Edit</button>
      <TraversalMap :locations="locations" :route="activeRoute" />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import LineIcon from '@/components/icons/Line.vue';
import TraversalMap from './TraversalMap.vue';
import RouteEditorModal from './RouteEditorModal.vue';

export default {
  name: 'RouteMapPage',
  components: {
    hxCard,
    TraversalMap,
  },
  data: () => {
    return {
      lineIcon: LineIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      assetTypes: state => state.assetTypes,
      locations: state => state.locations,
      activeRoute: state => state.activeRoute,
    }),
  },
  methods: {
    onOpenEditor() {
      this.$modal.create(RouteEditorModal);
    },
  },
};
</script>

<style>
</style>