<template>
  <ScrollView class="store-viewer-modal">
    <StackLayout v-if="raw" class="content">
      <Label class="value" :text="stringify(state)" :textWrap="true" />
    </StackLayout>
    <StackLayout v-else class="content">
      <StackLayout class="row" v-for="[key, value] in entries" :key="key" @tap="toggle(key)">
        <Label class="key" :text="key" :textWrap="true" />
        <Label class="value" :text="stringify(value)" :textWrap="true" />
      </StackLayout>
    </StackLayout>
  </ScrollView>
</template>

<script>
function createKeys(state, ignore = [], mask = []) {
  const keySettings = {};
  Object.keys(state).forEach(key => {
    keySettings[key] = !Array.isArray(state[key]);
  });

  // ignore
  ignore.forEach(key => {
    delete keySettings[key];
  });

  // mask (only say if set or not set)
  mask.forEach(key => {
    keySettings[key] = null;
  });

  return keySettings;
}

function processStateValue(state, key, mode) {
  const value = state[key];
  if (mode === true) {
    return [key, value];
  }

  if (mode === false) {
    const length = Array.isArray(value) ? ` (${value.length})` : '';
    return [key, `hidden${length}. Click to show`];
  }

  const mask = value ? '-- set --' : '-- not set --';
  return [key, mask];
}

export default {
  name: 'StoreViewerModal',
  props: {
    name: { type: String, default: null },
    raw: { type: Boolean, default: false },
    ignore: { type: Array, default: () => [] },
    mask: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      keySettings: {},
    };
  },
  computed: {
    state() {
      let state = this.$store.state;
      if (this.name) {
        state = state[this.name];
      }

      return state || {};
    },
    entries() {
      const settings = this.keySettings;
      const state = { ...(this.state || {}) };

      return Object.entries(settings).map(([key, mode]) => {
        return processStateValue(state, key, mode);
      });
    },
  },
  watch: {
    state: {
      immediate: true,
      handler(state) {
        this.updateKeySettings(state);
      },
    },
  },
  methods: {
    updateKeySettings(state) {
      const newKeys = createKeys(state, this.ignore, this.mask);
      this.keySettings = { ...newKeys, ...this.keySettings };
    },
    stringify(data) {
      if (typeof data === 'string') {
        return data;
      }
      return JSON.stringify(data, null, 2);
    },
    toggle(key) {
      const status = this.keySettings[key];

      if (status === undefined || status === null) {
        return;
      }

      this.keySettings = { ...this.keySettings, [key]: !status };
    },
  },
};
</script>

<style>
.store-viewer-modal {
  background-color: white;
  width: 85%;
  height: 80%;
}

.store-viewer-modal .content {
  padding: 25 50;
}

.store-viewer-modal .row {
  border-bottom-width: 1;
  border-bottom-color: black;
}

.store-viewer-modal .key {
  width: 100%;
  font-weight: 600;
  font-size: 20;
  background-color: rgb(192, 192, 192);
}

.store-viewer-modal .value {
  padding-bottom: 20;
  font-size: 16;
}
</style>