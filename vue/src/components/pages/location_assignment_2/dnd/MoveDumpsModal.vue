<template>
  <div class="move-dumps-modal">
    <table>
      <tr>
        <td class="key">Dig Unit</td>
        <td class="value">
          <DropDown
            v-model="localDigUnitId"
            :items="digUnitOptions"
            label="name"
            :useScrollLock="false"
          />
          <Icon v-tooltip="'Clear'" :icon="crossIcon" @click="localDigUnitId = null" />
        </td>
      </tr>
      <tr>
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
  wrapperClass: 'move-dumps-modal-wrapper',
  components: {
    Icon,
    DropDown,
  },
  props: {
    submitName: { type: String, default: 'Add' },
    digUnitId: { type: [Number, String], default: null },
    dumpId: { type: [Number, String], default: null },
    digUnits: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    dumpLocations: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      crossIcon: ErrorIcon,
      localDigUnitId: null,
      localDumpId: null,
      showAllLocations: false,
    };
  },
  computed: {
    digUnitOptions() {
      return this.digUnits.map(d => {
        const location = attributeFromList(this.locations, 'id', d.locationId, 'name');
        const name = location ? `${d.name} (${location})` : d.name;
        return {
          id: d.id,
          name,
        };
      });
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
    this.localDumpId = this.dumpId;
  },
  methods: {
    onClose(resp) {
      this.$emit('close', resp);
    },
    onSubmit() {
      const payload = {
        digUnitId: this.localDigUnitId,
        dumpId: this.localDumpId,
      };

      this.onClose(payload);
    },
  },
};
</script>

<style>
.move-dumps-modal-wrapper .modal-container {
  max-width: 32rem;
}

.move-dumps-modal .separator {
  height: 1rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #677e8c;
}

/* ----- dropdowns ------ */
.move-dumps-modal table {
  width: 100%;
}

.move-dumps-modal tr {
  height: 3rem;
}

.move-dumps-modal tr .key {
  width: 11rem;
  font-size: 2rem;
}

.move-dumps-modal tr .value {
  display: flex;
  font-size: 1.5rem;
  text-align: center;
}

.move-dumps-modal tr .value .dropdown-wrapper {
  width: 100%;
  height: 2.5rem;
}

.move-dumps-modal tr .value .hx-icon {
  height: 2.5rem;
  width: 2.5rem;
  cursor: pointer;
  padding: 0.5rem;
}

/* ----- action buttons ----- */
.move-dumps-modal .action-buttons {
  display: flex;
  width: 100%;
}

.move-dumps-modal .action-buttons button {
  width: 100%;
  font-size: 1rem;
  margin: 0.1rem;
}

/* ---- confirm modal class ----- */
.move-dumps-confirm .modal-container {
  max-width: 40rem;
}
</style>