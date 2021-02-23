<template>
  <GridLayout class="engine-hours-modal" columns="* * * * * *" rows="2*, 2*, 4*, 3*">
    <Label
      class="title"
      row="0"
      col="0"
      colSpan="6"
      text="Enter Engine Hours"
      horizontalAlignment="center"
    />
    <!-- top row -->
    <Label class="key" row="1" col="0" colSpan="2" text="Last Hours" horizontalAlignment="center" />
    <Label
      class="hours"
      row="1"
      col="2"
      colSpan="2"
      :text="lastEngineHours"
      horizontalAlignment="center"
    />
    <Label
      class="time"
      row="1"
      col="4"
      colSpan="2"
      :text="lastEngineTime"
      horizontalAlignment="center"
    />

    <!-- second row -->
    <TextField
      row="2"
      col="0"
      colSpan="6"
      class="text-field"
      keyboardType="number"
      hint="Current Engine Hours"
      v-model="engineHoursValue"
    />

    <!-- actions -->
    <Button
      row="3"
      col="0"
      colSpan="3"
      class="button submit-button"
      :isEnabled="isEnabled"
      text="Submit"
      textTransform="capitalize"
      @tap="onSubmit"
    />
    <Button
      row="3"
      col="3"
      colSpan="3"
      class="button cancel-button"
      text="Cancel"
      textTransform="capitalize"
      @tap="onCancel"
    />
  </GridLayout>
</template>

<script>
import EngineHoursConfirmModal from './EngineHoursConfirmModal.vue';

const SECONDS_TO_HOURS = 3600;
const MAX_HOURS_PADDING = 2;

function numberWithCommas(x) {
  let parts = x.toString().split('.');
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return parts.join('.');
}

function hoursBetween(ts1, ts2) {
  if (!ts1 || !ts2) {
    return null;
  }

  const milliseconds = ts1.getTime() - ts2.getTime();
  const hours = milliseconds / 1000 / SECONDS_TO_HOURS;
  return hours;
}

export default {
  name: 'EngineHoursModal',
  props: {
    asset: { type: Object, default: null },
    operator: { type: Object, default: null },
  },
  data: () => {
    return {
      engineHoursValue: '',
    };
  },
  computed: {
    validAsset() {
      return !!this.asset;
    },
    isEnabled() {
      if (!this.asset || !this.operator || !this.engineHoursValue) {
        return false;
      }

      return true;
    },
    engineHours() {
      return this.$store.state.engineHours;
    },
    lastEngineHours() {
      const hours = (this.engineHours || {}).hours;
      if (!hours && hours !== 0) {
        return 'Never Entered';
      }
      return numberWithCommas(hours);
    },
    lastEngineTime() {
      const timestamp = (this.engineHours || {}).timestamp;
      if (timestamp) {
        const ago = hoursBetween(new Date(), timestamp);
        if (ago <= 1) {
          return '< 1 hour ago';
        }
        if (ago < 48) {
          return `${ago.toFixed(1)} hours ago`;
        }
        const days = Math.trunc(ago / 24);
        return `> ${days} days ago`;
      }
      return '';
    },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onCancel() {
      this.close();
    },
    showError(msg) {
      this.$toaster.red(msg, 'long').show();
    },
    onSubmit() {
      if (!this.validAsset) {
        this.showError('Not assigned to an asset');
        return;
      }

      const hours = parseFloat(this.engineHoursValue);

      if (!hours || hours < 0) {
        this.showError('Must be a positive number');
        return;
      }

      if (!this.validAsset) {
        this.showError('No asset assigned to this tablet');
        return;
      }

      const engineHours = {
        hours,
        assetId: this.asset.id,
        operatorId: (this.operator || {}).id,
        timestamp: Date.now(),
      };

      if (!this.engineHours || !this.engineHours.hours) {
        this.submitEngineHours(engineHours);
        return;
      }

      const originalHours = this.engineHours.hours;
      const maxHoursDiff = hoursBetween(new Date(), this.engineHours.timestamp);
      const hoursDiff = hours - originalHours;

      const originalCommas = numberWithCommas(originalHours);
      const enteredCommas = numberWithCommas(hours);

      if (hoursDiff > maxHoursDiff + MAX_HOURS_PADDING) {
        const expected = numberWithCommas(Math.ceil(originalHours + maxHoursDiff));
        const msg = `The entered hours (${enteredCommas}) are greater than expected (${expected})`;
        this.checkEngineHours(engineHours, msg);
      } else if (hoursDiff < 0) {
        const msg = `The entered hours (${enteredCommas}) are less than the current hours (${originalCommas})`;
        this.checkEngineHours(engineHours, msg);
      } else {
        this.submitEngineHours(engineHours);
      }
    },
    checkEngineHours(engineHours, message) {
      const opts = { hours: engineHours.hours, message };

      this.$modalBus.open(EngineHoursConfirmModal, opts).onClose(answer => {
        if (answer === 'accept') {
          this.submitEngineHours(engineHours);
        }
      });
    },
    submitEngineHours(engineHours) {
      this.$store.dispatch('submitEngineHours', { engineHours, channel: this.$channel });
      this.$emit('submit', engineHours);
      this.close(engineHours);
    },
  },
};
</script>

<style>
.engine-hours-modal {
  width: 80%;
  height: 70%;
  background-color: #1c323d;
  padding: 20;
  border-width: 1;
  border-color: #d6d7d7;
}

.engine-hours-modal label {
  color: #b7c3cd;
}

.engine-hours-modal .text-field {
  margin: 30 10;
}

.engine-hours-modal .submit-button,
.engine-hours-modal .cancel-button {
  font-size: 30;
}

.engine-hours-modal .submit-button[isEnabled='false'] {
  background-color: #1e303a;
  border-color: #1e303a;
  color: #747472;
  opacity: 0.8;
}

.engine-hours-modal .title {
  padding-left: 20;
  text-align: left;
  vertical-align: center;
  font-size: 45;
  text-decoration: underline;
}

.engine-hours-modal .key {
  padding-left: 20;
  text-align: left;
  vertical-align: center;
  font-size: 38;
}

.engine-hours-modal .error {
  font-size: 20;
  text-align: center;
}

.engine-hours-modal .hours {
  text-align: center;
  vertical-align: center;
  font-size: 30;
}

.engine-hours-modal .time {
  text-align: center;
  vertical-align: center;
  font-size: 24;
}
</style>