<template>
  <GridLayout class="tally-home" width="100%" columns="*" rows="*">
    <StackLayout height="100%" v-if="!activeCycle" class="start-overlay" verticalAlignment="center">
      <Button class="button start-cycle-btn" text="Start New Cycle" @tap="onStartNewCycle" />
      <Button
        v-if="lastCycle"
        class="button repeat-cycle-btn"
        text="Repeat Last Cycle"
        @tap="onStartRepeatCycle"
      />
    </StackLayout>
    <GridLayout v-else class="tally-area" rows="4* *">
      <GridLayout row="0" class="fields" rows="* * * *" columns="* * * * * *">
        <!-- LEFT SIDE -->
        <!-- Start time -->
        <CenteredLabel row="0" col="0" class="key" text="Start" />
        <CenteredLabel
          row="0"
          col="1"
          colSpan="2"
          class="key"
          :text="formatDate(activeCycle.startTime)"
        />

        <!-- Duration -->
        <CenteredLabel row="1" col="0" class="key" text="Duration" />
        <CenteredLabel row="1" col="1" colSpan="2" class="key" :text="formatSeconds(duration)" />

        <!-- load unit -->
        <CenteredLabel row="2" col="0" class="key" text="Load Unit" />
        <DropDown
          row="2"
          col="1"
          colSpan="2"
          :class="{ error: validationErrors.includes('loadUnitId') }"
          :value="activeCycle.loadUnitId"
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
          :value="activeCycle.materialTypeId"
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
          :value="activeCycle.loadLocationId"
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
          :value="activeCycle.relativeLevel"
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
          :value="activeCycle.shot"
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
          :value="activeCycle.dumpLocationId"
          :options="locationOptions"
          filter="simple"
          @input="setCycleValue('dumpLocationId', $event)"
        />
      </GridLayout>

      <GridLayout row="1" columns="* * *">
        <Button col="0" class="button" text="End Cycle" @tap="onEndCycle" />
        <Button col="1" class="button" text="Clear Content" @tap="onClearCycleContent" />
        <Button col="2" class="button" text="Delete Cycle" @tap="onDeleteCycle" />
      </GridLayout>
    </GridLayout>
  </GridLayout>
</template>

<script>
import { mapState } from 'vuex';
import CenteredLabel from '../../../common/CenteredLabel.vue';
import DropDown from '../../../common/DropDown.vue';
import ConfirmModal from '../../../common/modals/ConfirmModal.vue';
import EngineHoursModal from '../../../common/modals/EngineHoursModal.vue';
import { formatDate, formatSeconds, toUtcDate, uniq } from '../../../code/helper';

const CLEAR_CONFIRM = 'Yes';
const END_CONFIRM = 'Yes';
const CANCEL_CONFIRM = 'Yes';

const REQUIRED_FIELDS = ['loadUnitId', 'loadLocationId', 'materialTypeId', 'dumpLocationId'];
const LOAD_UNIT_TYPES = ['Excavator', 'Loader', 'Scratchy'];

const TIME_BETWEEN_ENGINE_HOURS = 2 * 60 * 1000;

