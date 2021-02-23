<template>
  <ScrollView class="info-modal">
    <StackLayout class="info-modal-content">
      <Label class="info-key" text="Device" />
      <Label class="info-value" :text="deviceInfo" />

      <Label class="info-key" text="Device Id" />
      <Label class="info-value" :text="formattedDeviceUUID" />

      <Label class="info-key" text="Serial Number" />
      <Label class="info-value" :text="serial" />

      <Label class="info-key" text="Client Info" />
      <Label class="info-value" :text="clientVersion" :textWrap="true" />

      <Label class="info-key" text="Host" />
      <Label class="info-value" :text="host" />

      <Label class="info-key" text="OS" />
      <Label class="info-value" :text="operatingSystem" />

      <Button
        class="info-btn btn-clear-cache"
        text="Clear Offline Data"
        textTransform="lowercase"
        @tap="onClearOfflineData"
      />

      <Button
        class="info-btn btn-clear-cache"
        text="Clear Cache"
        textTransform="lowercase"
        @tap="clearCache"
      />

      <Button
        class="info-btn btn-authorize"
        text="Authorize Device"
        textTransform="lowercase"
        @tap="onAuthorizeDevice"
      />

      <Label
        v-if="authError"
        class="auth-error"
        horizontalAlignment="center"
        :textWrap="true"
        :text="`Error - ${authError}`"
      />
    </StackLayout>
  </ScrollView>
</template>

<script>
import axios from 'axios';
const AuthChannel = require('../../code/auth_channel.js');
const platformModule = require('tns-core-modules/platform');
import ConfirmModal from './ConfirmModal.vue';
import { AndroidInterface } from './androidInterface';
import { formatDate, formatDeviceUUID } from '../../code/helper';

function tryExecute(callback, defVal = null) {
  try {
    return callback();
  } catch {
    return defVal;
  }
}

function getDeviceDetails(androidInterface) {
  const device = platformModule.device;

  return {
    serial: tryExecute(() => androidInterface.getSerialNumber()),
    model: tryExecute(() => device.model),
    manufacturer: tryExecute(() => device.manufacturer),
  };
}

export default {
  name: 'InfoModal',
  data: () => {
    return {
      androidInterface: new AndroidInterface(),
      authChannel: null,
      authError: '',
    };
  },
  computed: {
    device() {
      return platformModule.device;
    },
    deviceInfo() {
      const model = this.device.model;
      const manufacturer = this.device.manufacturer;
      return `${manufacturer} (${model})`;
    },
    deviceUUID() {
      return this.device.uuid;
    },
    formattedDeviceUUID() {
      return formatDeviceUUID(this.deviceUUID.toUpperCase());
    },
    clientVersion() {
      const client = this.$store.state.disk.client;
      const version = client.version || 'No Version Given';
      if (!client.changedAt) {
        return version;
      }

      const changedAt = formatDate(client.changedAt, '%Y-%m-%d %HH:%MM:%SS');

      return `Version  : ${version}\nUpdated: ${changedAt}`;
    },
    operatingSystem() {
      const os = this.device.os;
      const version = this.device.osVersion;
      const sdk = this.device.sdkVersion;
      return `${os} (${version}) [${sdk}]`;
    },
    serial() {
      return this.androidInterface.getSerialNumber();
    },
    host() {
      return this.$hostname;
    },
  },
  beforeDestroy() {
    AuthChannel.destroy(this.authChannel);
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    clearCache() {
      this.$store.commit('disk/clear');
    },
    onClearOfflineData() {
      const confirmName = 'Clear';
      const opts = {
        message: 'Offline mode will be unavailable until next successful connection',
        confirmName,
        rejectName: 'cancel',
      };
      this.$modalBus.open(ConfirmModal, opts).onClose(answer => {
        if (answer === confirmName) {
          this.$store.dispatch('clearAllDiskData');
          this.$toaster.info('Offline Data Cleared').show();
        }
      });
    },
    setAuthError(msg) {
      this.authError = msg;
      console.error(msg);
    },
    clearAuthError() {
      this.authError = '';
    },
    initChannel(token) {
      if (!token) {
        console.error('[Auth] invalid token received');
        return;
      }

      const channel = AuthChannel.create(this.deviceUUID, token, this.$hostname);

      channel.on('set device token', ({ token }) => {
        this.$store.commit('disk/saveDeviceToken', token);
        this.$toaster.green('Device Authorized').show();
        this.close('authorized');
      });

      this.authChannel = channel;
    },
    onAuthorizeDevice() {
      this.clearAuthError();
      const data = {
        device_uuid: this.deviceUUID,
        details: getDeviceDetails(this.androidInterface),
      };

      const hostname = this.$hostname;
      axios
        .post(`${hostname}/auth/request_device_auth`, data)
        .then(resp => {
          const token = resp.data;
          this.initChannel(token);
        })
        .catch(error => {
          this.setAuthError('Dispatcher not accepting new devices');
        });
    },
  },
};
</script>

<style>
.info-modal {
  background-color: white;
  height: 90%;
  width: 500;
}

.info-modal-content {
  padding: 25 50;
}

.info-modal .info-key {
  font-weight: 500;
  font-size: 25;
}

.info-modal .info-value {
  font-size: 20;
  padding-bottom: 25;
}

.info-modal .auth-error {
  font-size: 20;
  color: red;
}

.info-modal .info-btn {
  height: 50;
  font-size: 20;
}
</style>
