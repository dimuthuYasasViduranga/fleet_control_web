<template>
  <div class="dnd-settings-modal">
    <div class="orientation">
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
          <DropDown
            v-model="localSettings.horizontal.orderBy"
            :items="orderByOptions"
            :useScrollLock="false"
          />
        </td>
      </tr>
    </table>
    <table v-else>
      <tr>
        <th>Order by</th>
        <td>
          <DropDown
            v-model="localSettings.vertical.orderBy"
            :items="orderByOptions"
            :useScrollLock="false"
          />
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
    <button class="hx-btn close" @click="onSubmit()">Close</button>
  </div>
</template>

<script>
import DropDown from '@/components/dropdown/DropDown.vue';

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
        vertical: {},
        horizontal: {},
      },
      orderByOptions: [
        { id: 'dig-unit', name: 'Dig Unit' },
        { id: 'location', name: 'Location' },
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

/* orientation selection */
.dnd-settings-modal-wrapper .orientation {
  display: flex;
  width: 100%;
}

.dnd-settings-modal-wrapper .orientation .hx-btn {
  width: 100%;
  border: 1px solid grey;
}

.dnd-settings-modal-wrapper .orientation .hx-btn.highlight {
  border-color: white;
}

/* table */
.dnd-settings-modal-wrapper table {
  margin-top: 1rem;
  table-layout: fixed;
  width: 100%;
  font-size: 1.5rem;
}

.dnd-settings-modal-wrapper .dropdown-wrapper {
  width: 100%;
}

.dnd-settings-modal-wrapper .typeable {
  width: 100%;
}

.dnd-settings-modal-wrapper .close {
  margin-top: 2rem;
  width: 100%;
}
</style>