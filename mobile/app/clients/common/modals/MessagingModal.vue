<template>
  <GridLayout class="messaging-modal">
    <ItemList :items="messages" @select="onSelect" />
  </GridLayout>
</template>

<script>
import { mapState } from 'vuex';
import ItemList from '../ItemList.vue';
import { attributeFromList } from '../../code/helper';

function occurances(arr, key, val) {
  return arr.reduce((acc, elem) => {
    return elem[key] === val ? acc + 1 : acc;
  }, 0);
}

export default {
  name: 'MessagingModal',
  components: {
    ItemList,
  },
  props: {
    deviceId: { type: Number, default: null },
    asset: { type: Object, default: null },
    operator: { type: Object, default: null },
  },
  computed: {
    ...mapState('constants', {
      messageTypes: state => state.operatorMessageTypes,
      messageTree: state => state.operatorMessageTypeTree,
    }),
    unreadMessages() {
      return this.$store.state.unreadOperatorMessages;
    },
    messages() {
      const messageTypes = this.messageTypes;
      const assetTypeId = (this.asset || {}).typeId;
      return this.messageTree
        .filter(t => t.assetTypeId === assetTypeId)
        .map(t => {
          const messageType = attributeFromList(messageTypes, 'id', t.messageTypeId) || {};
          const nUnread = occurances(this.unreadMessages, 'typeId', messageType.id);
          return {
            id: messageType.id,
            name: messageType.name,
            highlight: nUnread > 0,
            count: nUnread,
          };
        });
    },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onSelect(item) {
      this.submitMessage(item);
      this.close(item);
    },
    submitMessage(item) {
      const timestamp = Math.round(Date.now());
      const message = {
        deviceId: this.deviceId,
        assetId: (this.asset || {}).id,
        operatorId: (this.operator || {}).id,
        typeId: item.id,
        timestamp,
      };

      this.$store.dispatch('submitMessage', { message, channel: this.$channel });
    },
  },
};
</script>

<style>
.messaging-modal {
  width: 75%;
  height: 90%;
  background-color: #1c323d;
  padding: 20;
  border-width: 1;
  border-color: #d6d7d7;
}
</style>