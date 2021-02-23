<template>
  <modal class="cycle-edit-modal" :show="show" @close="onClose()">
    <table class="cycle-edit-table">
      <tr class="row asset">
        <td class="key">Asset</td>
        <td class="value">
          <DropDown
            :class="{ error: validationErrors.includes('assetId') }"
            v-model="localCycle.assetId"
            :items="haulTrucks"
            label="name"
            :useScrollLock="false"
          />
        </td>
      </tr>
      <tr class="row operator">
        <td class="key">Operator</td>
        <td class="value">
          <DropDown
            :class="{ error: validationErrors.includes('operatorId') }"
            v-model="localCycle.operatorId"
            :items="operators"
            label="name"
            :useScrollLock="false"
          />
        </td>
      </tr>
      <tr class="row start-time">
        <td class="key">Start</td>
        <td class="value">
          <Dately
            :class="{ error: validationErrors.includes('startTime') }"
            v-model="localCycle.startTime"
            :minDatetime="minDatetime"
            :maxDatetime="maxDatetime"
            :timezone="timezone"
          />
        </td>
      </tr>
      <tr class="row end-time">
        <td class="key">End</td>
        <td class="value">
          <Dately
            :class="{ error: validationErrors.includes('endTime') }"
            v-model="localCycle.endTime"
            :minDatetime="minDatetime"
            :maxDatetime="maxDatetime"
            :timezone="timezone"
          />
        </td>
      </tr>
      <tr class="row load-unit">
        <td class="key">Load Unit</td>
        <td class="value">
          <DropDown
            :class="{ error: validationErrors.includes('loadUnitId') }"
            v-model="localCycle.loadUnitId"
            :items="loadUnits"
            label="name"
            :useScrollLock="false"
          />
        </td>
      </tr>
      <tr class="row material-type">
        <td class="key">Material</td>
        <td class="value">
          <DropDown
            :class="{ error: validationErrors.includes('materialTypeId') }"
            v-model="localCycle.materialTypeId"
            :items="materialTypes"
            label="commonName"
            :useScrollLock="false"
          />
        </td>
      </tr>
      <tr class="row load-location">
        <td class="key">Load</td>
        <td class="value">
          <DropDown
            :class="{ error: validationErrors.includes('loadLocationId') }"
            v-model="localCycle.loadLocationId"
            :items="locations"
            label="name"
            :useScrollLock="false"
          />
        </td>
      </tr>
      <tr class="row relative-level">
        <td class="key">RL</td>
        <td class="value">
          <input
            class="typeable relative-level-input"
            type="text"
            v-model="localCycle.relativeLevel"
            :maxlength="maxRLLength"
          />
        </td>
      </tr>
      <tr class="row shot">
        <td class="key">Shot</td>
        <td class="value">
          <input
            class="typeable shot-input"
            type="text"
            v-model="localCycle.shot"
            :maxlength="maxShotLength"
          />
        </td>
      </tr>
      <tr class="row dump-location">
        <td class="key">Dump Location</td>
        <td class="value">
          <DropDown
            :class="{ error: validationErrors.includes('dumpLocationId') }"
            v-model="localCycle.dumpLocationId"
            :items="locations"
            label="name"
            :useScrollLock="false"
          />
        </td>
      </tr>
    </table>

    <div class="button-group">
      <button class="hx-btn update" @click="onUpdate()" :disabled="!hasChanged || updateInTransit">
        Update
      </button>
      <button class="hx-btn reset" @click="onReset()">Reset</button>
      <button class="hx-btn cancel" @click="onClose()">Cancel</button>
    </div>
  </modal>
</template>

<script>
import { mapState } from 'vuex';
import Modal from '../../modals/Modal.vue';
import LoadingModal from '../../modals/LoadingModal.vue';
import DropDown from '../../dropdown/DropDown.vue';
import { isDateEqual } from '../../../code/time';
import Dately from '../../dately/Dately.vue';
import { uniq } from '../../../code/helpers';

const RANGE_OFFSET = 2 * 3600 * 1000;
const LOAD_UNIT_TYPES = ['Excavator', 'Loader', 'Scratchy'];
const REQUIRED_FIELDS = [
  'assetId',
  'operatorId',
  'startTime',
  'endTime',
  'loadUnitId',
  'loadLocationId',
  'materialTypeId',
  'dumpLocationId',
];

function defaultCycle() {
  return {
    assetId: null,
    operatorId: null,
    startTime: null,
    endTime: null,
    operatorId: null,
    loadUnitId: null,
    loadLocationId: null,
    relativeLevel: null,
    shot: null,
    dumpLocationId: null,
    materialTypeId: null,
  };
}

