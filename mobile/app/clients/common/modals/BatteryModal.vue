<template>
  <GridLayout class="battery-modal" columns="*, *" rows="60 60 60 60 60 60">
    <CenteredLabel row="0" col="0" class="info-key" text="Level" />
    <CenteredLabel row="0" col="1" class="info-value" :text="`${info.percent}%`" />

    <CenteredLabel row="1" col="0" class="info-key" text="Health" />
    <CenteredLabel row="1" col="1" class="info-value" :text="info.health" />

    <CenteredLabel row="2" col="0" class="info-key" text="Status" />
    <CenteredLabel row="2" col="1" class="info-value" :text="info.status" />

    <CenteredLabel row="3" col="0" class="info-key" text="Temperature" />
    <CenteredLabel row="3" col="1" class="info-value" :text="`${info.temperature} °C`" />

    <CenteredLabel row="4" col="0" class="info-key" text="Voltage" />
    <CenteredLabel row="4" col="1" class="info-value" :text="`${info.voltage} V`" />

    <CenteredLabel row="5" col="0" class="info-key" text="Last Updated" />
    <CenteredLabel row="5" col="1" class="info-value" :text="age" />
  </GridLayout>
</template>

<script>
import CenteredLabel from '../CenteredLabel.vue';
import { formatDate } from '../../code/helper';
export default {
  name: 'BatteryModal',
  components: {
    CenteredLabel,
  },
  data: () => {
    return {
      interval: null,
      ago: null,
    };
  },
  computed: {
    info() {
      return this.$store.getters['battery/info'];
    },
    age() {
      const age = this.ago;
      if (age == null) {
        return '';
      }

      const minutes = Math.trunc(age / 60);
      if (minutes === 1) {
        return `${minutes} minute ago`;
      }

      if (minutes > 1) {
        return `${minutes} minutes ago`;
      }

      if (age === 1) {
        return `${age} second ago`;
      }
      return `${age} seconds ago`;
    },
  },
  mounted() {
    this.updateAgo();
    this.interval = setInterval(() => {
      this.updateAgo();
    }, 1000);
  },
  beforeDestroy() {
    clearInterval(this.interval);
  },
  methods: {
    updateAgo() {
      if (this.info.updatedAt != null) {
        this.ago = Math.trunc((Date.now() - this.info.updatedAt.getTime()) / 1000);
      }
    },
  },
};
</script>

<style>
.battery-modal {
  background-color: white;
  width: 450;
  padding: 25 25;
}

.battery-modal .centered-label {
  color: black;
}

.battery-modal .info-key {
  font-weight: 500;
  font-size: 25;
}

.battery-modal .info-value {
  font-size: 20;
}
</style>