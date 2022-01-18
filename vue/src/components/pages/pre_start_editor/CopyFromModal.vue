<template>
  <div class="copy-from-modal">
    <h1 class="title">Copy Pre-Start</h1>
    <DropDown
      placeholder="Select Asset"
      :value="selectedAssetType"
      :items="options"
      keyName="assetTypeId"
      label="assetType"
      @change="onAssetTypeChange"
    />

    <template v-if="selectedSections.length">
      <div v-if="selectedSections.length" class="preview">
        <div
          class="section"
          v-for="(section, sIndex) in selectedSections"
          :key="`section-${sIndex}`"
        >
          <div class="heading">{{ section.title }}</div>
          <div class="details">{{ section.details }}</div>
          <div class="controls">
            <div
              class="control"
              v-for="(control, cIndex) in section.controls"
              :key="`section-${sIndex}-control-${cIndex}`"
            >
              <div class="label">- {{ control.label }}</div>
              <DropDown
                class="category"
                placeholder="None"
                :value="control.categoryId"
                :items="categories"
                label="name"
              />
              <Icon
                class="comment-toggle"
                :class="{ dim: !control.requiresComment }"
                v-tooltip="control.requiresComment ? 'Comment Required' : 'Comment Not Required'"
                :icon="commentIcon"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="actions">
        <button class="hx-btn" @click="onCopy()">Copy</button>
        <button class="hx-btn" @click="close()">Cancel</button>
      </div>
    </template>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import DropDown from '@/components/dropdown/DropDown.vue';

import CommentIcon from '@/components/icons/Comment.vue';
import { attributeFromList } from '@/code/helpers';

function toOption(preStartForm, assetTypes) {
  if (!preStartForm) {
    return;
  }
  const assetType = attributeFromList(assetTypes, 'id', preStartForm.assetTypeId, 'type');

  return {
    assetTypeId: preStartForm.assetTypeId,
    assetType,
    preStartForm,
  };
}

export default {
  name: 'CopyFromModal',
  wrapperClass: 'copy-from-wrapper',
  components: {
    Icon,
    DropDown,
  },
  props: {
    preStartForms: { type: Array, default: () => [] },
    categories: { type: Array, default: () => [] },
    assetTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      selectedAssetType: null,
      commentIcon: CommentIcon,
    };
  },
  computed: {
    options() {
      return this.preStartForms
        .map(ps => toOption(ps, this.assetTypes))
        .filter(e => e)
        .sort((a, b) => a.assetType.localeCompare(b.assetType));
    },
    selectedOption() {
      return this.options.find(o => o.assetTypeId === this.selectedAssetType);
    },
    selectedSections() {
      return this.selectedOption?.preStartForm?.sections || [];
    },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onAssetTypeChange(assetTypeId) {
      this.selectedAssetType = assetTypeId;
    },
    onCopy() {
      this.close(this.selectedOption?.preStartForm);
    },
  },
};
</script>

<style>
.copy-from-modal-wrapper .modal-container {
  max-width: 35rem;
}

.copy-from-modal .title {
  text-align: center;
  margin: 0;
}

.copy-from-modal .preview {
  margin-top: 1rem;
}

.copy-from-modal .section {
  margin: 0.5rem 0;
  padding-left: 1rem;
  border-top: 0.1rem solid #677e8c;
  border-bottom: 0.1rem solid #677e8c;
  border-left: 2rem solid #425866;
}

.copy-from-modal .section .heading {
  font-size: 1.5rem;
}

.copy-from-modal .controls {
  margin: 1rem;
}

.copy-from-modal .control {
  display: grid;
  grid-template-columns: auto 10rem 2.5rem;
  margin: 0.25rem;
  padding: 0.5rem;
}

.copy-from-modal .control .comment-toggle {
  height: 2rem;
  padding: 0.2rem;
  padding-left: 0.5rem;
  padding-right: 0;
}

.copy-from-modal .control .comment-toggle svg {
  stroke-width: 1.2;
}

.copy-from-modal .control .comment-toggle.dim {
  opacity: 0.5;
}

.copy-from-modal .control .category {
  pointer-events: none;
}

.copy-from-modal .control .category .dd-right {
  display: none;
}

.copy-from-modal .control .category .dd-button {
  text-align: center;
}

.copy-from-modal .actions {
  margin-top: 2rem;
  display: flex;
  justify-content: flex-end;
}

.copy-from-modal .actions * {
  margin-left: 0.25rem;
}
</style>