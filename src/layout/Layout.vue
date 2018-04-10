<template>
  <div id="layout">
    <hxHeader :username="username" :logout="logout" />

    <div id="body">
      <hxNavbar :routes="routes"/>
      <span id="nav-gap"/>
      <router-view class="view"></router-view>
    </div>

    <hxFooter />
  </div>
</template>

<script>
import hxHeader from './Header.vue'
import hxNavbar from './Navbar.vue'
import hxFooter from './Footer.vue'

export default {
  name: 'Layout',
  props: {
    routes: Array,
    username: String,
    logout: Function
  },
  components: {
    hxHeader,
    hxNavbar,
    hxFooter
  }
}

</script>

<style>
body {
  margin: 0;
}

#nav-gap {
  width: 4rem;
}

#body {
  width: auto;
  max-width: none;
  margin-right: 0;
  margin-left: 0;
  position: relative;
  display: flex;
  box-sizing: inherit;
  min-height: calc(100vh - 8rem);
}

#layout {
  font-family: "GE Inspira Sans", sans-serif;
  font-weight: normal;
  -webkit-font-smoothing: antialiased;
  color: #2c3e50;
  background-color: #748b99;

  display: flex;
  flex-flow: column;
  height: 100%;
}
</style>
