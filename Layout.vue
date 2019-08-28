<template>
  <div id="layout">
    <hxHeader :username="username" :logout="logout" >
      <slot name="header"></slot>
    </hxHeader>

    <div v-if="username" id="body">
      <hxNavbar :routes="routes" @showPage="showPage" @hidePage="hidePage" />
      <div :class="smallShowPage">
        <router-view class="view"></router-view>
      </div>
    </div>

    <hxFooter>
      <slot name="footer"></slot>
    </hxFooter>
  </div>
</template>

<script>
import hxHeader from './layout/Header.vue'
import hxNavbar from './layout/Navbar.vue'
import hxFooter from './layout/Footer.vue'

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
  },
  data: () => {
    return { smallShowPage: "showPage" };
  },
  methods: {
    hidePage() {
      this.smallShowPage = "hidePage";
    },
    showPage() {
      this.smallShowPage = "showPage";
    },
  }
}

</script>

<style>
body {
  margin: 0;
}

input {
    border-radius: 0;
}

#layout {
  font-family: "GE Inspira Sans", sans-serif;
  font-weight: normal;
  -webkit-font-smoothing: antialiased;

  color: #b6c3cc;
  background-color: #748b99;

  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

#body {
  flex: 1;
  flex-direction: column;
  position: relative; 
  display: flex; 
  box-sizing: inherit; 
  min-height: calc(100vh - 8rem); 
}

.view {
  margin-left: 4rem;
}

.hidePage, .showPage {
  display: contents;
}

@media screen and (max-width: 820px) {
  .view {
    margin-left: 0rem;
  }
  .hidePage {
    display: none;
  }
}
</style>
