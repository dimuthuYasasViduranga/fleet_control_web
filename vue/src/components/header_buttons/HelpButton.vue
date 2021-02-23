<template>
  <div class="help-button">
    <Icon :icon="icon" @click="open" />
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import HelpIcon from './../icons/Help.vue';

export default {
  name: 'HelpButton',
  components: {
    Icon,
  },
  data: () => {
    return {
      icon: HelpIcon,
    };
  },
  methods: {
    open() {
      this.$eventBus.$emit('chat-open');
    },
  },
};
</script>

<style>
.help-button {
  margin: auto;
}

.help-button .icon-wrapper {
  height: 1.5rem;
  width: 1.5rem;
  margin: 0 0.75rem;
}
</style>