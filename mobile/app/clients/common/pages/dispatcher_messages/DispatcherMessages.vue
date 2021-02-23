<template>
  <StackLayout class="dispatcher-messages">
    <CenteredLabel v-if="messages.length === 0" class="no-messages" text="No Recent Messages" />
    <ListView ref="scrollable" class="message-list" for="item in messages">
      <v-template>
        <MessageRow
          :class="{ unacknowledged: !item.acknowledged }"
          :timestamp="item.timestamp"
          :text="getText(item)"
          @click="onClick(item)"
        />
      </v-template>
    </ListView>
  </StackLayout>
</template>

<script>
import { mapState } from 'vuex';
import MessageRow from './MessageRow.vue';
import CenteredLabel from '../../CenteredLabel.vue';

export default {
  name: 'DispatcherMessages',
  components: {
    MessageRow,
    CenteredLabel,
  },
  computed: {
    ...mapState({
      dispatcherMessages: state => state.dispatcherMessages,
      storedIds: state => state.disk.dispatcherMsgAcks.map(m => m.id),
      deviceId: state => state.deviceId,
    }),
    messages() {
      const storedIds = this.storedIds;
      return this.dispatcherMessages.map(m => {
        const alreadyAcked = storedIds.includes(m.id);
        return {
          ...m,
          acknowledged: m.acknowledged || alreadyAcked,
        };
      });
    },
  },
  mounted() {
    this.scrollToBottom();
  },
  methods: {
    getText(item) {
      if (item.answer) {
        return `${item.message} [${item.answer}]`;
      }
      return item.message;
    },
    getScrollable() {
      return (this.$refs['scrollable'] || {}).nativeView;
    },
    scrollToIndex(index = 0) {
      const scrollable = this.getScrollable();
      scrollable.scrollToIndex(index);
    },
    scrollToBottom() {
      this.scrollToIndex(this.dispatcherMessages.length - 1);
    },
    onClick(message) {
      if (message.acknowledged) {
        return;
      }

      const acknowledgement = {
        messageId: message.id,
        deviceId: this.deviceId,
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

<style>
.dispatcher-messages .message-row {
  border-width: 0.5 20;
  border-top-color: gray;
  border-bottom-color: gray;
  border-left-color: transparent;
  border-right-color: transparent;
}

.dispatcher-messages .message-row.unacknowledged {
  border-width: 0.5 20;
  border-top-color: orange;
  border-bottom-color: orange;
  border-left-color: orange;
  border-right-color: orange;
}

.dispatcher-messages .no-messages {
  height: 60;
  font-size: 30;
}
</style>