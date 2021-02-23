<template>
  <Page
    class="page no-asset-placeholder"
    :actionBarHidden="true"
    androidStatusBarBackground="#0c1419"
  >
    <GridLayout class="no-asset-placeholder" rows="* 2* * 3* * * *">
      <Label row="1" class="heading" :text="text" textAlignment="center" :textWrap="true" />
      <Label
        row="3"
        class="message"
        :text="`UUID: ${formattedDeviceUUID}`"
        textAlignment="center"
        :textWrap="true"
      />
      <Label
        row="4"
        class="message"
        :text="channelStatus"
        textAlignment="center"
        :textWrap="true"
      />

      <Button row="5" text="Logout" @tap="onLogout" width="200" />
    </GridLayout>
  </Page>
</template>

<script>
import { formatDeviceUUID } from '../../../code/helper';
const platformModule = require('tns-core-modules/platform');

export default {
  name: 'NoAssetPlaceholder',
  props: {
    asset: { type: Object, default: null },
  },
  data: () => {
    return {
      channel: null,
    };
  },
  computed: {
    formattedDeviceUUID() {
      return formatDeviceUUID(platformModule.device.uuid.toUpperCase());
    },
    channelStatus() {
      return this.$store.state.connection.status || 'unknown';
    },
    assetType() {
      return (this.asset || {}).type;
    },
    assetName() {
      return (this.asset || {}).name;
    },
    text() {
      const assetName = this.assetName;
      if (!assetName) {
        return 'No asset assigned to this device';
      }

      return `Asset '${assetName}' does not have an asset type`;
    },
  },
  mounted() {
    this.$emit('mounted');
  },
  methods: {
    onLogout() {
      this.$emit('logout');
    },
  },
};
</script>

<style>
.no-asset-placeholder .heading {
  font-size: 50;
}

.no-asset-placeholder .message {
  font-size: 40;
}
</style>