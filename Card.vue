<template>
  <div class="hxCard">
    <div class="hxCardHeader" v-if="!hideTitle">
      <div class="hxCardHeaderWrapper">
        <slot name="title-pre"></slot>
        <icon v-if="showIcon" :icon="icon" :iconSize="iconSize" />
        {{ title }}
        <slot name="title-post"></slot>
      </div>
    </div>
    <slot></slot>
  </div>
</template>

<script>
import icon from './Icon.vue';

export default {
  name: 'hxCard',
  components: {
    icon,
  },
  props: {
    title: String,
    hideTitle: { type: Boolean, deafult: false },
    icon: Object,
    icon_size: Number,
    iconSize: Number,
  },
  computed: {
    size() {
      return this.iconSize || this.icon_size || this.icon.size;
    },
    showIcon() {
      return !!this.icon;
    },
  },
};
</script>

<style>
.hxCard {
  background-color: #121f26;
  border-top: 1px solid #364c59;
  padding-left: 2rem;
  padding-right: 2rem;
}

.hxCardHeader {
  padding-top: 1.2rem;
  padding-bottom: 1.8rem;
  display: flex;
  text-transform: uppercase;
}

.hxCardHeaderWrapper {
  display: flex;
  align-items: center;
}

@media screen and (max-width: 820px) {
  .hxCard {
    padding-left: 0rem;
    padding-right: 0rem;
  }
}
</style>
