<template>
  <div v-if="v.$error">
    <span class="error-label" v-for="(msg, index) in errors" :key="index">
      <div class="error-icon-wrapper">
        <Icon class="error-icon" :icon="errorIcon" />
      </div>

      <div class="msg">{{ msg }}</div>
    </span>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import InfoIcon from '@/components/icons/Info.vue';

export default {
  name: 'ErrorLabel',
  components: {
    Icon,
  },
  props: {
    v: { type: Object, default: () => ({}) },
    errors: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      errorIcon: InfoIcon,
    };
  },
};
</script>

<style>
.error-label {
  width: 100%;
  min-height: 1.75rem;
  font-size: 0.85rem;
  margin-top: 0.5rem;
  display: grid;
  grid-template-columns: 2.5rem auto;
  background-color: #4b10102d;
}

.error-label .error-icon-wrapper {
  margin: auto;
  padding-bottom: 0.1rem;
}

.error-label .error-icon {
  height: 1.3rem;
  width: 1.3rem;
}

.error-label .error-icon svg {
  stroke: #FF8A8A;
  stroke-width: 1;
}

.error-label .msg {
  padding: 0.4rem 0;
  color: #FF8A8A;
  line-height: 1.4rem;
}
</style>