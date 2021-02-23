<template>
  <GridLayout class="tally-edit-modal" rows="4* *">
    <GridLayout row="0" class="fields" rows="* * * *" columns="* * * * * *">
      <!-- LEFT SIDE -->
      <!-- Start time -->
      <CenteredLabel row="0" col="0" class="key" text="Start" />
      <DateTimePickerFields
        v-if="ready"
        row="0"
        col="1"
        colSpan="2"
        class="date-picker"
        :class="{ error: validationErrors.includes('startTime') }"
        v-model="startTime"
        timeFormat="HH:mm"
        locale="en_GB"
      />

      <!-- End -->
      <CenteredLabel row="1" col="0" class="key" text="End" />
      <DateTimePickerFields
        v-if="ready"
        row="1"
        col="1"
        colSpan="2"
        class="date-picker"
        :class="{ error: validationErrors.includes('endTime') }"
        v-model="endTime"
        timeFormat="HH:mm"
        locale="en_GB"
      />

      <!-- load unit -->
      <CenteredLabel row="2" col="0" class="key" text="Load Unit" />
      <DropDown
        row="2"
        col="1"
        colSpan="2"
        :class="{ error: validationErrors.includes('loadUnitId') }"
        :value="localCycle.loadUnitId"
        :options="loadUnitOptions"
        @input="setCycleValue('loadUnitId', $event)"
      />

      <!-- Material type -->
      <CenteredLabel row="3" col="0" class="key" text="Material" />
      <DropDown
        row="3"
        col="1"
        colSpan="2"
        :class="{ error: validationErrors.includes('materialTypeId') }"
        :value="localCycle.materialTypeId"
        :options="materialTypeOptions"
        @input="setCycleValue('materialTypeId', $event)"
      />

      <!-- RIGHT SIDE -->
      <!-- Load location -->
      <CenteredLabel row="0" col="3" class="key" text="Load" />
      <DropDown
        row="0"
        col="4"
        colSpan="2"
        :class="{ error: validationErrors.includes('loadLocationId') }"
        :value="localCycle.loadLocationId"
        :options="locationOptions"
        filter="simple"
        @input="setCycleValue('loadLocationId', $event)"
      />

      <!-- RL -->
      <CenteredLabel row="1" col="3" class="key" text="RL" />
      <DropDown
        row="1"
        col="4"
        colSpan="2"
        :value="localCycle.relativeLevel"
        :options="RLOptions"
        :allowInput="true"
        keyboardType="number"
        @input="setRelativeLevel"
      />

      <!-- SHOT -->
      <CenteredLabel row="2" col="3" class="key" text="Shot" />
      <DropDown
        row="2"
        col="4"
        colSpan="2"
        :value="localCycle.shot"
        :options="shotOptions"
        :allowInput="true"
        @input="setShot"
      />

      <!-- dump location -->
      <CenteredLabel row="3" col="3" class="key" text="Dump" />
      <DropDown
        row="3"
        col="4"
        colSpan="2"
        :class="{ error: validationErrors.includes('dumpLocationId') }"
        :value="localCycle.dumpLocationId"
        :options="locationOptions"
        filter="simple"
        @input="setCycleValue('dumpLocationId', $event)"
      />
    </GridLayout>

    <GridLayout row="1" columns="* * *">
      <Button col="0" class="button" text="Submit" @tap="onSubmit" :isEnabled="hasChanged" />
      <Button col="1" class="button" text="Delete" @tap="onDelete" :isEnabled="canDelete" />
      <Button col="2" class="button" text="Cancel" @tap="onCancel" />
    </GridLayout>
  </GridLayout>
</template>

<script>
import CenteredLabel from '../../common/CenteredLabel.vue';
import DropDown from '../../common/DropDown.vue';
import ConfirmModal from '../../common/modals/ConfirmModal.vue';
import { copyDate, formatDate, toUtcDate, uniq, isEqualDate } from '../../code/helper';

const REQUIRED_FIELDS = [
  'startTime',
  'endTime',
  'loadUnitId',
  'loadLocationId',
  'materialTypeId',
  'dumpLocationId',
];

const CHANGEABLE_KEYS = [
  'startTime',
  'endTime',
  'loadUnitId',
  'loadLocationId',
  'materialTypeId',
  'dumpLocationId',
  'relativeLevel',
  'shot',
];

function copyCycle(cycle) {
  if (!cycle) {
    return {};
  }

  const now = new Date();

  return {
    id: cycle.id,
    assetId: cycle.assetId,
    operatorId: cycle.operatorId,
    startTime: copyDate(cycle.startTime) || new Date(now),
    endTime: copyDate(cycle.endTime) || new Date(now),
    loadUnitId: cycle.loadUnitId,
    loadLocationId: cycle.loadLocationId,
    relativeLevel: cycle.relativeLevel,
    shot: cycle.shot,
    materialTypeId: cycle.materialTypeId,
    dumpLocationId: cycle.dumpLocationId,
  };
}

