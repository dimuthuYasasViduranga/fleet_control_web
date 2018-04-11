<template>
  <hxCard :title="title" :icon="icon">
    <div class="hello">
      <h1>{{ msg }}</h1>
      This is much more sparse.
    </div>
  </hxCard>
</template>

<script>
import hxCard from '../layout/Card.vue'
import getIcon from '../iconDictionary.js'

export default {
  name: 'HelloGalaxy',
  props: {
    msg: String
  },
  components: {
    hxCard
  },
  data: () => {
    return {
      title: 'Hello Galaxy',
      icon: getIcon('generic-user')
    };
  }
}
</script>
