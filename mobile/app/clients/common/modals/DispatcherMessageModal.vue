<template>
  <StackLayout
    class="dispatcher-message-modal"
    :class="{ 'message-only': !hasAnswers }"
    @tap="onBodyClick"
  >
    <Label class="age" :text="age" verticalAlignment="center" />
    <Label class="message" :text="message" :textWrap="true" verticalAlignment="center" />
    <FlexBoxLayout v-if="hasAnswers" alignItems="flex-end">
      <Button
        :width="answerButtonWidth"
        class="button"
        v-for="(answer, index) in answers"
        :key="index"
        :text="answer"
        @tap="close(answer)"
      />
    </FlexBoxLayout>
  </StackLayout>
</template>

<script>
import { disableModalCloseOutside } from './androidInterface';
import { toPlural } from '../../code/helper';
const MAX_HOURS = 12;

function divmod(y, x) {
  if (x === 0) {
    return [0, y];
  }

  const quotient = Math.floor(y / x);
  const remainder = y % x;
  return [quotient, remainder];
}

function toRelativeAgo(totalSeconds) {
  const s = Math.round(Math.abs(totalSeconds));

  const [hours, minSeconds] = divmod(s, 3600);
  const [minutes, seconds] = divmod(minSeconds, 60);

  return {
    hours,
    minutes,
    seconds,
  };
}

export default {
  name: 'DispatcherMessageModal',
  props: {
    message: { type: String, default: '' },
    timestamp: { type: Date, default: null },
    answers: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      interval: null,
      now: Date.now(),
    };
  },
  computed: {
    hasAnswers() {
      return this.answers.length !== 0;
    },
    answerButtonWidth() {
      return `${(100 / this.answers.length + 1).toFixed(3)}%`;
    },
    age() {
      if (!this.timestamp) {
        return '';
      }

      const age = this.now - this.timestamp;
      const relative = toRelativeAgo(age / 1000);

      if (relative.hours > MAX_HOURS) {
        return `More than ${MAX_HOURS} hours ago`;
      }

      if (relative.hours) {
        return toPlural(relative.hours, 'hour', 's', ' ago');
      }

      if (relative.minutes) {
        return toPlural(relative.minutes, 'minute', 's', ' ago');
      }

      return toPlural(relative.seconds, 'second', 's', ' ago');
    },
  },
  mounted() {
    this.interval = setInterval(() => {
      this.now = Date.now();
    }, 1000);
  },
  beforeDestroy() {
    clearInterval(this.interval);
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onBodyClick() {
      if (!this.hasAnswers) {
        this.close();
      }
    },
  },
};
</script>

<style>
.dispatcher-message-modal {
  background-color: white;
  padding: 20 50;
  width: 600;
}

.dispatcher-message-modal.message-only {
  margin-top: 30;
  margin-bottom: 30;
}

.dispatcher-message-modal .message {
  font-size: 38;
  word-break: break-all;
  margin-bottom: 15;
}

.dispatcher-message-modal .button {
  font-size: 25;
  height: 70;
}
</style>