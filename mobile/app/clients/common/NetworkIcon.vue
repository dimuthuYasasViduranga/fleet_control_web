<template>
  <Gridlayout class="network-container">
    <Image
      class="icon network"
      :src="icon"
      stretch="aspectFit"
      horizontalAlignment="right"
      :tintColor="tint"
      @tap="showNetworkInfo()"
    />
  </Gridlayout>
</template>

<script>
import { mapState } from 'vuex';
import NetworkModal from './modals/NetworkModal.vue';

const NETWORK_UPDATE_INTERVAL = 10 * 1000;

export default {
  name: 'NetworkIcon',
  data: () => {
    return {
      networkUpdateInterval: null,
    };
  },
  computed: {
    ...mapState('network', {
      updatedAt: state => state.updatedAt,
      type: state => state.type,
    }),
    icon() {
      if (this.type) {
        return `~/assets/images/wifi.png`;
      }
      return `~/assets/images/noWifi.png`;
    },
    tint() {
      return !this.type ? 'red' : 'transparent';
    },
  },
  mounted() {
    this.$store.dispatch('network/forceUpdate');
    this.networkUpdateInterval = setInterval(
      () => this.$store.dispatch('network/forceUpdate'),
      NETWORK_UPDATE_INTERVAL,
    );
  },
  beforeDestroy() {
    clearInterval(this.networkUpdateInterval);
  },
  methods: {
    showNetworkInfo() {
      this.$modalBus.open(NetworkModal);
    },
  },
};
</script>

<style>
.network-container {
  padding: 0 10;
}
</style>