<template>
  <div v-if="value" class="pre-start-form-editor">
    <div class="sections">
      <Container
        class="section-container"
        group-name="section-container"
        :drop-placeholder="{
          className: 'tile-drop-preview',
          animationDuration: '150',
          showOnTop: true,
        }"
        drag-handle-selector=".drag-handle"
        :get-child-payload="index => value.sections[index]"
        @drop="onSectionDrop"
      >
        <Draggable v-for="(section, sIndex) in value.sections" :key="`section-${sIndex}`">
          <PreStartSection
            :data="section"
            @sectionRemove="onRemoveSection(section)"
            @controlAdd="onAddControl(section, $event)"
            @controlRemove="onRemoveControl(section, $event)"
            @controlDrop="onControlDrop(section, $event)"
          />
        </Draggable>
      </Container>
      <div
        class="add-new-section"
        tabindex="0"
        @click="onAddSection()"
        @keydown="onAddSectionKeyDown"
      >
        Add Section
      </div>
    </div>
  </div>
</template>

<script>
import { Container, Draggable } from 'vue-smooth-dnd';

import PreStartSection from './PreStartSection.vue';

const ENTER = 13;

function createForm() {
  return {
    title: '',
    details: '',
    sections: [],
  };
}

function createSection() {
  return {
    title: 'Section A',
    details: '',
    controls: [createControl()],
  };
}

function createControl() {
  return {
    label: '',
    requiresComment: false,
    categoryId: null,
  };
}

function changeIndex(sourceArr, fromIndex, toIndex) {
  const arr = sourceArr.slice();
  const item = arr[fromIndex];

  arr.splice(fromIndex, 1);
  arr.splice(toIndex, 0, item);
  return arr;
}

function insertAt(source, index, item) {
  const arr = source.slice();
  arr.splice(index, 0, item);
  return arr;
}

function removeAt(source, index) {
  const arr = source.slice();
  arr.splice(index, 1);
  return arr;
}

export default {
  name: 'PreStartFormEditor',
  components: {
    Container,
    Draggable,
    PreStartSection,
  },
  props: {
    value: { type: Object },
    existingElements: { type: Array, default: () => [] },
  },

  watch: {
    value: {
      immediate: true,
      handler(form) {
        if (!form) {
          this.$emit('input', createForm());
        }
      },
    },
  },
  methods: {
    onAddSection() {
      const section = createSection();
      section.setFocus = true;
      // eslint-disable-next-line vue/no-mutating-props
      this.value.sections.push(section);
    },
    onAddSectionKeyDown({ keyCode }) {
      if (keyCode === ENTER) {
        this.onAddSection();
      }
    },
    onRemoveSection(section) {
      // eslint-disable-next-line vue/no-mutating-props
      this.value.sections = this.value.sections.filter(s => s !== section);
    },
    onAddControl(section) {
      const control = createControl();
      control.setFocus = true;
      section.controls.push(control);
    },
    onRemoveControl(section, control) {
      const controls = section.controls.filter(c => c !== control);
      if (controls.length === 0) {
        controls.push(createControl());
      }

      section.controls = controls;
    },
    onSectionDrop({ addedIndex, removedIndex }) {
      if (addedIndex !== null && removedIndex !== null) {
        // eslint-disable-next-line vue/no-mutating-props
        this.value.sections = changeIndex(this.value.sections, removedIndex, addedIndex);
      }
    },
    onControlDrop(section, { addedIndex, removedIndex, payload }) {
      // no change
      if (addedIndex === null && removedIndex === null) {
        return;
      }

      // the sections is the SAME group
      if (addedIndex !== null && removedIndex !== null) {
        section.controls = changeIndex(section.controls, removedIndex, addedIndex);
        return;
      }

      // the section is a NEW group
      if (addedIndex !== null && removedIndex === null) {
        section.controls = insertAt(section.controls, addedIndex, payload);
        return;
      }

      // the section is the OLD group
      if (addedIndex === null && removedIndex !== null) {
        section.controls = removeAt(section.controls, removedIndex);
        return;
      }
    },
  },
};
</script>

<style>
/* ---- draggable ---- */
.pre-start-form-editor .tile-drop-preview {
  border: 1px dashed grey;
  background-color: rgba(150, 150, 200, 0.1);
}

.pre-start-form-editor .add-new-section {
  margin-top: 0.5rem;
  height: 2rem;
  line-height: 1.9rem;
  cursor: pointer;
  border: 1px dashed grey;
  text-align: center;
}

.pre-start-form-editor .add-new-section:hover {
  opacity: 0.5;
}
</style>
