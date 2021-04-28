<template>
  <div class="add-route-modal">
    <div v-if="title" class="title">{{ title }}</div>
    <table>
      <tr>
        <td class="key">
          <DropDown v-model="source" :items="sourceOptions" label="id" :useScrollLock="false" />
        </td>
        <td class="value">
          <template v-if="source === 'Dig Unit'">
            <DropDown
              :value="localDigUnitId"
              :items="digUnits"
              label="fullname"
              selectedLabel="name"
              :useScrollLock="false"
              @change="onDigUnitChange"
            />
            <Icon v-tooltip="'Clear'" :icon="crossIcon" @click="localDigUnitId = null" />
          </template>
          <template v-else>
            <DropDown
              v-model="localLoadId"
              :items="availableLoads"
              label="name"
              :useScrollLock="false"
            />
            <Icon v-tooltip="'Clear'" :icon="crossIcon" @click="localLoadId = null" />
          </template>
        </td>
      </tr>
      <tr v-if="source === 'Dig Unit'">
        <td></td>
        <td class="value">
          <DropDown
            v-model="localDigUnitLocationId"
            :items="locations"
            label="name"
            :useScrollLock="false"
          />
          <Icon v-tooltip="'Clear'" :icon="crossIcon" @click="localDigUnitLocationId = null" />
        </td>
      </tr>
      <tr v-if="!hideDump">
        <td class="key">Dump</td>
        <td class="value">
          <DropDown
            v-model="localDumpId"
            :items="availableDumps"
            label="name"
            :useScrollLock="false"
          />
          <Icon v-tooltip="'Clear'" :icon="crossIcon" @click="localDumpId = null" />
        </td>
      </tr>
    </table>
    <div class="extended-list">
      <input type="checkbox" v-model="showAllLocations" />
      <span class="text">Show all locations</span>
    </div>
    <div class="separator"></div>
    <div class="action-buttons">
      <button class="hx-btn" @click="onSubmit()">{{ submitName }}</button>
      <button class="hx-btn" @click="onClose()">Cancel</button>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import DropDown from '@/components/dropdown/DropDown.vue';
import { attributeFromList, filterLocations } from '@/code/helpers';
import ErrorIcon from 'hx-layout/icons/Error.vue';

export default {
  name: 'AddRouteModal',
  wrapperClass: 'add-route-modal-wrapper',
  components: {
    Icon,
    DropDown,
  },
  props: {
    title: { type: String, default: '' },
    submitName: { type: String, default: 'Add' },
    digUnitId: { type: [Number, String], default: null },
    loadId: { type: [Number, String], default: null },
    dumpId: { type: [Number, String], default: null },
    digUnits: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    dumpLocations: { type: Array, default: () => [] },
    loadLocations: { type: Array, default: () => [] },
    hideDump: { type: Boolean, default: false },
  },
  data: () => {
    return {
      crossIcon: ErrorIcon,
      localDigUnitId: null,
      localDigUnitLocationId: null,
      localDumpId: null,
      localLoadId: null,
      showAllLocations: false,
      source: 'Dig Unit',
      sourceOptions: [{ id: 'Dig Unit' }, { id: 'Load', text: 'Location' }],
    };
  },
  computed: {
    availableLoads() {
      return filterLocations(
        this.loadLocations,
        this.locations,
        this.localLoadId,
        this.showAllLocations,
      );
    },
    availableDumps() {
      return filterLocations(
        this.dumpLocations,
        this.locations,
        this.localDumpId,
        this.showAllLocations,
      );
    },
  },
  mounted() {
    this.localDigUnitId = this.digUnitId;
    this.localDigUnitLocationId = attributeFromList(
      this.digUnits,
      'id',
      this.digUnitId,
      'locationId',
    );
    this.localLoadId = this.loadId;
    this.localDumpId = this.dumpId;

    if (!this.digUnitId && this.loadId) {
      this.source = 'Load';
    }
  },
  methods: {
    onClose(resp) {
      this.$emit('close', resp);
    },
    onSubmit() {
      if (this.source === 'Dig Unit') {
        const payload = {
          digUnitId: this.localDigUnitId,
          digUnitLocationId: this.localDigUnitLocationId,
          dumpId: this.localDumpId,
        };

        this.onClose(payload);
      } else {
        const payload = {
          loadId: this.localLoadId,
          dumpId: this.localDumpId,
        };

        this.onClose(payload);
      }
    },
    onDigUnitChange(digUnitId) {
      const locationId = attributeFromList(this.digUnits, 'id', digUnitId, 'locationId');
      this.localDigUnitId = digUnitId;
      this.localDigUnitLocationId = locationId;
    },
  },
};
</script>

<style>
.add-route-modal-wrapper .modal-container {
  max-width: 38rem;
}

.add-route-modal .separator {
  height: 1rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #677e8c;
}

.add-route-modal .title {
  width: 100%;
  font-size: 2rem;
  text-align: center;
  margin-bottom: 1rem;
  border-bottom: 1px solid #677e8c;
}

/* ----- dropdowns ------ */
.add-route-modal table {
  width: 100%;
}

.add-route-modal tr {
  height: 3rem;
}

.add-route-modal tr .key {
  width: 13rem;
  font-size: 2rem;
}

.add-route-modal tr .key .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
  font-size: 1.5rem;
}

.add-route-modal tr .value {
  display: flex;
  font-size: 1.5rem;
  text-align: center;
  padding: 4px;
}

.add-route-modal tr .value .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
}

.add-route-modal tr .value .hx-icon {
  height: 2.5rem;
  width: 2.5rem;
  cursor: pointer;
  padding: 0.5rem;
}

/* ----- action buttons ----- */
.add-route-modal .action-buttons {
  display: flex;
  width: 100%;
}

.add-route-modal .action-buttons button {
  width: 100%;
  font-size: 1rem;
  margin: 0.1rem;
}

/* ---- confirm modal class ----- */
.add-route-confirm .modal-container {
  max-width: 40rem;
}
</style>