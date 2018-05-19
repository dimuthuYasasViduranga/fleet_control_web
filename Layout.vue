<template>
  <div id="layout">
    <hxHeader :username="username" :logout="logout" />

    <div v-if="username" id="body">
      <hxNavbar :routes="routes"/>
      <span id="nav-gap"/>
      <router-view class="view"></router-view>
    </div>

    <div v-if="!username" id="body" class="wrapper" style="width:100%">
      <hxLogin :login="login"/>
    </div>

    <hxFooter />
  </div>
</template>

<script>
import hxHeader from './layout/Header.vue'
import hxNavbar from './layout/Navbar.vue'
import hxFooter from './layout/Footer.vue'
import hxLogin from './layout/Login.vue'

export default {
  name: 'Layout',
  props: {
    routes: Array,
    username: String,
    logout: Function,
    login: Function
  },
  components: {
    hxHeader,
    hxNavbar,
    hxFooter,
    hxLogin
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

  // two options for color
  color: #2c3e50;
  color: #b6c3cc;
  background-color: #748b99;

  display: flex;
  flex-flow: column;
  height: 100%;
}
</style>
