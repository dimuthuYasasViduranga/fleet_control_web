<template>
  <div class="chat-button">
    <Icon :icon="icon" @click="open" />

    <div v-if="nUnreadMsgs > 0" class="indicator" @click="open">
      <Bubble>{{ nUnreadMsgs }}</Bubble>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import ChatIcon from './../icons/Chat.vue';
import Bubble from '../Bubble.vue';

export default {
  name: 'ChatButton',
  components: {
    Icon,
    Bubble,
  },
  props: {
    clickable: { type: Boolean, default: true },
  },
  data: () => {
    return {
      icon: ChatIcon,
    };
  },
  computed: {
    nUnreadMsgs() {
      return this.$store.getters.unreadOperatorMessages.length;
    },
  },
  methods: {
    open() {
      if (this.clickable) {
        const options = {
          scroll: 'bottom',
          assetId: 'all',
        };
        this.$eventBus.$emit('chat-open', options);
      }
    },
  },
};
</script>

<style>
.chat-button {
  margin: auto;
  position: relative;
  cursor: pointer;
}

.chat-button .icon-wrapper {
  height: 1.5rem;
  width: 1.5rem;
  margin: 0 0.75rem;
  padding-top: 0.1rem;
}

.chat-button .indicator {
  position: absolute;
  top: -12px;
  right: -2px;
  font-size: 14px;
}
</style>