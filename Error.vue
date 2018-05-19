<template>
  <div v-if="error" class="error">
    <div class="card-wrapper">
      <hxCard :title="error" :icon=icon :icon_size="icon_size">
      </hxCard>
    </div>
  </div>
</template>

<script>
import hxCard from 'hx-layout/Card.vue'
import ErrorIcon from './icons/Error.vue'

export default {
  name: 'Error',
  props: {
    error: String
  },
  components: {
    hxCard,
  },
  data: () => {
    return {
      icon: ErrorIcon,
      icon_size: 16,
    };
  },
}
</script>

<style>
.error {
  color: red;
}

.error .icon-wrapper {
  stroke: red;
}
</style>
