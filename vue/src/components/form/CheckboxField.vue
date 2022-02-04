<template>
  <div class="checkbox-field" :class="{ error: v.$error }">
    <span class="checkbox">
      <input type="checkbox" :checked="value" @change="onToggle()" @keyup.enter="onToggle()" />
    </span>
    <span class="label">{{ wrapper.label }} </span>
    <Icon v-if="wrapper.info" v-tooltip="{ content: wrapper.info, html: true }" :icon="helpIcon" />
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';

import HelpIcon from '@/components/icons/Help.vue';

export default {
  name: 'CheckboxField',
  components: {
    Icon,
  },
  props: {
    wrapper: { type: Object, required: true },
    value: { type: Boolean, default: false },
    v: { type: Object, default: () => ({}) },
  },
  data: () => {
    return {
      helpIcon: HelpIcon,
    };
  },
  methods: {
    onToggle() {
      this.$emit('input', !this.value);
    },
  },
};
</script>

<style>
.checkbox-field {
  margin: 0.75rem 0;
}

.checkbox-field .label {
  margin-left: 0.5rem;
}

.checkbox-field input {
  cursor: pointer;
  width: 1rem;
  height: 1rem;
}

.checkbox-field .hx-icon {
  cursor: pointer;
  margin-left: 0.25rem;
  margin-bottom: -0.1rem;
  display: inline-block;
  height: 1rem;
  width: 1rem;
}
</style>