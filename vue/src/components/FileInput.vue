<template>
  <!-- the form is required to reset the input (manually chaing input.value can be blocked by some browsers) -->
  <form
    ref="form"
    class="file-input"
    :class="{ 'valid-file-inside': validDragInside }"
    enctype="multipart/form-data"
    novalidate
    :disabled="loading"
  >
    <input
      type="file"
      name="albert"
      :accept="acceptString"
      :multiple="multiple"
      v-on="dragHandlers"
      @input="onFilesUpload"
    />
    <div class="text-area-wrapper">
      <div class="text-area">
        <div v-if="loading" class="loading">{{ loadingText }}</div>
        <div v-else class="placeholder">{{ validDragInside ? 'Drop file here' : placeholder }}</div>
      </div>
    </div>
    <div class="border-wrapper">
      <div class="border"></div>
    </div>
  </form>
</template>

<script>
export default {
  name: 'FileInput',
  props: {
    accepts: { type: [String, Array], default: () => [] },
    placeholder: { type: String, default: 'Drag file here or click to browse' },
    multiple: { type: Boolean, default: false },
    loading: { type: Boolean, default: false },
    loadingText: { type: String, default: 'Loading ...' },
  },
  data: () => {
    return {
      validDragInside: false,
    };
  },
  computed: {
    validExtensions() {
      if (typeof this.accepts === 'string') {
        return this.accepts.split(',');
      }

      return this.accepts;
    },
    acceptString() {
      return this.validExtensions.join(',');
    },
    dragHandlers() {
      return {
        dragenter: this.setDragInStyle,
        dragleave: this.resetDragInStyle,
        dragend: this.resetDragInStyle,
        drop: this.resetDragInStyle,
      };
    },
  },
  methods: {
    onFilesUpload(event) {
      const files = [...event.target.files];
      const validFiles = files.filter(f => {
        return this.validExtensions.some(ext => f.name.endsWith(ext));
      });

      this.$refs.form.reset();

      if (validFiles.length === 0) {
        this.$toaster.error('Invalid file type');
        return;
      }

      this.$emit('upload', validFiles);
    },
    setDragInStyle(event) {
      this.validDragInside = !!event.dataTransfer;
    },
    resetDragInStyle() {
      this.validDragInside = false;
    },
  },
};
</script>

<style>
.file-input {
  background: #b6c3cc;
  color: #0c1419;
  height: 200px;
  position: relative;
  cursor: pointer;
}

.file-input:hover {
  background: #748b99;
}

.file-input[disabled] {
  pointer-events: none;
  opacity: 0.8;
}

.file-input.valid-file-inside {
  opacity: 0.8;
}

.file-input input {
  opacity: 0;
  width: 100%;
  height: 100%;
  cursor: pointer;
}

.file-input .text-area-wrapper {
  pointer-events: none;
  position: relative;
  display: flex;
  width: 100%;
  height: 100%;
  font-size: 1rem;
  top: -100%;
}

.file-input .text-area-wrapper .text-area {
  margin: auto;
  text-align: center;
}

.file-input .text-area-wrapper .text-area .loading {
  font-style: italic;
}

.file-input .border-wrapper {
  position: relative;
  pointer-events: none;
  top: -200%;
  width: 100%;
  height: 100%;
  padding: 5px;
  transition: 0.1s padding ease-in;
}

.file-input.valid-file-inside .border-wrapper {
  padding: 10px;
}

.file-input .border-wrapper .border {
  border: 2px dashed #263e49;
  height: 100%;
  width: 100%;
}
</style>