export default {
  name: 'TallyEditModal',
  components: {
    CenteredLabel,
    DropDown,
  },
  props: {
    cycle: { type: Object, default: () => ({}) },
    loadUnits: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    relativeLevels: { type: Array, default: () => [] },
    shots: { type: Array, default: () => [] },
    materialTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      itemHeight: 100,
      localCycle: {},
      date: new Date(),
      customRLs: [],
      customShots: [],
      error: '',
      validationErrors: [],
      ready: false,
    };
  },
  computed: {
    hasChanged() {
      return CHANGEABLE_KEYS.some(key => {
        if (['startTime', 'endTime'].includes(key)) {
          return !isEqualDate(this.cycle[key], this.localCycle[key]);
        } else {
          return this.cycle[key] !== this.localCycle[key];
        }
      });
    },
    canDelete() {
      return !!this.localCycle.id && this.$store.state.connection.isConnected;
    },
    loadUnitOptions() {
      return this.loadUnits.map(l => ({ id: l.id, text: l.name }));
    },
    locationOptions() {
      return this.locations.map(l => ({ id: l.id, text: l.name }));
    },
    materialTypeOptions() {
      return this.materialTypes.map(m => ({ id: m.id, text: m.commonName }));
    },
    RLOptions() {
      return [].concat(this.relativeLevels).concat(this.customRLs);
    },
    shotOptions() {
      return [].concat(this.shots).concat(this.customShots);
    },
    startTime: {
      get() {
        return this.localCycle.startTime;
      },
      set(args) {
        this.setCycleValue('startTime', args.value);
      },
    },
    endTime: {
      get() {
        return this.localCycle.endTime;
      },
      set(args) {
        this.setCycleValue('endTime', args.value);
      },
    },
  },
  mounted() {
    this.localCycle = copyCycle(this.cycle);
    this.ready = true;
  },
  methods: {
    setCycleValue(key, value) {
      this.localCycle[key] = value;
      this.clearValidationError(key);
    },
    setRelativeLevel(option) {
      if (option.new) {
        this.customRLs.push(option.text);
      }
      this.localCycle.relativeLevel = option.text;
    },
    setShot(option) {
      if (option.new) {
        this.customShots.push(option.text);
      }
      this.localCycle.shot = option.text;
    },
    close(resp) {
      this.$emit('close', resp);
    },
    onCancel() {
      this.close();
    },
    onSubmit() {
      this.setValidationErrors();
      if (this.validationErrors.length === 0) {
        const confirmName = 'Yes';
        const opts = {
          message: 'Do you want to submit these changes?',
          confirmName,
          rejectName: 'No',
        };

        this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
          if (answer === confirmName) {
            const cycle = { ...this.localCycle, timestamp: new Date() };
            this.$store.dispatch('haulTruck/submitManualCycle', { cycle, channel: this.$channel });
            this.close();
          }
        });
      }
    },
    onDelete() {
      const confirmName = 'Yes';
      const opts = {
        message: `Are you sure you want to delete this cycle?`,
        confirmName,
        rejectName: 'No',
      };

      const onError = msg => {
        this.$toaster.red(msg).show();
      };

      this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
        if (answer === confirmName) {
          this.$channel
            .push('haul:delete manual cycle', this.localCycle.id)
            .receive('ok', () => {
              this.$toaster.info('Cycle deleted').show();
              this.close();
            })
            .receive('error', () => onError('Cannot delete cycle at this time'))
            .receive('timeout', () => onError('Must have connection to delete a cycle'));
        }
      });
    },
    setValidationErrors() {
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
        this.$toaster.red('Start must come before end', 'long').show();
      }

      this.validationErrors = uniq(errors);
    },
    clearValidationErrors() {
      this.validationErrors = [];
    },
    clearValidationError(key) {
      const index = this.validationErrors.indexOf(key);
      if (index !== -1) {
        this.validationErrors.splice(index, 1);
      }
    },
  },
};
</script>

<style>
.tally-edit-modal {
  height: 95%;
  width: 95%;
  background-color: #1c323d;
  padding: 20;
  color: black;
  border-width: 1;
  border-color: #d6d7d7;
}

.tally-edit-modal .date-picker {
  background-color: #d6d7d7;
  margin: 5 4;
  padding-left: 20;
  border-radius: 2;
}

.tally-edit-modal .button {
  font-size: 26;
}

.tally-edit-modal .button[isEnabled='false'] {
  background-color: #1e303a;
  border-color: #1e303a;
  color: #747472;
  opacity: 0.8;
}

.tally-edit-modal .fields {
  padding-bottom: 30;
}

.tally-edit-modal .key {
  color: #b7c3cd;
  font-size: 26;
}

.tally-edit-modal .dropdown-btn,
.tally-edit-modal .dropdown-btn-ellipses {
  font-size: 26;
}

.tally-edit-modal .error .dropdown-btn,
.tally-edit-modal .error.date-picker {
  background: rgb(136, 0, 0);
  color: white;
}
</style>