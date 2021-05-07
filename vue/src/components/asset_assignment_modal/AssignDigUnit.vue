<template>
  <div class="assign-dig-unit">
    <InfoHeader :asset="asset" :crossScale="crossScale" />
    <Separator />
    <AssignTimeAllocation :asset="asset" :crossScale="crossScale" />
    <Separator />
    <table class="activity">
      <tr class="row location">
        <td class="key">Location</td>
        <td class="value">
          <DropDown
            v-model="localActivity.locationId"
            :items="locationOptions"
            label="name"
            :useScrollLock="false"
          />
          <Icon
            v-tooltip="'Clear'"
            :icon="crossIcon"
            :scale="crossScale"
            @click="onClearLocation"
          />
        </td>
      </tr>
      <!-- <tr class="row material-type">
        <td class="key">Material</td>
        <td class="value">
          <DropDown
            v-model="localActivity.materialTypeId"
            :items="materialTypeOptions"
            label="commonName"
            :useScrollLock="false"
          />
          <Icon
            v-tooltip="'Clear'"
            :icon="crossIcon"
            :scale="crossScale"
            @click="onClearMaterial"
          />
        </td>
      </tr> -->
      <!-- <tr class="row load-style">
        <td class="key">Load Style</td>
        <td class="value">
          <DropDown
            v-model="localActivity.loadStyleId"
            :items="loadStyleOptions"
            label="style"
            :useScrollLock="false"
          />
          <Icon
            v-tooltip="'Clear'"
            :icon="crossIcon"
            :scale="crossScale"
            @click="onClearLoadStyle"
          />
        </td>
      </tr> -->
    </table>
    <Separator />
    <ActionButtons @submit="onSubmit" @reset="onReset" @cancel="onCancel" />
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import InfoHeader from './InfoHeader.vue';
import AssignTimeAllocation from './AssignTimeAllocation.vue';
import Separator from './Separator.vue';
import ActionButtons from './ActionButtons.vue';
import DropDown from '../dropdown/DropDown.vue';

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
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    crossScale: { type: Number, default: 1 },
  },
  data: () => {
    return {
      localActivity: {},
      crossIcon: ErrorIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      locations: state => state.locations,
      loadStyles: state => state.loadStyles,
      materialTypes: state => state.materialTypes,
    }),
    locationOptions() {
      return [{ id: null, name: 'None' }].concat(this.locations);
    },
    materialTypeOptions() {
      return [{ id: null, commonName: 'None' }].concat(this.materialTypes);
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

      this.$emit('submit');
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
.assign-dig-unit .activity {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
}

.assign-dig-unit .activity .row {
  height: 3rem;
}

.assign-dig-unit .activity .row .key {
  width: 11rem;
  font-size: 2rem;
}

.assign-dig-unit .activity .row .value {
  display: flex;
  font-size: 1.5rem;
  text-align: center;
}

.assign-dig-unit .activity .row .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
}
</style>