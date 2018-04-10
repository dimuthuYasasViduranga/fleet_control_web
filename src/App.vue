<template>
  <div>
    <Layout :routes="routes" :username="username" :logout="logout" />
  </div>
</template>

<script>
import Layout from './layout/Layout.vue'

export default {
  name: 'app',
  props: {
    routes: Array,
    username: String,
    logout: Function
  },
  components: {
    Layout
  }
}
</script>
