<template>
  <div class="assign-dig-unit">
    <InfoHeader :asset="asset" :crossScale="crossScale" />
    <Separator />
    <AssignTimeAllocation
      v-model="timeCodeId"
      :assetTypeId="asset.typeId"
      :crossScale="crossScale"
    />
    <Separator />
    <table class="activity">
      <tr class="row location">
        <td class="key">Target Location</td>
        <td class="value">
          <DropDown
            v-tooltip="
              invalidLocation ? 'This load location is no longer active. Please re-assign' : ''
            "
            :class="{ 'inactive-location': !!invalidLocation }"
            v-model="localActivity.locationId"
            :options="locationOptions"
            placeholder="None"
            label="name"
          />
          <Icon
            v-tooltip="'Clear'"
            :icon="crossIcon"
            :scale="crossScale"
            @click="onClearLocation"
          />
        </td>
      </tr>
      <tr class="row material-type">
        <td class="key">Material</td>
        <td class="value">
          <div class="material-type-wrapper">
            <MaterialTypeDropDown v-model="localActivity.materialTypeId" direction="down" />
          </div>
          <Icon
            v-tooltip="'Clear'"
            :icon="crossIcon"
            :scale="crossScale"
            @click="onClearMaterial"
          />
        </td>
      </tr>
    </table>
    <Separator />
    <ActionButtons @submit="onSubmit" @reset="onReset" @cancel="onCancel" />
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { DropDown } from 'hx-vue';
import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import InfoHeader from './InfoHeader.vue';
import AssignTimeAllocation from './AssignTimeAllocation.vue';
import Separator from './Separator.vue';
import ActionButtons from './ActionButtons.vue';
import MaterialTypeDropDown from '@/components/MaterialTypeDropDown.vue';

function toLocalActivity(activity) {
  return {
    id: activity.id,
    locationId: activity.locationId,
    materialTypeId: activity.materialTypeId,
    loadStyleId: activity.loadStyleId,
  };
}

export default {
  name: 'AssignDigUnit',
  components: {
    Icon,
    Separator,
    InfoHeader,
    AssignTimeAllocation,
    ActionButtons,
    DropDown,
    MaterialTypeDropDown,
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    crossScale: { type: Number, default: 1 },
  },
  data: () => {
    return {
      localActivity: {},
      timeCodeId: null,
      crossIcon: ErrorIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      dimLocations: state => state.dimLocations,
      locations: state => state.locations,
      loadStyles: state => state.loadStyles,
      materialTypes: state => state.materialTypes,
    }),
    locationOptions() {
      const locations = this.locations.map(l => ({ id: l.id, name: l.name }));

      if (this.invalidLocation) {
        locations.push({
          id: this.invalidLocation.id,
          name: this.invalidLocation.name,
          invalid: true,
        });
      }

      return [{ id: null, name: 'None' }].concat(locations);
    },
    invalidLocation() {
      const locationId = this.localActivity?.locationId;

      if (!location || this.locations.find(l => l.id === locationId)) {
        return;
      }

      return this.dimLocations.find(l => l.id === locationId);
    },
    loadStyleOptions() {
      return [{ id: null, style: 'None' }].concat(this.loadStyles);
    },
    activities() {
      return this.$store.state.digUnit.currentActivities;
    },
  },
  watch: {
    asset: {
      immediate: true,
      handler(asset = {}) {
        this.setLocalActivity(asset);
        this.timeCodeId = asset.activeTimeCodeId;
      },
    },
  },
  methods: {
    emit(event) {
      this.$emit(event);
    },
    setLocalActivity(asset) {
      const activity = this.activities.find(a => a.assetId === asset.id);
      this.localActivity = toLocalActivity(activity || {});
    },
    onReset() {
      this.$emit('reset');
    },
    onCancel() {
      this.$emit('cancel');
    },
    onSubmit() {
      if (!this.asset.id) {
        console.error('[AssignDigUnit] Cannot submit with no asset id');
        return;
      }

      const activity = {
        asset_id: this.asset.id,
        location_id: this.localActivity.locationId || null,
        material_type_id: this.localActivity.materialTypeId || null,
        load_style_id: this.localActivity.loadStyleId || null,
        timestamp: Date.now(),
      };

      this.$channel.push('dig:set activity', activity);

      this.$emit('submit', this.timeCodeId);
    },
    onClearLocation() {
      this.localActivity.locationId = null;
    },
    onClearMaterial() {
      this.localActivity.materialTypeId = null;
    },
    onClearLoadStyle() {
      this.localActivity.loadStyleId = null;
    },
  },
};
</script>

<style>
.assign-dig-unit .activity .row .value {
  display: flex;
  font-size: 1.5rem;
  text-align: center;
}

.assign-dig-unit .activity .row .drop-down,
.material-type-wrapper {
  width: 100%;
  height: 2.5rem;
  max-width: calc(100% - 1rem);
  overflow: hidden;
}

.assign-dig-unit .row .v-select {
  width: 100%;
  height: 2.5rem;
}

.assign-dig-unit .hx-icon {
  height: 2.5rem;
  width: 2.5rem;
  cursor: pointer;
}

.assign-dig-unit .drop-down.inactive-location > div {
  border: 1px solid #ff6565;
}
</style>
