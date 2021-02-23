<template>
  <div class="pre-start-control">
    <Icon class="drag-handle" :icon="hamburgerIcon" />
    <input
      ref="control-input"
      class="label typeable"
      placeholder="Criteria"
      v-model="data.label"
      @keydown="onKeyDown"
    />
    <Icon v-tooltip="'Remove'" class="remove-icon" :icon="crossIcon" @click="onRemove()" />
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import HamburgerIcon from '@/components/icons/Hamburger.vue';

const ENTER = 13;

export default {
  name: 'Control',
  components: {
    Icon,
  },
  props: {
    data: { type: Object, required: true },
  },
  data: () => {
    return {
      crossIcon: ErrorIcon,
      hamburgerIcon: HamburgerIcon,
    };
  },
  mounted() {
    if (this.data.setFocus) {
      this.$refs['control-input'].focus();
      delete this.data.setFocus;
    }
  },
  methods: {
    onRemove() {
      this.$emit('remove');
    },
    onKeyDown(event) {
      if (event.keyCode === ENTER) {
        this.$emit('enter', event);
      }
    },
  },
};
</script>

<style>
.pre-start-control {
  display: grid;
  grid-template-columns: 3rem auto 2rem;
  margin: 0.25rem;
  padding: 0.5rem;
  background-color: #23343f;
}

.pre-start-control .drag-handle {
  cursor: pointer;
  width: 2rem;
  height: 100%;
  padding: 0.5rem;
}

.pre-start-control .remove-icon {
  cursor: pointer;
  height: 2rem;
  padding: 0.5rem;
}

.pre-start-control .remove-icon:hover {
  stroke: red;
}
</style>