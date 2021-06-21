<template>
  <div class="assign-haul-truck">
    <InfoHeader :asset="asset" :crossScale="crossScale" />
    <Separator />
    <AssignTimeAllocation
      v-model="timeCodeId"
      :assetTypeId="asset.typeId"
      :crossScale="crossScale"
    />
    <Separator />
    <table class="dispatch">
      <tr class="row dig-unit">
        <td class="key">
          <DropDown v-model="source" :items="sourceOptions" label="id" :useScrollLock="false" />
        </td>
        <td class="value">
          <template v-if="source === 'Dig Unit'">
            <DropDown
              v-model="localDispatch.digUnitId"
              :items="digUnitOptions"
              label="name"
              :useScrollLock="false"
            />
            <Icon
              v-tooltip="'Clear'"
              :icon="crossIcon"
              :scale="crossScale"
              @click="onClearDigUnit"
            />
          </template>
          <template v-else>
            <DropDown
              v-model="localDispatch.loadId"
              :items="loads"
              label="name"
              :useScrollLock="false"
            />
            <Icon v-tooltip="'Clear'" :icon="crossIcon" :scale="crossScale" @click="onClearLoad" />
          </template>
        </td>
      </tr>
      <tr class="row dump">
        <td class="key">Dump</td>
        <td class="value">
          <DropDown
            v-model="localDispatch.dumpId"
            :items="dumps"
            label="name"
            :useScrollLock="false"
          />
          <Icon v-tooltip="'Clear'" :icon="crossIcon" :scale="crossScale" @click="onClearDump" />
        </td>
      </tr>
    </table>

    <div class="extended-list">
      <input id="checkbox" type="checkbox" v-model="showAllLocations" />
      Show all locations
    </div>
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
import ActionButtons from './ActionButtons.vue';
import Separator from './Separator.vue';
import DropDown from '../dropdown/DropDown.vue';
import { attributeFromList, filterLocations } from '@/code/helpers';

function getEmptyLocation() {
  return {
    id: null,
    name: 'None',
  };
}

function toLocalDispatch(dispatch) {
  return {
    digUnitId: dispatch.digUnitId,
    loadId: dispatch.loadId,
    dumpId: dispatch.dumpId,
    nextId: dispatch.nextId,
  };
}

export default {
  name: 'AssignHaulTruck',
  components: {
    Icon,
    Separator,
    InfoHeader,
    AssignTimeAllocation,
    DropDown,
    ActionButtons,
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    crossScale: { type: Number, default: 1 },
  },
  data: () => {
    return {
      timeCodeId: null,
      localDispatch: {},
      showAllLocations: false,
      crossIcon: ErrorIcon,
      source: 'Dig Unit',
      sourceOptions: [{ id: 'Dig Unit' }, { id: 'Location' }],
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      loadLocations: state => state.loadLocations,
      dumpLocations: state => state.dumpLocations,
      allLocations: state => state.locations,
    }),
    ...mapState({
      haulTruckDispatches: state => state.haulTruck.currentDispatches,
      digUnitActivities: state => state.digUnit.currentActivities,
    }),
    loads() {
      const loads = filterLocations(
        this.loadLocations,
        this.allLocations,
        this.localDispatch.loadId,
        this.showAllLocations,
      );
      return [getEmptyLocation()].concat(loads);
    },
    dumps() {
      const dumps = filterLocations(
        this.dumpLocations,
        this.allLocations,
        this.localDispatch.dumpId,
        this.showAllLocations,
      );
      return [getEmptyLocation()].concat(dumps);
    },
    digUnitOptions() {
      const activities = this.digUnitActivities;
      const options = this.assets
        .filter(a => a.secondaryType === 'Dig Unit')
        .map(d => {
          const activity = attributeFromList(activities, 'assetId', d.id) || {};

          const locName = attributeFromList(this.allLocations, 'id', activity.locationId, 'name');

          const name = locName ? `${d.name} (${locName})` : d.name;

          return {
            id: d.id,
            name,
          };
        });

      return [{ name: 'None' }].concat(options);
    },
  },
  watch: {
    asset: {
      immediate: true,
      handler(asset = {}) {
        this.setLocalDispatch(asset);
        this.timeCodeId = asset.activeTimeCodeId;
      },
    },
  },
  methods: {
    setLocalDispatch(asset) {
      const dispatch = this.haulTruckDispatches.find(d => d.assetId === asset.id);
      this.localDispatch = toLocalDispatch(dispatch || {});

      if (!this.localDispatch.digUnitId && this.localDispatch.loadId) {
        this.source = 'Location';
      } else {
        this.source = 'Dig Unit';
      }
    },
    onReset() {
      this.$emit('reset');
    },
    onCancel() {
      this.$emit('cancel');
    },
    onSubmit() {
      if (!this.asset.id) {
        console.error('[AssignHaulTruck] Cannot submit with no asset id');
        return;
      }

      const digUnitId = this.source === 'Dig Unit' ? this.localDispatch.digUnitId : null;
      const loadId = this.source === 'Location' ? this.localDispatch.loadId : null;

      const dispatch = {
        asset_id: this.asset.id,
        dig_unit_id: digUnitId,
        load_location_id: loadId,
        dump_location_id: this.localDispatch.dumpId,
        timestamp: Date.now(),
      };

      this.$channel.push('haul:set dispatch', dispatch);

      this.$emit('submit', this.timeCodeId);
    },
    onClearDigUnit() {
      this.localDispatch.digUnitId = null;
    },
    onClearLoad() {
      this.localDispatch.loadId = null;
    },
    onClearDump() {
      this.localDispatch.dumpId = null;
    },
    onClearNext() {
      this.localDispatch.nextId = null;
    },
  },
};
</script>

<style>
.assign-haul-truck .dispatch .row .key .dropdown-wrapper {
  width: 95%;
  height: 2.5rem;
  font-size: 1.75rem;
}

.assign-haul-truck .dispatch .row .value {
  display: flex;
  font-size: 1.5rem;
  text-align: center;
  padding: 4px;
}

.assign-haul-truck .dispatch .row .value .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
}

.assign-haul-truck .hx-icon {
  height: 2.5rem;
  width: 2.5rem;
  cursor: pointer;
}

.assign-haul-truck .hx-icon:hover {
  stroke: red;
}

.assign-haul-truck .extended-list {
  padding-bottom: 1rem;
}

.assign-haul-truck #checkbox {
  cursor: pointer;
}
</style>