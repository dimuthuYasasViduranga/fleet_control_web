<template>
  <hxCard class="location-assignment" :hideTitle="true">
    <loaded>
      <div class="settings">
        <Icon
          v-tooltip="{ content: 'Settings', placement: 'left' }"
          :icon="cogIcon"
          @click="onOpenSettings()"
        />
      </div>
      <DndRoutes
        :orientation="settings.orientation"
        :settings="settings"
        :digUnits="digUnits"
        :haulTrucks="haulTrucks"
        :otherAssets="otherAssets"
        :locations="locations"
        :dumpLocations="dumpLocations"
        @set-haul-truck="onSetHaulTruck"
        @mass-set-haul-truck="onMassSetHaulTruck"
      />
    </loaded>
  </hxCard>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import Loaded from '@/components/Loaded.vue';
import DndRoutes from './DndRoutes.vue';
import DndSettingsModal from './DndSettingsModal.vue';

import { attributeFromList } from '@/code/helpers';

import CogIcon from '@/components/icons/Cog.vue';

export default {
  name: 'LocationAssignment',
  components: {
    hxCard,
    Icon,
    Loaded,
    DndRoutes,
  },
  data: () => {
    return {
      cogIcon: CogIcon,
      routeStructure: {},
      dropPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
    };
  },
  computed: {
    ...mapState('constants', {
      locations: state => state.locations,
      dumpLocations: state => state.dumpLocations,
    }),
    settings() {
      return this.$store.state.dndSettings;
    },
    fullAssets() {
      return this.$store.getters.fullAssets.filter(
        fa => fa.hasDevice || fa.secondaryType === 'Dig Unit',
      );
    },
    digUnits() {
      const activities = this.$store.state.digUnit.currentActivities;

      return this.fullAssets
        .filter(a => a.secondaryType === 'Dig Unit')
        .map(a => {
          const activity = attributeFromList(activities, 'assetId', a.id) || {};
          return { ...a, activity: { ...activity } };
        });
    },
    haulTrucks() {
      const dispatches = this.$store.state.haulTruck.currentDispatches;

      return this.fullAssets
        .filter(a => a.type === 'Haul Truck')
        .map(a => {
          const dispatch = attributeFromList(dispatches, 'assetId', a.id) || {};
          return { ...a, dispatch: { ...dispatch } };
        });
    },
    otherAssets() {
      const usedAssetIds = []
        .concat(this.digUnits)
        .concat(this.haulTrucks)
        .map(a => a.id);
      return this.fullAssets.filter(a => !usedAssetIds.includes(a.id));
    },
  },
  methods: {
    onOpenSettings() {
      this.$modal.create(DndSettingsModal, { settings: this.settings }).onClose(resp => {
        if (resp) {
          this.$store.commit('setDndSettings', resp);
        }
      });
    },
    onSetHaulTruck({ assetId, digUnitId, dumpId }) {
      const payload = {
        asset_id: assetId,
        dig_unit_id: digUnitId,
        dump_location_id: dumpId,
        timestamp: Date.now(),
      };

      this.$channel
        .push('haul:set dispatch', payload)
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to update dispatch'));
    },
    onMassSetHaulTruck({ assetIds, digUnitId, dumpId }) {
      const payload = {
        asset_ids: assetIds,
        dispatch: {
          dig_unit_id: digUnitId,
          dump_location_id: dumpId,
        },
      };

      this.$channel
        .push('haul:set mass dispatch', payload)
        .receive('error', resp => this.$toasted.global.error(resp.resp.error))
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