export default {
  name: 'CycleEditModal',
  components: {
    Modal,
    DropDown,
    Dately,
  },
  props: {
    cycle: { type: Object, default: null },
    show: { type: Boolean, default: false },
    shift: { type: Object, default: null },
  },
  data: () => {
    return {
      localCycle: defaultCycle(),
      updateInTransit: false,
      requestError: '',
      maxRLLength: 63,
      maxShotLength: 63,
      showValidation: false,
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
      locations: state => state.locations,
      materialTypes: state => state.materialTypes,
      timezone: state => state.timezone,
    }),
    haulTrucks() {
      return this.assets.filter(a => a.type === 'Haul Truck');
    },
    loadUnits() {
      return this.assets.filter(a => LOAD_UNIT_TYPES.includes(a.type));
    },
    minDatetime() {
      if (this.shift) {
        return new Date(this.shift.startTime.getTime() - RANGE_OFFSET);
      }
      return null;
    },
    maxDatetime() {
      if (this.shift) {
        return new Date(this.shift.endTime.getTime() + RANGE_OFFSET);
      }
      return null;
    },
    hasChanged() {
      const a = this.cycle || {};
      const b = this.localCycle || {};

      return Object.keys(defaultCycle()).some(key => {
        const aVal = a[key];
        const bVal = b[key];

        if (['startTime', 'endTime'].includes(key)) {
          return !isDateEqual(aVal, bVal);
        }

        return aVal !== bVal;
      });
    },
    validationErrors() {
      if (this.showValidation) {
        const localCycle = this.localCycle;
        const errors = [];
        REQUIRED_FIELDS.forEach(r => {
          if (localCycle[r] == null) {
            errors.push(r);
          }
        });

        if (
          localCycle.startTime &&
          localCycle.endTime &&
          localCycle.startTime.getTime() >= localCycle.endTime.getTime()
        ) {
          errors.push('startTime', 'endTime');
        }

        return uniq(errors);
      }
      return [];
    },
  },
  watch: {
    show(bool) {
      if (bool) {
        this.setLocalCycle(this.cycle);
      }
      this.showValidation = false;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    setLocalCycle(cycle) {
      this.localCycle = { ...defaultCycle(), ...(cycle || {}) };
    },
    setRequestError(msg) {
      this.requestError = msg;
    },
    onUpdate() {
      this.showValidation = true;
      this.setRequestError('');
      if (this.validationErrors.length > 0) {
        console.error('[CycleEdit] Invalid changes');
        return;
      }

      if (this.updateInTransit) {
        console.error('[CycleEdit] Changes already in transit');
        return;
      }

      this.updateInTransit = true;

      const cycle = this.localCycle;
      const payload = {
        id: cycle.id,
        asset_id: cycle.assetId,
        operator_id: cycle.operatorId,
        start_time: cycle.startTime,
        end_time: cycle.endTime,
        load_unit_id: cycle.loadUnitId,
        load_location_id: cycle.loadLocationId,
        material_type_id: cycle.materialTypeId,
        relative_level: cycle.relativeLevel,
        shot: cycle.shot,
        dump_location_id: cycle.dumpLocationId,
      };

      const loading = this.$modal.create(
        LoadingModal,
        { message: 'Updating Cycle' },
        { clickOutsideClose: false },
      );

      this.$channel
        .push('haul:update manual cycle', payload)
        .receive('ok', () => {
          this.updateInTransit = false;
          this.$emit('update');
          loading.close();
          this.onClose();
        })
        .receive('error', resp => {
          this.updateInTransit = false;
          loading.close();
          this.$toasted.global.error(resp.error);
        })
        .receive('timeout', () => {
          this.updateInTransit = false;
          loading.close();
          this.$toasted.global.noComms('Unable to update cycle');
        });
    },
    onReset() {
      this.showValidation = false;
      this.setLocalCycle(this.cycle);
    },
  },
};
</script>

<style>
@import '../../../assets/hxInput.css';

.cycle-edit-modal {
  font-family: 'GE Inspira Sans', sans-serif;
  color: #b6c3cc;
}

/* -------- modal config ------- */
.cycle-edit-modal .modal-container {
  height: auto;
  max-width: 45rem;
}

.cycle-edit-modal > .modal-container-wrapper {
  height: 100%;
  width: 100%;
  padding: 2rem 3rem;
}

/* ---- content ----- */
.cycle-edit-modal .cycle-edit-table {
  width: 100%;
  border-collapse: collapse;
}

.cycle-edit-modal tr.padding {
  height: 2rem;
}

.cycle-edit-modal .row {
  height: 4rem;
}

.cycle-edit-modal .row .key {
  font-size: 2rem;
  width: 15rem;
}

.cycle-edit-modal .row .value {
  padding-left: 2rem;
  font-size: 1.5rem;
  text-align: center;
}

.cycle-edit-modal .row .typeable {
  width: 100%;
}

.cycle-edit-modal .dropdown-wrapper {
  margin-right: 1rem;
}

.cycle-edit-modal .value .dropdown-wrapper {
  height: 2.5rem;
  width: 100%;
}

.cycle-edit-modal .button-group {
  margin-top: 2rem;
  display: flex;
}

.cycle-edit-modal .button-group .hx-btn {
  width: 100%;
  font-size: 1rem;
  margin: 0.1rem 0.05rem;
}

.cycle-edit-modal .button-group .hx-btn[disabled] {
  opacity: 0.5;
  cursor: default;
}

.cycle-edit-modal .datetime-input {
  height: 2.5rem;
}

.cycle-edit-modal .datetime-input .time {
  width: 50%;
}

.cycle-edit-modal .datetime-input .date-selector {
  width: 50%;
}

.cycle-edit-modal .vdatetime-input {
  text-align: center;
  font-size: 1.4rem;
}

.cycle-edit-modal .dropdown-wrapper.error {
  transition: background 0.4s;
  background-color: darkred;
}

.cycle-edit-modal .datetime-input.error .vdatetime-input,
.cycle-edit-modal .datetime-input.error .time .typeable {
  background-color: darkred;
}

.cycle-edit-modal .datetime-input.error .time .typeable:focus {
  color: #b6c3cc;
}
</style>