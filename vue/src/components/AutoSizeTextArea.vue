<template>
  <div ref="replica" class="auto-size-text-area">
    <textarea :value="value" @input="onInput" />
    <div v-show="!value && placeholder" class="placeholder">{{placeholder}}</div>
  </div>
</template>

<script>
export default {
  name: 'AutoSizeTextArea',
  props: {
    value: { type: String },
    placeholder: { type: String },
  },
  methods: {
    onInput(event) {
      const text = event.target.value;
      const replica = this.$refs.replica;
      replica.dataset.replicatedValue = text;
      this.$emit('input', text);
    },
  },
};
</script>

<style>
.auto-size-text-area {
  display: grid;
}

.auto-size-text-area::after {
  content: attr(data-replicated-value) ' ';
  white-space: pre-wrap;
  word-break: break-all;
  visibility: hidden;
}

.auto-size-text-area > textarea {
  z-index: 2;
  resize: none;
  overflow: hidden;
}

.auto-size-text-area > textarea,
.auto-size-text-area::after {
  min-height: 2rem;
  font: inherit;
  border: none;
  border-radius: 0;
  border-bottom: 1px solid #677e8c;
  color: #b6c3cc;
  background-color: transparent;
  outline: none;
  padding: 0.33rem;
  transition: background 0.4s, border-color 0.4s, color 0.4s;

  grid-area: 1 / 1 / 2 / 2;
}

.auto-size-text-area > textarea:focus {
  background-color: white;
  color: #0c1419;
  outline: none;
}

.auto-size-text-area .placeholder {
  padding: 0.33rem;
  position: absolute;
  color: gray;
  z-index: 1;
}
</style>