<template>
  <header id="header" role="banner">
    <div id="header-wrapper">
      <img id="logo" src="../assets/hps.png" />

      <logout-button :username="username" @logout="logoutUser()" />
    </div>
  </header>
</template>

<script>
import LogoutButton from './LogoutButton.vue';

export default {
  name: 'hxHeader',
  components: {
    LogoutButton,
  },
  props: {
    username: String,
    logout: {type: Function, required: true },
  },
  methods: {
    logoutUser() {
      this.logout();
    },
  },
};
</script>

<style>
#header {
  box-sizing: border-box;
  line-height: 19.9999px;
  width: 100%;
  display: block;
  margin: auto;
  height: 4rem;
  background-color: #0c1419;
}

#logo {
  height: 3.6rem;
  padding-top: 0.2rem;
}

#header-wrapper {
  margin: 0 15px;
  -webkit-box-align: center;
  -ms-flex-align: center;
  align-items: center;
  -webkit-box-pack: justify;
  -ms-flex-pack: justify;
  justify-content: space-between;
  display: flex;
  width: auto;
  max-width: none;
}

@media screen and (max-width: 820px) {
  #logo {
    width: 40%;
    height: auto;
    margin-left: 6em;
  }

  #login-btn:hover,
  #logout-btn:hover {
    color: #b7c3cd;
    stroke: #b7c3cd;
  }
}

@media screen and (max-width: 480px) {
  #logo {
    display: none;
  }
}
</style>
