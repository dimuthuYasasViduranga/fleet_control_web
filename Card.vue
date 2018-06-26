<template>
  <div class="hxCard">
    <div class="hxCardHeader">
      <div class="hxCardHeaderWrapper">
        <icon :icon="icon" :icon_size="icon_size"/>
        {{title}}
      </div>
    </div>
    <slot></slot>
  </div>
</template>

<script>
import icon from './Icon.vue'

export default {
  name: 'hxCard',
  components: {
    icon,
  },
  props: {
    title: String,
    icon: Object,
    icon_size: Number
  }
}

</script>

<style>
.hxCard {
  width: 100%;
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
  ;
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
