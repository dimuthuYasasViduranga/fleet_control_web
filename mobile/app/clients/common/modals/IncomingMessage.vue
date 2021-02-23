<template>
  <ScrollView class="incoming-message-modal" orientation="vertical">
    <StackLayout class="incoming-message-content" @tap="onClick">
      <Label class="age" :text="`${prefix} ${age} ago ${suffix}`" verticalAlignment="center" />
      <Label class="message" :text="message" :textWrap="true" verticalAlignment="center" />
    </StackLayout>
  </ScrollView>
</template>

<script>
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
  name: 'IncomingMessage',
  props: {
    prefix: { type: String, default: '' },
    suffix: { type: String, default: '' },
    message: { type: String, default: '' },
    timestamp: { type: Date, default: null },
    closeOnMessage: { type: Boolean, default: true },
  },
  data: () => {
    return {
      interval: null,
      now: Date.now(),
    };
  },
  computed: {
    age() {
      if (!this.timestamp) {
        return '';
      }

      const age = this.now - this.timestamp;
      const relative = toRelativeAgo(age / 1000);

      if (relative.hours > MAX_HOURS) {
        return `> ${MAX_HOURS} hours`;
      }

      if (relative.hours) {
        return toPlural(relative.hours, 'hour', 's');
      }

      if (relative.minutes) {
        return toPlural(relative.minutes, 'minute', 's');
      }

      return toPlural(relative.seconds, 'second', 's');
    },
  },
  mounted() {
    this.interval = setInterval(() => {
      this.now = Date.now();
    }, 1000);
    this.$modalBus.onTerminate(this.close);
  },
  beforeDestroy() {
    clearInterval(this.interval);
  },
  methods: {
    close(resp) {
      this.$modal.close(resp);
    },
    onClick() {
      if (this.closeOnMessage) {
        this.close();
      }
    },
  },
};
</script>

<style>
.incoming-message-modal {
  background-color: white;
  width: 70%;
}

.incoming-message-content {
  padding: 20;
  margin-top: 60;
  margin-bottom: 60;
  width: 700;
}

.incoming-message-modal .title {
  font-weight: 500;
  font-size: 38;
  padding-bottom: 10;
}

.incoming-message-modal .message {
  font-size: 38;
  word-break: break-all;
}
</style>