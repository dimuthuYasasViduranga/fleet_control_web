<template>
  <div class="dispatcher-message" :class="acknowledgementClass">
    <div class="chat-line-right">
      <div class="box">
        <div class="box-wrapper">
          <div class="title">{{ dispatcherName }} {{ '\u2b95' }} {{ entry.assetName }}</div>
          <div class="message">{{ entry.text }}</div>
          <div class="answers" v-if="answers.length !== 0">
            [
            <span class="answer" v-for="(answer, index) in answers" :key="index">
              <span class="text" :class="getAnswerClass(answer)">{{ answer }}</span>
              <span
                v-if="index !== answers.length - 1"
                class="separator"
                :class="{ unselected: answerGiven }"
              >
                |
              </span>
            </span>
            ]
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DispatchMessage',
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    dispatcherName() {
      return this.entry.dispatcher || 'Dispatcher';
    },
    acknowledgementClass() {
      if (this.entry.acknowledged) {
        return '';
      }
      return 'unacknowledged';
    },
    answers() {
      return this.entry.answers || [];
    },
    answerGiven() {
      return this.answers.includes(this.entry.answer);
    },
  },
  methods: {
    getAnswerClass(answer) {
      if (!this.answerGiven || this.entry.answer === answer) {
        return '';
      }
      return 'unselected';
    },
  },
};
</script>

<style>
.dispatcher-message {
  text-align: right;
  margin-left: 10%;
}

.dispatcher-message .title {
  text-decoration: underline;
  padding-bottom: 0.25rem;
}

.dispatcher-message .answers {
  padding-top: 0.5rem;
}

.dispatcher-message .answers .answer .separator {
  margin: 0 0.25rem;
}

.dispatcher-message .answers .answer .unselected {
  opacity: 0.25;
}

.dispatcher-message.unacknowledged .box {
  border-color: orange;
}

.dispatcher-message .chat-line-right {
  height: 100%;
  width: 100%;
  padding: 10px;
  padding-right: 30px;
}

.dispatcher-message .box-wrapper {
  padding: 5px;
}

.dispatcher-message .box {
  height: 100%;
  width: 100%;
  position: relative;
  border: 2px solid #084444;
  background-color: #084444;
  border-radius: 10px;
  border-top-right-radius: 0;
}

/* outter segment */
.dispatcher-message .box:before {
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
  transform: translate(-50%, -50%) rotate(-45deg);
}

/* inner border */
.dispatcher-message .box:after {
  content: '';
  position: absolute;
  width: 0;
  height: 0;
  top: 0;
  border: 16px solid;
  border-top-color: transparent;
  border-right-color: transparent;
  border-bottom-color: #084444;
  border-left-color: transparent;
  transform: translate(-55%, -50%) rotate(-45deg);
}
</style>