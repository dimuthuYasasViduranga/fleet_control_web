<template>
  <div v-show="show" class="field-wrapper" :class="{ error: v.$error }">
    <span v-if="label" class="label">{{ label }}</span>
    <Icon v-if="info" v-tooltip="{ content: info, html: true }" :icon="helpIcon" />
    <slot></slot>
    <ErrorLabel v-if="showErrors" :v="v" :errors="errors" />
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';

import HelpIcon from '@/components/icons/Help.vue';
import ErrorLabel from './ErrorLabel.vue';

export default {
  name: 'FormBase',
  components: {
    Icon,
    ErrorLabel,
  },
  props: {
    v: { type: Object, default: () => ({}) },
    label: { type: String, default: null },
    info: { type: String, default: null },
    show: { type: Boolean, default: true },
    errors: { type: Array, default: () => [] },
    showErrors: { type: Boolean, default: true },
  },
  data: () => {
    return {
      helpIcon: HelpIcon,
    };
  },
};
</script>

<style>
.field-wrapper {
  margin: 1.2rem 0;
}

.field-wrapper .label {
  margin-bottom: 0.2rem;
  font-weight: bold;
}

.field-wrapper > .hx-icon {
  cursor: pointer;
  margin-left: 0.25rem;
  margin-bottom: -0.1rem;
  display: inline-block;
  height: 1rem;
  width: 1rem;
}
</style>