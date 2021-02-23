<template>
  <StackLayout class="clients">
    <HaulTruckClient
      v-if="assetType.primary === 'Haul Truck'"
      :class="connectionClass"
      :operator="operator"
      :asset="asset"
      @mounted="onMounted()"
      @confirmLogout="onConfirmLogout()"
    />
    <DigUnitClient
      v-else-if="assetType.secondary === 'Dig Unit'"
      :class="connectionClass"
      :operator="operator"
      :asset="asset"
      @mounted="onMounted()"
      @confirmLogout="onConfirmLogout()"
    />
    <WatercartClient
      v-else-if="assetType.primary === 'Watercart'"
      :class="connectionClass"
      :operator="operator"
      :asset="asset"
      @mounted="onMounted()"
      @confirmLogout="onConfirmLogout()"
    />
    <GeneralClient
      v-else-if="assetType.primary"
      :class="connectionClass"
      :operator="operator"
      :asset="asset"
      @mounted="onMounted()"
      @confirmLogout="onConfirmLogout()"
    />
    <NoAssetPlaceholder v-else :asset="asset" />
  </StackLayout>
</template>

<script>
import HaulTruckClient from './haul_truck/HaulTruckClient.vue';
import DigUnitClient from './dig_unit/DigUnitClient.vue';
import WatercartClient from './watercart/WatercartClient.vue';
import GeneralClient from './general/GeneralClient.vue';
import NoAssetPlaceholder from './common/pages/no_asset/NoAssetPlaceholder.vue';

function getConnectionClass(status) {
  switch (status) {
    case 'connected':
      return '';
    case 'disconnected':
      return 'connection-offline';
    case 'disconnected_long':
      return 'connection-long-offline';
    default:
      return 'connection-suspected-network-failure';
  }
}

export default {
  name: 'Clients',
  components: {
    HaulTruckClient,
    DigUnitClient,
    GeneralClient,
    WatercartClient,
    NoAssetPlaceholder,
  },
  props: {
    isLoggedIn: { type: Boolean, default: false },
    connectionStatus: { type: String, default: null },
    // should say "NOT FOUND" if there is no operator, but still logged in
    operator: { type: Object, default: null },
    // used to determine the client type. if not asset, show "NO ASSET PAGE"
    asset: { type: Object, default: null },
  },
  data: () => {
    return {
      connectedOnce: false,
    };
  },
  computed: {
    assetType() {
      const asset = this.asset || {};
      return {
        primary: asset.type,
        secondary: asset.secondaryType,
      };
    },
    isConnected() {
      return this.connectionStatus === 'connected';
    },
    connectionClass() {
      return getConnectionClass(this.connectionStatus);
    },
  },
  watch: {
    isLoggedIn: {
      immediate: true,
      handler(isLoggedIn) {
        if (!isLoggedIn) {
          this.connectedOnce = false;
        }
      },
    },
    isConnected: {
      immediate: true,
      handler(isConnected) {
        if (isConnected && this.isLoggedIn) {
          this.connectedOnce = true;
        }
      },
    },
  },
  methods: {
    pass(topic, event) {
      this.$emit(topic, event);
    },
    onConfirmLogout() {
      this.$emit('confirmLogout');
    },
    onMounted() {
      this.$emit('mounted');
    },
  },
};
</script>

<style>
/* These connection classes cannot be further scoped (nativescript issue) */
.connection-offline {
  border-width: 10;
  border-color: gray;
}

.connection-long-offline {
  border-width: 10;
  border-color: orange;
}

.connection-suspected-network-failure {
  border-width: 10;
  border-color: orangered;
}
</style>