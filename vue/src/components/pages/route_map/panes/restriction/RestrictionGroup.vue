<template>
  <div class="restriction-group">
    <div class="actions">
      <input
        ref="input"
        class="search typeable"
        type="text"
        placeholder="Group Name"
        :value="name"
        :disabled="!canEditName"
        @change="onNameChange"
      />
    </div>
    <Container
      orientation="horizontal"
      group-name="restriction"
      :drop-placeholder="containerPlaceholderOptions"
      :get-child-payload="index => getPayload(index)"
      @drop="onDrop"
    >
      <Draggable v-for="type in assetTypes" :key="type">
        <Icon v-tooltip="type" class="asset-type-icon" :icon="icons[type]" />
      </Draggable>
    </Container>
    <button
      v-if="canRemove && assetTypes.length === 0"
      class="hx-btn remove-btn"
      @click="onRemove()"
    >
      Remove
    </button>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import { Container, Draggable } from 'vue-smooth-dnd';
import Icon from 'hx-layout/Icon.vue';

export default {
  name: 'RestrictionGroup',
  components: {
    Container,
    Draggable,
    Icon,
  },
  props: {
    value: { type: Object },
    canEditName: { type: Boolean, default: true },
    canRemove: { type: Boolean, default: true },
  },
  data: () => {
    return {
      containerPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
    };
  },
  computed: {
    ...mapState('constants', {
      icons: state => state.icons,
    }),
    assetTypes() {
      return this.value?.assetTypes || [];
    },
    name() {
      return this.value?.name || '';
    },
  },
  methods: {
    getPayload(index) {
      return this.assetTypes[index];
    },
    update(changes) {
      this.$emit('update', { ...this.value, ...changes });
    },
    onDrop({ addedIndex, removedIndex, payload }) {
      // is added
      if (addedIndex != null && removedIndex == null) {
        this.$emit('added', { assetType: payload });
      }
    },
    onNameChange(event) {
      this.update({ name: event.target.value });
    },
    onRemove() {
      this.$emit('remove');
    },
  },
};
</script>

<style>
.restriction-group {
  min-height: 8rem;
  border: 1px solid orange;
}

.restriction-group input[disabled] {
  border: none;
  font-style: italic;
}

.restriction-group .remove-btn {
  position: relative;
  width: 6rem;
  top: -3rem;
  left: calc(50% - 3rem);
  margin-top: -5rem;
  margin-bottom: -5rem;
}

/* dnd wrappers */
.restriction-group .smooth-dnd-container.horizontal {
  width: 100%;
  min-height: 5rem;
  padding: 0.25rem;
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  overflow: hidden;
}

.restriction-group .smooth-dnd-container.horizontal > .smooth-dnd-draggable-wrapper {
  cursor: pointer;
  background-color: #2c404c;
  height: 4rem;
  width: 4rem;
  margin: 2px;
}

.restriction-group .tile-drop-preview {
  height: 4rem;
  width: 4rem;
  border: 1px dashed grey;
  background-color: rgba(150, 150, 200, 0.1);
  margin: 2px;
}

.restriction-group .asset-type-icon {
  height: 4rem;
  width: 4rem;
  padding: 4px;
}
</style>