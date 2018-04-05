<template>
  <div id="layout">
    <hxHeader />

    <div id="body">
      <hxNavbar :routes="routes"/>
      <span id="nav-gap"/>
      <router-view class="view"></router-view>
    </div>

    <footer role="banner">
      <div id="footer-wrapper">
        <span>
          Powered by
        </span>
      </div>
    </footer>
  </div>
</template>

<script>
import hxHeader from './Header.vue'
import hxNavbar from './Navbar.vue'

export default {
  name: 'Layout',
  props: {
    routes: Array
  },
  created: function() {
    console.log(this)
  },
  components: {
    hxHeader,
    hxNavbar
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

footer span {
  display: block;
  -webkit-margin-after: 12px;
  -webkit-margin-before: 12px;
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

#footer-wrapper {
  margin: 0 15px;
  align-items: center;
  -webkit-box-pack: justify;
  -webkit-box-align: center;
  -webkit-font-smoothing: antialiased;
  -ms-flex-pack: justify;
  -ms-flex-align: center;
  justify-content: space-between;
  display: flex;
  width: auto;
  max-width: none;
  padding-left: 2em;
  padding-right: 2em;
}

footer {
  box-sizing: border-box ;
  line-height: 19.9999px ;
  width: 100%;
  display: flex;
  margin: auto;
  height: 4rem;
  color: #b6c3cc;
  background-color: #0c1419;
  -webkit-box-align: center;
  align-items: center;
  font-size: 12px;
}
</style>
