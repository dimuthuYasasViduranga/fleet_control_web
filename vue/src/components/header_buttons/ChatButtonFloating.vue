<template>
  <div class="chat-button-floating">
    <div class="outer-circle-wrapper" @click="open">
      <div class="outer-circle">
        <ChatButton :clickable="false" />
      </div>
    </div>
  </div>
</template>

<script>
import ChatButton from './ChatButton.vue';

export default {
  name: 'ChatButtonFloating',
  components: {
    ChatButton,
  },
  methods: {
    open() {
      const options = {
        scroll: 'bottom',
        assetId: 'all',
      };
      this.$eventBus.$emit('chat-open', options);
    },
  },
};
</script>

<style>
.chat-button-floating {
  position: fixed;
  height: 75px;
  width: 75px;
  bottom: 65px;
  right: 50px;
  z-index: 10;
}

.chat-button-floating .outer-circle-wrapper {
  height: 100%;
  width: 100%;
  cursor: pointer;
}

.chat-button-floating .outer-circle {
  padding-top: 0.1rem;
  display: flex;
  text-align: center;
  vertical-align: middle;

  border-radius: 50%;
  border: 1px solid #1b2a33;
  width: 100%;
  height: 100%;
  padding-right: 0.1rem;

  background-color: #0c1419;
  color: black;
  font-weight: bold;
}

</style>