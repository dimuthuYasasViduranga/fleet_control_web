<template>
  <div class="pre-start-section">
    <Icon class="drag-handle" :icon="hamburgerIcon" />
    <div>
      <div class="header">
        <div class="info">
          <input
            class="title typeable"
            ref="section-title-input"
            v-model="data.title"
            placeholder="Title"
          />
          <input class="details typeable" v-model="data.details" placeholder="Details" />
        </div>
        <Icon
          v-tooltip="'Remove'"
          class="remove-icon"
          :icon="crossIcon"
          @click="onRemoveSection()"
        />
      </div>
      <div class="controls">
        <Container
          group-name="control-container"
          :drop-placeholder="{
            className: 'tile-drop-preview',
            animationDuration: '150',
            showOnTop: true,
          }"
          drag-handle-selector=".drag-handle"
          :get-child-payload="index => data.controls[index]"
          @drop="onDrop"
        >
          <Draggable v-for="(control, index) in data.controls" :key="`control-${index}`">
            <PreStartControl :data="control" @remove="onRemoveControl(control)" @enter="onEnter(index)" />
          </Draggable>
        </Container>
        <div class="add-new-control" @click="onAddControl()">Add Criteria</div>
      </div>
    </div>
  </div>
</template>

<script>
import { Container, Draggable } from 'vue-smooth-dnd';
import PreStartControl from './PreStartControl.vue';

import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import HamburgerIcon from '@/components/icons/Hamburger.vue';

export default {
  name: 'PreStartSection',
  components: {
    Container,
    Draggable,
    Icon,
    PreStartControl,
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
      this.$refs['section-title-input'].focus();
      delete this.data.setFocus;
    }
  },
  methods: {
    onAddControl() {
      this.$emit('controlAdd');
    },
    onRemoveControl(control) {
      this.$emit('controlRemove', control);
    },
    onRemoveSection() {
      this.$emit('sectionRemove');
    },
    onDrop(event) {
      this.$emit('controlDrop', event);
    },
    onEnter(index) {
      if (index === this.data.controls.length - 1) {
        this.onAddControl();
      }
    },
  },
};
</script>

<style>
.pre-start-section {
  margin: 0.5rem 0;
  display: grid;
  grid-template-columns: 3rem auto;
  border-top: 0.1rem solid #677e8c;
  border-bottom: 0.1rem solid #677e8c;
  background-color: #121f26;
}

.pre-start-section .typeable {
  border-bottom: 0.05rem solid #2c404c;
}

.pre-start-section .drag-handle {
  cursor: pointer;
  width: 2rem;
  height: 100%;
  padding: 0.25rem;
  background-color: #23343f;
}

.pre-start-section .header {
  display: grid;
  grid-template-columns: auto 2rem;
}

.pre-start-section .header .info {
  display: flex;
  flex-direction: column;
}

.pre-start-section .header .info .title {
  font-size: 1.5rem;
  width: 50%;
}

.pre-start-section .remove-icon {
  cursor: pointer;
  height: 2rem;
  padding: 0.2rem;
}

.pre-start-section .remove-icon:hover {
  stroke: red;
}

.pre-start-section .controls {
  margin-top: 0.5rem;
}

.pre-start-section .add-new-control {
  margin-top: 0.5rem;
  height: 2rem;
  line-height: 2rem;
  cursor: pointer;
  border: 1px dashed grey;
  text-align: center;
}

.pre-start-section .add-new-control:hover {
  opacity: 0.5;
}
</style>