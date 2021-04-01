<template>
  <div class="n-icon">
    <Icon class="primary-icon" :icon="icon" />
    <div class="secondary-wrapper">
      <Icon class="secondary-icon" :icon="secondaryIcon" :scale="secondaryScale" />
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
export default {
  name: 'NIcon',
  components: {
    Icon,
  },
  props: {
    icon: { type: Object },
    secondaryIcon: { type: Object },
    secondaryScale: { type: Number, default: 1 },
  },
};
</script>

<style>
.n-icon {
  width: 2rem;
  position: relative;
}

.n-icon .primary-icon {
  width: 100%;
  height: 100%;
  padding: 0 5%;
}

.n-icon .secondary-wrapper {
  width: 40%;
  height: 40%;
  position: absolute;
  bottom: 5%;
  right: 5%;
}

.n-icon .secondary-wrapper .secondary-icon {
  width: 100%;
  height: 100%;
}
</style>