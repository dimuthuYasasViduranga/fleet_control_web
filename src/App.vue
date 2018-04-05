<template>
  <div>
    <Layout :routes="routes">
    </Layout>
  </div>
</template>

<script>
import Layout from './layout/Layout.vue'

export default {
  name: 'app',
  props: {
    routes: Array
  },
  components: {
    Layout
  }
}
</script>

<style>
</style>
