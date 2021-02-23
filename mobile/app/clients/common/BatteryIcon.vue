<template>
  <Gridlayout class="battery-container">
    <Image
      class="icon battery"
      :src="icon"
      stretch="aspectFit"
      horizontalAlignment="right"
      :tintColor="tint"
    />
    <Image
      class="icon battery-charging"
      :src="chargingIcon"
      stretch="aspectFit"
      horizontalAlignment="right"
      :tintColor="flashColor || 'transparent'"
      @tap="showBatteryInfo()"
    />
  </Gridlayout>
</template>

<script>
import BatteryModal from './modals/BatteryModal.vue';

export default {
  name: 'BatteryIcon',
  data: () => {
    return {
      flashInterval: null,
      flashColor: null,
    };
  },
  computed: {
    isCharging() {
      return this.$store.state.battery.isCharging;
    },
    percent() {
      return this.$store.state.battery.percent;
    },
    icon() {
      const percent = this.percent;
      if (percent > 95) {
        return '~/assets/images/battery100.png';
      } else if (percent >= 70) {
        return '~/assets/images/battery75.png';
      } else if (percent >= 50) {
        return '~/assets/images/battery50.png';
      } else {
        return '~/assets/images/battery25.png';
      }
    },
    chargingIcon() {
      return this.isCharging
        ? '~/assets/images/batteryCharging.png'
        : '~/assets/images/battery0.png';
    },
    tint() {
      return this.percent > 10 ? 'green' : 'red';
    },
  },
  watch: {
    percent: {
      immediate: true,
      handler(percent) {
        if (percent < 10) {
          this.startFlashing();
        } else {
          this.stopFlashing();
        }
      },
    },
  },
  methods: {
    showBatteryInfo() {
      this.$modalBus.open(BatteryModal);
    },
    startFlashing() {
      if (!this.flashInterval) {
        this.flashInterval = setInterval(() => {
          this.flashColor = this.flashColor ? null : 'red';
        }, 1000);
      }
    },
    stopFlashing() {
      this.flashColor = null;
      this.flashInterval = clearInterval(this.flashInterval);
    },
  },
};
</script>

<style>
.battery-container {
  padding: 0 10;
}
</style>