<template>
  <StackLayout class="connect-modal">
    <Label class="title" :text="loginText" min-width="300" />
    <Label class="title" :text="maxLoginText" height="0" />
    <Label v-if="subTitle" class="sub-title" :text="subTitle" :textWrap="true" />
    <Label class="sub-title" :text="attemptText" :textWrap="true" />
    <Button class="button" :text="cancelText" @tap="onCancel" />
  </StackLayout>
</template>

<script>
import axios from 'axios';
const platformModule = require('tns-core-modules/platform');

const MAX_DOTS = 3;
const DOT_PERIOD = 1;
const MAX_CONNECT_PERIOD = 10;

function axiosPost(url, data, timeout = 4) {
  const source = axios.CancelToken.source();

  // create a timeout
  const cancelTimer = setTimeout(() => {
    source.cancel(`Timeout of ${timeout}s`);
  }, timeout * 1000);

  const config = {
    cancelToken: source.token,
  };

  return axios
    .post(url, data, config)
    .then(response => {
      clearTimeout(cancelTimer);
      return new Promise(resolve => resolve(response));
    })
    .catch(error => {
      if (axios.isCancel(error)) {
        return new Promise(resolve => resolve({ error: 'Connection timeout' }));
      }
      return new Promise((_resolve, reject) => reject(error));
    });
}

function getStatusError(response) {
  switch (response.status) {
    case 401:
      return { error: '401 - Invalid Employee Id' };

    case 403:
      const reason = (response.data || {}).error || 'Device Unauthorized';
      return { error: `403 - ${reason}` };

    default:
      return {
        error: `${response.status} - ${response.statusText}`,
      };
  }
}

export default {
  name: 'ConnectModal',
  props: {
    employeeId: String,
    heading: { type: String, default: 'Logging In' },
    subTitle: { type: String, default: '' },
    cancelText: { type: String, default: 'Cancel' },
    maxAttempts: { type: Number, default: 5 },
  },
  data: () => {
    return {
      nDots: 0,
      attempts: 0,
    };
  },
  computed: {
    loginText() {
      return `${this.heading} ${'.'.repeat(this.nDots)}`;
    },
    maxLoginText() {
      return `${this.heading} ${'.'.repeat(MAX_DOTS)}`;
    },
    attemptText() {
      if (this.maxAttempts === Infinity || this.maxAttempts === 0) {
        return `Attempt ${this.attempts}`;
      }
      return `Attempt ${this.attempts}/${this.maxAttempts}`;
    },
    deviceUUID() {
      return platformModule.device.uuid;
    },
    deviceToken() {
      return this.$store.state.disk.deviceToken;
    },
  },
  mounted() {
    setInterval(() => {
      if (this.nDots >= MAX_DOTS) {
        this.nDots = 0;
      } else {
        this.nDots += 1;
      }
    }, DOT_PERIOD * 1000);
    this.attempLogin();
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onCancel() {
      this.close();
    },
    attempLogin() {
      const loginData = {
        device_uuid: this.deviceUUID,
        device_token: this.deviceToken,
        employee_id: this.employeeId,
      };

      const hostname = this.$hostname;

      this.attempts += 1;
      axiosPost(`${hostname}/auth/operator_login`, loginData, MAX_CONNECT_PERIOD)
        .then(resp => {
          this.loginCallback(resp);
        })
        .catch(error => {
          this.processError(error);
        });
    },
    loginCallback({ data }) {
      // check how many times this has happened
      if (this.attempts >= this.maxAttempts) {
        this.close({ error: 'max attempts reached' });
        return;
      }

      if (!data) {
        setTimeout(() => {
          console.error('[ConnectModal] no outgoing coms');
          this.attempLogin();
        }, MAX_CONNECT_PERIOD * 1000);
        return;
      }

      if (data.token) {
        this.close({ token: data.token });
        return;
      }

      console.error('[ConnectModal] could not connect');
      this.attempLogin();
    },
    processError({ response }) {
      this.close({
        code: response.status,
        error: getStatusError(response),
      });
    },
  },
};
</script>

<style>
.connect-modal {
  background-color: white;
  width: 550;
  padding: 25 50;
}

.connect-modal .title {
  font-size: 50;
}

.connect-modal .sub-title {
  font-size: 30;
  text-align: center;
}

.connect-modal .button {
  font-size: 25;
  height: 60;
  text-align: center;
}

.connect-modal .spinner {
  height: 100;
  width: 100;
  background-color: none;
  clip-path: none;

  animation-name: spinner-rotate;
  animation-duration: 1s;
  animation-iteration-count: 30;
  animation-timing-function: linear;
}

@keyframes spinner-rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.connect-modal .inner-segment {
  height: 50;
  width: 50;
  background-color: blue;
  clip-path: none;
}

.connect-modal .inner-circle {
  height: 50;
  width: 50;
  background-color: red;
  border-radius: 50%;
  top: 25;
  left: 25;
}
</style>