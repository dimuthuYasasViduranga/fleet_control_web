<template>
  <div class="layout">
    <img src="../assets/logo.png">
    <div class="nav">
      <div v-for="route in routes" :key="route.path">
        <router-link :to="route.path">{{route.name}}</router-link>
      </div>
    </div>
    <router-view class="view"></router-view>
  </div>
</template>

<script>

export default {
  name: 'Layout',
  props: {
    routes: Array
  },
  created: function() {
    console.log(this)
  }
}

</script>

<style>
#layout {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
