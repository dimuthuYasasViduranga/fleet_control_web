<template>
  <hxCard class="location-assignment-2" :hideTitle="true">
    <loaded>
      <div class="settings">
        <Icon
          v-tooltip="{ content: 'Layout Settings', placement: 'left' }"
          :icon="cogIcon"
          @click="onOpenSettings()"
        />
      </div>
      <DndRouteMain
        :orientation="dndSettings.orientation"
        :layoutSettings="dndSettings"
        :fullAssets="fullAssets"
        :locations="locations"
        :loadLocations="loadLocations"
        :dumpLocations="dumpLocations"
        :digUnitActivities="digUnitActivities"
        :haulTruckDispatches="haulTruckDispatches"
        @set-haul-truck="onUpdateHaulTruck"
        @mass-set-haul-trucks="onMassUpdateHaulTrucks"
      />
    </loaded>
  </hxCard>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import Loaded from '@/components/Loaded.vue';

import DndRouteMain from './dnd/DndRouteMain.vue';
import CogIcon from '@/components/icons/Cog.vue';
import DndSettingsModal from './dnd/DndSettingsModal.vue';

export default {
  name: 'LocationAssignment',
  components: {
    hxCard,
    Icon,
    Loaded,
    DndRouteMain,
  },
  data: () => {
    return {
      cogIcon: CogIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      locations: state => state.locations,
      loadLocations: state => state.loadLocations,
      dumpLocations: state => state.dumpLocations,
    }),
    ...mapState({
      haulTruckDispatches: state => state.haulTruck.currentDispatches,
      digUnitActivities: state => state.digUnit.currentActivities,
    }),
    fullAssets() {
      return this.$store.getters.fullAssets;
    },
    dndSettings() {
      return this.$store.state.dndSettings;
    },
  },
  methods: {
    onOpenSettings() {
      this.$modal.create(DndSettingsModal, { settings: this.dndSettings }).onClose(resp => {
        if (resp) {
          this.$store.commit('setDndSettings', resp);
        }
      });
    },
    onUpdateHaulTruck({ assetId, digUnitId, loadId, dumpId }) {
      const payload = {
        asset_id: assetId,
        dig_unit_id: digUnitId,
        load_location_id: loadId,
        dump_location_id: dumpId,
        timestamp: Date.now(),
      };

      this.$channel
        .push('haul:set dispatch', payload)
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to update dispatch'));
    },
    onMassUpdateHaulTrucks({ assetIds, digUnitId, loadId, dumpId }) {
      const payload = {
        asset_ids: assetIds,
        dispatch: {
          dig_unit_id: digUnitId,
          load_location_id: loadId,
          dump_location_id: dumpId,
        },
      };

      this.$channel
        .push('haul:set mass dispatch', payload)
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to update mass dispatch'));
    },
  },
};
</script>

<style scoped>
.settings {
  height: 0rem;
}

.settings .hx-icon {
  cursor: pointer;
  position: absolute;
  top: 1rem;
  right: 1rem;
}

.settings .hx-icon:hover {
  opacity: 0.5;
}
</style>

