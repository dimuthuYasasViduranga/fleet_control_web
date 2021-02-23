<template>
  <div class="object-editor">
    <table>
      <tr v-for="entry in entries" :key="entry.key">
        <td class="key">{{ entry.key }}</td>
        <td class="value">
          <input
            class="typeable"
            type="text"
            :value="entry.value"
            @input="onAdd(entry.key, $event.target.value)"
          />
        </td>
        <td>
          <button class="hx-btn" @click="onDelete(entry.key)">Remove</button>
        </td>
      </tr>
      <tr>
        <td class="key">
          <input class="key typeable" v-model="pendingKey" type="text" placeholder="Attribute" />
        </td>
        <td class="value">
          <input class="value typeable" v-model="pendingValue" type="text" placeholder="Value" />
        </td>
        <td>
          <button class="hx-btn" @click="onAdd(pendingKey, pendingValue)">
            Add
          </button>
        </td>
      </tr>
    </table>
  </div>
</template>

<script>
export default {
  name: 'ObjectEditor',
  props: {
    value: { type: Object },
  },
  data: () => {
    return {
      pendingKey: null,
      pendingValue: null,
    };
  },
  computed: {
    entries() {
      const list = Object.entries(this.value || {}).map(([key, value]) => ({ key, value }));
      list.sort((a, b) => a.key.localeCompare(b.key));
      return list;
    },
  },
  methods: {
    emitValue(value) {
      this.$emit('input', { ...value });
    },
    onAdd(key, value) {
      if (!key || !value) {
        console.error('[ObjectEditor] Must have valid key and value');
        return;
      }

      this.pendingKey = null;
      this.pendingValue = null;
      this.emitValue({ ...(this.value || {}), [key]: value });
    },
    onDelete(key) {
      const newValue = { ...(this.value || {}) };
      delete newValue[key];
      this.emitValue(newValue);
    },
  },
};
</script>

<style>
@import '../../../assets/hxInput.css';
.object-editor {
  width: 10rem;
}

.object-editor table {
  width: 100%;
}

.object-editor .hx-btn {
  width: 6rem;
}

.object-editor input {
  height: 2rem;
}

.object-editor .key {
  font-weight: bold;
  width: 10rem;
}
.object-editor .value {
  width: 10rem;
}

.object-editor .actions {
  margin-top: 1rem;
}
</style>