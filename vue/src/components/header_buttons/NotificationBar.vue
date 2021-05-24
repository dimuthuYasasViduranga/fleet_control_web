<template>
  <div v-if="show" class="notification-bar blink" :class="state.class" @click="enact()">
    {{ state.message || 'No Notifications' }}
  </div>
</template>

<script>
import { formatSecondsRelative } from '@/code/time';
const RELOAD_NOTIFICATION_AFTER = 5 * 60; // 5 minutes

function timeSince(now, datetime) {
  if (!datetime) {
    return;
  }

  const seconds = Math.trunc((now - datetime.getTime()) / 1000);

  if (seconds === 0) {
    return;
  }

  if (seconds < RELOAD_NOTIFICATION_AFTER) {
    return formatSecondsRelative(seconds);
  }

  return formatSecondsRelative(seconds) + ' (click to reload)';
}

export default {
  name: 'NotificationBar',
  data: () => {
    return {
      connectedOnce: false,
    };
  },
  computed: {
    overlayOpen() {
      return this.$store.state.overlayOpen;
    },
    nUnreadMsgs() {
      return this.$store.getters.unreadOperatorMessages.length;
    },
    offline() {
      return !this.$store.state.connection.isConnected;
    },
    lastDisconnectedAt() {
      return this.$store.state.connection.lastDisconnectedAt;
    },
    state() {
      if (this.offline && this.connectedOnce) {
        const ago = timeSince(this.$everySecond.timestamp, this.lastDisconnectedAt);
        let message = 'You are offline';

        if (ago) {
          message += `. Last connected ${ago}`;
        }

        return {
          message,
          action: this.refreshPage,
          class: 'offline',
        };
      }
      if (this.nUnreadMsgs > 0) {
        return {
          message: 'Unread Operator Messages',
          action: this.openChatOverlay,
          class: 'new-messages',
        };
      }

      return {};
    },
    show() {
      return !this.overlayOpen && this.state.message;
    },
    clickable() {
      if (this.state.action) {
        return 'clickable';
      }
    },
  },
  watch: {
    offline: {
      immediate: true,
      handler(isOffline) {
        if (!isOffline) {
          this.connectedOnce = true;
        }
      },
    },
  },
  methods: {
    sendEvent(event, payload) {
      this.$eventBus.$emit(event, payload);
    },
    enact() {
      if (!this.state.action) {
        return;
      }
      this.state.action();
    },
    openChatOverlay() {
      const options = {
        scroll: 'bottom',
        assetId: 'all',
      };
      this.sendEvent('chat-open', options);
    },
    refreshPage() {
      location.reload();
    },
  },
};
</script>

<style>
.notification-bar {
  cursor: pointer;
  position: fixed;
  top: 0;
  right: 0;
  left: 0;
  margin: 0 4rem;
  padding: 0 0.5rem;
  height: 2rem;
  background-color: orange;
  border: 2px solid orangered;
  border-radius: 10px;
  text-align: center;
  line-height: 1.75rem;
  font-family: 'GE Inspira Sans', sans-serif;
  user-select: none;
  font-weight: 600;
}

.notification-bar.new-messages {
  background-color: orange;
  border-color: orangered;
}

.notification-bar.offline {
  background-color: white;
  border-color: dimgray;
}

.blink {
  animation: blinker 3s linear infinite;
}

@keyframes blinker {
  from {
    opacity: 0.6;
  }
  50% {
    opacity: 0.9;
  }
  to {
    opacity: 0.6;
  }
}
</style>