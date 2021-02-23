<template>
  <StackLayout class="icon-stack" row="0" rowSpan="3" col="2">
    <BatteryIcon height="65" width="65" />

    <StackLayout
      v-if="unreadMessages.length > 0"
      class="icon-wrapper message-wrapper"
      @tap="showUnreadMessageCount"
    >
      <Image
        class="icon message-icon"
        src="~/assets/images/message.png"
        stretch="aspectFill"
        tintColor="#b7c3cd"
        horizontalAlignment="center"
      />
    </StackLayout>

    <StackLayout
      v-if="requiresEngineHours"
      class="icon-wrapper odometer-wrapper"
      @tap="onTapIcon('engineHours')"
    >
      <Image
        class="icon"
        src="~/assets/images/odometer.png"
        stretch="aspectFit"
        tintColor="orange"
        horizontalAlignment="center"
      />
    </StackLayout>

    <StackLayout v-if="showNoWifi" class="icon-wrapper wifi-wrapper" @tap="onTapIcon('noWifif')">
      <Image
        class="icon"
        src="~/assets/images/noWifi.png"
        stretch="aspectFit"
        tintColor="orange"
        horizontalAlignment="center"
      />
    </StackLayout>
  </StackLayout>
</template>

<script>
import IncomingMessage from '../../../common/modals/IncomingMessage.vue';
import BatteryIcon from '../../../common/BatteryIcon.vue';

export default {
  name: 'IconStack',
  components: {
    BatteryIcon,
  },
  data: () => {
    return {};
  },
  computed: {
    requiresEngineHours() {
      return this.$store.state.engineHoursOld;
    },
    showNoWifi() {
      const status = this.$store.state.connection.status;
      return [
        'disconnected_long',
        'disconnected_no_channel',
        'disconnected_suspected_network_failure',
        null,
      ].includes(status);
    },
    unreadMessages() {
      return this.$store.state.unreadOperatorMessages;
    },
  },
  methods: {
    onTapIcon(icon) {
      this.$emit('tap', icon);
    },
    showUnreadMessageCount() {
      if (!this.unreadMessages || this.unreadMessages.length === 0) {
        return;
      }

      const nUnread = this.unreadMessages.length;
      const maxTimestamp = this.unreadMessages[0].timestamp;
      const plural = nUnread === 1 ? '' : 's';
      const msg = `${nUnread} message${plural} unread by Dispatcher`;

      const opts = {
        message: msg,
        timestamp: maxTimestamp,
        prefix: 'Last message sent',
      };

      this.$modalBus.open(IncomingMessage, opts);
    },
  },
};
</script>

<style>
.icon-stack {
  margin-top: 10;
}

.icon-wrapper {
  width: 70;
  height: 70;
  padding: 10;
}

.icon-wrapper.battery-wrapper {
  padding: 0;
}
</style>