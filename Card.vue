<template>
  <div class="hxCard">
    <div class="hxCardHeader">
      <div class="hxCardHeaderWrapper">
        <icon :icon="icon"/>
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
    icon: Object
  }
}

</script>

<style>
.hxCard {
  width: 100%;
  height: 100%;
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
</style>
