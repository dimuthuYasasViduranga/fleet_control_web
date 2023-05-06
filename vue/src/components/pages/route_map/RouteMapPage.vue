<template>
  <div class="route-map-page">
    <hxCard title="Route Map" :icon="lineIcon">
      <button v-if="permissions.fleet_control_edit_routing" class="hx-btn" @click="onOpenEditor()">
        Edit
      </button>
      <TraversalMap :assetTypes="assetTypes" :locations="locations" :route="activeRoute" />
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
      permissions: state => state.permissions,
      assetTypes: state => state.assetTypes.slice().sort((a, b) => a.type.localeCompare(b.type)),
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