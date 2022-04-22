<template>
  <div class="dnd-settings-modal">
    <div class="heading">Asset Ordering</div>
    <div class="radio">
      <button
        class="hx-btn"
        :class="{ highlight: localSettings.assetOrdering === 'normal' }"
        @click="setAssetOrdering('normal')"
      >
        Alphabetically
      </button>
      <button
        class="hx-btn"
        :class="{ highlight: localSettings.assetOrdering === 'status' }"
        @click="setAssetOrdering('status')"
      >
        Status
      </button>
    </div>
    <div class="separator"></div>
    <div class="heading">Route Settings</div>
    <div class="radio">
      <button
        class="hx-btn"
        :class="{ highlight: localSettings.orientation === 'horizontal' }"
        @click="setOrientation('horizontal')"
      >
        Horizontal
      </button>
      <button
        class="hx-btn"
        :class="{ highlight: localSettings.orientation === 'vertical' }"
        @click="setOrientation('vertical')"
      >
        Vertical
      </button>
    </div>
    <table v-if="localSettings.orientation === 'horizontal'">
      <tr>
        <th>Order by</th>
        <td>
          <DropDown v-model="localSettings.horizontal.orderBy" :options="orderByOptions" />
        </td>
      </tr>
    </table>
    <table v-else>
      <tr>
        <th>Order by</th>
        <td>
          <DropDown v-model="localSettings.vertical.orderBy" :options="orderByOptions" />
        </td>
      </tr>
      <tr>
        <th>Columns</th>
        <td>
          <input
            class="typeable"
            type="number"
            :value="localSettings.vertical.columns"
            @change="onColumnsChange"
          />
        </td>
      </tr>
    </table>
    <div class="separator"></div>

    <button class="hx-btn close" @click="onSubmit()">Apply</button>
  </div>
</template>

<script>
import { DropDown } from 'hx-vue';

const MAX_COLUMNS = 10;
const MIN_COLUMNS = 2;

export default {
  name: 'DndSettingsModal',
  wrapperClass: 'dnd-settings-modal-wrapper',
  components: {
    DropDown,
  },
  props: {
    settings: { type: Object, default: () => ({}) },
  },
  data: () => {
    return {
      localSettings: {
        assetOrdering: 'normal',
        vertical: {},
        horizontal: {},
      },
      orderByOptions: [
        { id: 'dig-unit', label: 'Dig Unit' },
        { id: 'location', label: 'Location' },
      ],
    };
  },
  mounted() {
    this.localSettings = JSON.parse(JSON.stringify(this.settings));
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    setOrientation(mode) {
      this.localSettings.orientation = mode;
    },
    setAssetOrdering(mode) {
      this.localSettings.assetOrdering = mode;
    },
    onSubmit() {
      const settings = JSON.parse(JSON.stringify(this.localSettings));
      this.close(settings);
    },
    onColumnsChange(event) {
      let value = parseInt(event.target.value, 10);
      if (isNaN(value)) {
        this.localSettings.vertical.columns = MIN_COLUMNS;
        return;
      }

      if (value > MAX_COLUMNS) {
        value = MAX_COLUMNS;
      }

      if (value < MIN_COLUMNS) {
        value = MIN_COLUMNS;
      }

      this.localSettings.vertical.columns = value;
    },
  },
};
</script>

<style>
.dnd-settings-modal-wrapper .modal-container {
  width: 32rem;
}

.dnd-settings-modal-wrapper .separator {
  height: 1rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #677e8c;
}

.dnd-settings-modal-wrapper .heading {
  font-size: 1.5rem;
  text-align: center;
  line-height: 3rem;
}

/* radio button selection */
.dnd-settings-modal-wrapper .radio {
  display: flex;
  width: 100%;
}

.dnd-settings-modal-wrapper .radio .hx-btn {
  width: 100%;
  border: 1px solid grey;
}

.dnd-settings-modal-wrapper .radio .hx-btn.highlight {
  border-color: white;
}

/* table */
.dnd-settings-modal-wrapper table {
  margin-top: 1rem;
  table-layout: fixed;
  width: 100%;
  font-size: 1.5rem;
}

.dnd-settings-modal-wrapper .drop-down {
  width: 100%;
}

.dnd-settings-modal-wrapper .drop-down .v-select {
  height: 2.5rem;
}

.dnd-settings-modal-wrapper .typeable {
  width: 100%;
}

.dnd-settings-modal-wrapper .close {
  width: 100%;
}
</style>