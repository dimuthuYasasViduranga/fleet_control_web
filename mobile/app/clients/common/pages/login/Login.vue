<template>
  <Page class="page login-page" androidStatusBarBackground="#0c1419">
    <ActionBar class="action-bar" height="75">
      <GridLayout width="100%" columns="*, *">
        <StackLayout orientation="horizontal" row="0" col="0">
          <Image
            v-if="site"
            class="icon logo"
            stretch="aspectFit"
            horizontalAlignment="left"
            :src="`~/assets/images/logos/${site}.png`"
          />

          <CenteredLabel
            id="title_label"
            class="heading"
            text="FleetControl"
            @longPress="openDebug"
          />
        </StackLayout>

        <StackLayout row="0" col="1" orientation="horizontal" horizontalAlignment="right">
          <CenteredLabel
            height="100%"
            class="client-version"
            :text="clientVersion || 'dev'"
            horizontalAlignment="right"
          />
          <BatteryIcon height="60" width="60" />
          <NetworkIcon height="60" width="60" />
          <Image
            class="icon settings"
            src="~/assets/images/cog.png"
            stretch="aspectFit"
            horizontalAlignment="right"
            @tap="showInfo"
          />
        </StackLayout>
      </GridLayout>
    </ActionBar>

    <GridLayout width="100%" columns="* 7*" rows="* *2 * *2">
      <CenteredLabel
        id="error"
        class="text-danger"
        :text="localError || error"
        row="0"
        colSpan="2"
        horizontalAlignment="center"
      />

      <Label id="id_label" class="label" text="ID" row="1" col="0" />
      <TextField
        class="text-field employee-id"
        keyboardType="number"
        row="1"
        col="1"
        hint="Employee ID"
        :text="employeeId"
        @textChange="onTextChange"
      />

      <Image
        v-if="hasPreStarts"
        row="3"
        col="0"
        class="pre-start-icon"
        src="~/assets/images/clipboard.png"
        stretch="aspectFit"
        tintColor="black"
        @tap="onOpenOfflinePreStart()"
      />

      <Button
        class="button login-button"
        textTransform="capitalize"
        row="3"
        :col="hasPreStarts ? 1 : 0"
        colSpan="2"
        text="Login"
        @tap="onLogin"
      />
    </GridLayout>
  </Page>
</template>

<script>
import axios from 'axios';

import InfoModal from '../../modals/InfoModal.vue';
import DebugModal from '../../modals/DebugModal.vue';
import CenteredLabel from '../../CenteredLabel.vue';
import BatteryIcon from '../../BatteryIcon.vue';
import NetworkIcon from '../../NetworkIcon.vue';

const { LoginLooper } = require('./login.js');

const MIN_EMPLOYEE_ID_LEN = 1;

function chunkStr(str, size) {
  if (size <= 0) {
    return [str];
  }

  const arr = str.split('');
  const chunks = chunk(arr, size);
  return chunks.map(c => c.join(''));
}

function chunk(arr, size) {
  const maxLen = arr.length;
  const repeats = Math.ceil(maxLen / size);
  const ranges = [];
  for (let i = 0; i < repeats; i++) {
    const start = i * size;
    const end = start + size;
    ranges.push([start, end]);
  }

  const chunks = ranges.map(([start, end]) => arr.slice(start, end));
  return chunks;
}

function validNumber(val, minLength) {
  return val && val.length >= minLength;
}

export default {
  name: 'main',
  components: {
    CenteredLabel,
    BatteryIcon,
    NetworkIcon,
  },
  props: {
    deviceToken: { type: String, default: '' },
    employeeId: { type: String, default: '' },
    site: { type: String, default: 'Haultrax' },
    error: { type: String, default: '' },
  },
  data: () => {
    return {
      localError: '',
      loginRunning: false,
    };
  },
  computed: {
    clientVersion() {
      return this.$store.state.disk.client.version;
    },
    hasPreStarts() {
      return this.$store.state.constants.preStarts.length !== 0;
    },
  },
  mounted() {
    this.loginUntil = new LoginLooper(this.$hostname);
  },
  methods: {
    showInfo() {
      this.$modalBus.open(InfoModal).onClose(answer => {
        if (answer === 'authorized') {
          this.clearError();
        }
      });
    },
    openDebug() {
      this.$modalBus.open(DebugModal);
    },
    setError(msg) {
      console.error(msg);
      this.localError = msg;
    },
    clearError() {
      this.localError = '';
    },
    onTextChange(change) {
      if (change.value !== this.employeeId) {
        this.$emit('employeeIdChange', change.value);
      }
    },
    validateEmployeeId() {
      if (!validNumber(this.employeeId, MIN_EMPLOYEE_ID_LEN)) {
        this.setError('Please input a valid employee ID');
        return false;
      }

      if (!this.deviceToken) {
        this.setError('Device has not been authorized');
        return false;
      }

      return true;
    },
    onLogin() {
      this.clearError();

      if (this.validateEmployeeId()) {
        this.$emit('login');
      }
    },
    onOpenOfflinePreStart() {
      this.$emit('offlinePreStart');
    },
  },
};
</script>

<style>
#title_label {
  text-align: left;
}

.login-page .label {
  text-align: right;
  vertical-align: center;
  font-size: 55;
}

.login-page .client-version {
  text-align: right;
  font-size: 16;
}

.login-page .icon.logo {
  height: 40;
}

.login-page .icon.settings {
  padding: 0 50;
  height: 35;
  width: 60;
}

.login-page .icon.help {
  height: 30;
}

.login-page .action-bar .heading {
  font-size: 24;
}

.login-page .text-danger {
  color: red;
  font-size: 24;
}

.login-page .text-field {
  font-size: 24;
}

.login-page .login-button {
  font-size: 30;
}

.login-page .employee-id {
  font-size: 35;
}

.login-page .pre-start-icon {
  margin: 6 0;
  padding: 35;
  background-color: #d6d7d7;
  border-radius: 4;
}
</style>