export default {
  name: 'TallyHome',
  components: {
    CenteredLabel,
    DropDown,
  },
  props: {
    asset: { type: Object, required: true },
    operator: { type: Object, required: true },
  },
  data: () => {
    return {
      duration: 0,
      timingInterval: null,
      validationErrors: [],
      customRLs: [],
      customShots: [],
    };
  },
  computed: {
    ...mapState('constants', {
      loadUnits: state => state.assets.filter(a => LOAD_UNIT_TYPES.includes(a.type)),
      locations: state => state.locations,
      materialTypes: state => state.materialTypes,
    }),
    cycles() {
      return this.$store.state.haulTruck.manualCycles;
    },
    loadUnitOptions() {
      const loadUnits = this.loadUnits.map(a => ({ id: a.id, text: a.name }));
      loadUnits.sort((a, b) => a.text.localeCompare(b.text));
      return loadUnits;
    },
    locationOptions() {
      return this.locations.map(l => ({ id: l.id, text: l.name }));
    },
    materialTypeOptions() {
      return this.materialTypes.map(m => ({ id: m.id, text: m.commonName }));
    },
    RLOptions() {
      const existingRLs = uniq(this.cycles.map(c => c.relativeLevel).filter(rl => rl));
      return existingRLs.concat(this.customRLs);
    },
    shotOptions() {
      const existingShots = uniq(this.cycles.map(c => c.shot).filter(s => s));
      return existingShots.concat(this.customShots);
    },
    activeCycle() {
      return this.$store.state.haulTruck.activeManualCycle;
    },
    lastCycle() {
      const cycles = this.cycles.slice();
      if (cycles.length === 0) {
        return null;
      }

      cycles.sort((a, b) => b.startTime.getTime() - a.startTime.getTime());
      return cycles[0];
    },
    lastEngineHours() {
      return this.$store.state.engineHours;
    },
  },
  mounted() {
    this.calculateDuration();
    this.timingInterval = setInterval(() => this.calculateDuration(), 1000);
  },
  beforeDestroy() {
    this.timingInterval = clearInterval(this.timingInterval);
  },
  methods: {
    calculateDuration() {
      const cycle = this.activeCycle || {};
      if (!cycle.startTime) {
        this.duration = 0;
        return;
      }

      this.duration = Math.trunc((Date.now() - cycle.startTime.getTime()) / 1000);
    },
    setCycleValue(key, value) {
      this.$store.dispatch('haulTruck/updateActiveManualCycle', { [key]: value });
      this.clearValidationError(key);
    },
    setRelativeLevel(option) {
      if (option.new) {
        this.customRLs.push(option.text);
      }
      this.setCycleValue('relativeLevel', option.text);
    },
    setShot(option) {
      if (option.new) {
        this.customShots.push(option.text);
      }
      this.setCycleValue('shot', option.text);
    },
    afterEngineHours(callback) {
      const latestEngineHours = this.lastEngineHours || {};

      // if engine hours were entered recently, dont ask again
      if (
        latestEngineHours.timestamp &&
        Date.now() - latestEngineHours.timestamp.getTime() < TIME_BETWEEN_ENGINE_HOURS
      ) {
        callback();
        return;
      }

      const opts = {
        asset: this.asset,
        operator: this.operator,
      };

      this.$modalBus.open(EngineHoursModal, opts).onClose(answer => {
        if (answer) {
          callback();
        }
      });
    },
    onStartNewCycle() {
      this.$store.dispatch('haulTruck/startActiveManualCycle', {
        assetId: this.asset.id,
        operatorId: this.operator.id,
        startTime: new Date(),
      });
    },
    onStartRepeatCycle() {
      const cycle = this.lastCycle;
      const repeatCycle = {
        assetId: this.asset.id,
        operatorId: this.operator.id,
        startTime: new Date(),
        loadUnitId: cycle.loadUnitId,
        loadLocationId: cycle.loadLocationId,
        relativeLevel: cycle.relativeLevel,
        shot: cycle.shot,
        materialTypeId: cycle.materialTypeId,
        dumpLocationId: cycle.dumpLocationId,
      };

      this.$store.dispatch('haulTruck/startActiveManualCycle', repeatCycle);
    },
    onEndCycle() {
      this.setValidationErrors();
      if (this.validationErrors.length === 0) {
        const opts = {
          message: 'Do you want to end this cycle?',
          confirmName: END_CONFIRM,
          rejectName: 'No',
        };

        this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
          if (answer === END_CONFIRM) {
            const cycle = { ...this.activeCycle, endTime: new Date(), timestamp: new Date() };
            this.$store.dispatch('haulTruck/submitManualCycle', {
              cycle,
              channel: this.$channel,
            });
            this.$store.dispatch('haulTruck/clearActiveManualCycle');
          }
        });
      }
    },
    onClearCycleContent() {
      const opts = {
        message: `Do you want to clear all fields?`,
        confirmName: CLEAR_CONFIRM,
        rejectName: 'No',
      };

      this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
        if (answer === CLEAR_CONFIRM) {
          this.$store.dispatch('haulTruck/startActiveManualCycle', {
            assetId: this.asset.id,
            operatorId: this.operator.id,
            startTime: new Date(),
          });
        }
      });
    },
    onDeleteCycle() {
      const opts = {
        message: 'Do you want to delete the current cycle?',
        confirmName: CANCEL_CONFIRM,
        rejectName: 'No',
      };

      this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
        if (answer === CANCEL_CONFIRM) {
          this.$store.dispatch('haulTruck/clearActiveManualCycle');
          this.clearValidationErrors();
        }
      });
    },
    setValidationErrors() {
      const errors = [];
      REQUIRED_FIELDS.forEach(r => {
        if (this.activeCycle[r] == null) {
          errors.push(r);
        }
      });

      this.validationErrors = errors;
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
    formatDate(epoch) {
      const date = toUtcDate(epoch);
      return formatDate(date, '%Y-%m-%d %HH:%MM:%SS');
    },
    formatSeconds(totalSeconds) {
      if (!totalSeconds && totalSeconds !== 0) {
        return '--';
      }
      return formatSeconds(totalSeconds);
    },
  },
};
</script>

<style>
.tally-home .start-overlay {
  background-color: rgba(100, 99, 99, 0.247);
}

.tally-home .tally-area {
  padding: 20;
}

.tally-home .button {
  font-size: 26;
}

.tally-home .fields {
  padding-bottom: 30;
}

.tally-home .key {
  font-size: 26;
}

.tally-home .dropdown-btn,
.tally-home .dropdown-btn-ellipses {
  font-size: 30;
}

.tally-home .error .dropdown-btn {
  background: rgb(136, 0, 0);
}

.tally-home .start-cycle-btn,
.tally-home .repeat-cycle-btn {
  height: 120;
  font-size: 26;
  width: 80%;
}
</style>