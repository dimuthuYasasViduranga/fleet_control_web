<template>
  <div class="category-editor-modal">
    <table>
      <tr>
        <td class="key">Name</td>
        <td class="value">
          <input
            v-tooltip="{
              trigger: 'manual',
              show: nameTaken,
              content: 'Name already exists',
            }"
            class="typeable"
            v-model="localCat.name"
            placeholder="Name"
            type="text"
            autocomplete="off"
          />
        </td>
      </tr>
      <tr>
        <td class="key">Action</td>
        <td class="value">
          <input
            class="typeable"
            v-model="localCat.action"
            placeholder="Action upon failure"
            type="text"
            autocomplete="off"
          />
        </td>
      </tr>
    </table>
    <div class="actions">
      <button class="hx-btn" :disabled="!localCat.name || nameTaken" @click="onUpdate()">
        Update
      </button>
      <button class="hx-btn" @click="reset()">Reset</button>
      <button class="hx-btn" @click="close()">Cancel</button>
    </div>
  </div>
</template>

<script>
function emptyCategory() {
  return {
    id: null,
    name: '',
    action: '',
  };
}

export default {
  name: 'CategoryEditorModal',
  wrapperClass: 'category-editor-modal-wrapper',
  props: {
    category: { type: Object, default: () => emptyCategory() },
    existingNames: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      localCat: emptyCategory(),
    };
  },
  computed: {
    nameTaken() {
      return this.existingNames.includes(this.localCat.name);
    },
  },
  mounted() {
    this.reset();
  },
  methods: {
    reset() {
      this.localCat = { ...emptyCategory(), ...this.category };
    },
    close(resp) {
      this.$emit('close', resp);
    },
    onUpdate() {
      if (!this.localCat.name) {
        this.$toaster.error('Category requires a name');
        return;
      }

      if (this.nameTaken) {
        this.$toaster.error('Name already exists');
        return;
      }

      this.close(this.localCat);
    },
  },
};
</script>

<style>
.category-editor-modal-wrapper .modal-container {
  max-width: 35rem;
}

.category-editor-modal table {
  width: 100%;
  border-collapse: collapse;
}

.category-editor-modal table tr {
  height: 3rem;
}

.category-editor-modal table .key {
  font-size: 2rem;
}

.category-editor-modal table .value {
  font-size: 1.5rem;
  text-align: center;
}

.category-editor-modal table .value input {
  width: 90%;
}

.category-editor-modal .actions {
  display: flex;
  padding-top: 1rem;
  justify-content: space-between;
}

.category-editor-modal .actions:first-child {
  margin-left: 0;
}

.category-editor-modal .actions:last-child {
  margin-right: 0;
}

.category-editor-modal .actions .hx-btn {
  width: 100%;
  margin: 0 0.1rem;
}

.category-editor-modal .hx-btn[disabled] {
  cursor: default;
  opacity: 0.5;
}

.category-editor-modal .hx-btn[disabled]:hover {
  background-color: #425866;
}
</style>