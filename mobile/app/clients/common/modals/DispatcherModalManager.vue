<template>
  <StackLayout></StackLayout>
</template>

<script>
import DispatcherMessageModal from './DispatcherMessageModal.vue';

const OLD_MSG_INTERVAL = 20 * 1000;

export default {
  name: 'DispatcherModalManager',
  components: {
    DispatcherMessageModal,
  },
  data: () => {
    return {
      displayedMessage: null,
      seenIds: [],
      alertInterval: null,
    };
  },
  computed: {
    storedAcknowledgementIds() {
      const storedIds = this.$store.state.disk.dispatcherMsgAcks.map(m => m.id);

      // return these from disk, and the ones seen locally
      return [].concat(this.seenIds).concat(storedIds);
    },
    unreadDispatcherMessages() {
      const storedAckIds = this.storedAcknowledgementIds;
      return this.$store.state.dispatcherMessages.filter(
        m => !m.acknowledged && !storedAckIds.includes(m.id),
      );
    },
  },
  watch: {
    unreadDispatcherMessages(msgs) {
      this.showNext();
    },
  },
  beforeDestroy() {
    this.clearAlertInterval();
  },
  methods: {
    clearAlertInterval() {
      clearInterval(this.alertInterval);
    },
    setAlertInterval() {
      this.clearAlertInterval();
      this.$avPlayer.playNotification();
      this.alertInterval = setInterval(() => {
        this.$avPlayer.playNotification();
      }, OLD_MSG_INTERVAL);
    },
    showNext() {
      if (this.displayedMessage) {
        console.log('[DispatcherModalManager] Message already being displayed');
        return;
      }

      const msgs = this.unreadDispatcherMessages;

      if (msgs.length === 0) {
        console.log('[DispatcherModalManager] No more messages to show');
        return;
      }

      const msg = msgs[0];
      this.setDisplayedMessage(msg);

      const opts = {
        message: msg.message,
        timestamp: msg.timestamp,
        answers: msg.answers,
      };

      this.$modalBus
        .open(DispatcherMessageModal, opts, { disableOuterClose: opts.answers.length > 0 })
        .onClose(answer => {
          this.acknowledgeMsg(msg, answer);
          this.clearDisplayedMessage();
          this.showNext();
        })
        .onTerminate(() => {
          this.clearDisplayedMessage();
        });
    },
    clearDisplayedMessage() {
      this.displayedMessage = null;
      this.clearAlertInterval();
    },
    setDisplayedMessage(msg) {
      this.displayedMessage = msg;
      this.setAlertInterval();
    },
    acknowledgeMsg(msg, answer) {
      this.seenIds.push(msg.id);
      const acknowledgement = {
        messageId: msg.id,
        answer,
        timestamp: Date.now(),
      };
      this.$store.dispatch('submitDispatcherMessageAck', {
        acknowledgement,
        channel: this.$channel,
      });
    },
  },
};
</script>