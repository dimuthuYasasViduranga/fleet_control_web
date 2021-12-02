<template>
  <div class="operator-message" :class="acknowledgementClass" @click="onAcknowledge">
    <div class="chat-line-left">
      <div class="box">
        <div class="box-wrapper">
          <div class="title">
            {{ entry.assetName }} - {{ entry.operatorFullname || 'No Operator' }}
          </div>
          <div class="message">{{ entry.text }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'OperatorMessage',
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    acknowledgementClass() {
      if (this.entry.acknowledged === true) {
        return '';
      }
      return 'unacknowledged';
    },
  },
  methods: {
    onAcknowledge() {
      if (this.entry.acknowledged === false && this.entry.messageId) {
        this.$channel.push('acknowledge operator message', this.entry.messageId);
      }
    },
  },
};
</script>

<style>
.operator-message {
  position: relative;
  width: 90%;
}

.operator-message .title {
  text-decoration: underline;
  padding-bottom: 0.25rem;
}

.operator-message.unacknowledged .box {
  border-color: orange;
  cursor: pointer;
  user-select: none;
}

.chat-line-left {
  height: 100%;
  width: 100%;
  padding: 10px;
  padding-left: 30px;
}

.chat-line-left .box-wrapper {
  padding: 5px;
}

.chat-line-left .box {
  height: 100%;
  width: 100%;
  position: relative;
  border: 2px solid #344955;
  background-color: #344955;
  border-radius: 10px;
  border-top-left-radius: 0;
}

/* outter segment */
.chat-line-left .box:before {
  content: '';
  position: absolute;
  width: 0;
  height: 0;
  top: -2px; /* (border_diff / 2) */
  border: 20px solid;
  border-top-color: transparent;
  border-right-color: transparent;
  border-bottom-color: inherit;
  border-left-color: transparent;
  transform: translate(-50%, -50%) rotate(45deg);
}

/* inner border */
.chat-line-left .box:after {
  content: '';
  position: absolute;
  width: 0;
  height: 0;
  top: 0;
  border: 16px solid;
  border-top-color: transparent;
  border-right-color: transparent;
  border-bottom-color: #344955;
  border-left-color: transparent;
  transform: translate(-45%, -50%) rotate(45deg);
}
</style>