<template>
  <header id="header" role="banner">
    <div id="header-wrapper">
      <div class="logo-wrapper">
        <img id="logo" src="../assets/hps.png" />
      </div>
      <div class="header-right">
        <div class="slot-wrapper">
          <slot></slot>
        </div>
        <div class="logout-wrapper">
          <logout-button :username="username" @logout="logoutUser()" />
        </div>
      </div>
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
    logout: { type: Function, required: true },
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
  height: 100%;
  padding: 0.1rem 0;
}

.logo-wrapper {
  position: absolute;
  left: 0;
  display: contents;
  width: auto;
  height: 100%;
}

.header-right {
  position: absolute;
  right: 0;
  display: inline-flex;
  padding-left: 1rem;
}

.slot-wrapper {
  display: inline-flex;
}

.slot-element {
  vertical-align: middle;
  margin: 0 0.25rem;
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
  height: 100%;
  max-width: none;
}

@media screen and (max-width: 820px) {
  #logo {
    width: 40%;
    height: auto;
    margin-left: 5rem;
  }

  #login-btn:hover,
  #logout-btn:hover {
    color: #b7c3cd;
    stroke: #b7c3cd;
  }
}

@media screen and (max-width: 620px) {
  #logo {
    width: 30%;
    height: auto;
    margin-left: 5rem;
  }
}

@media screen and (max-width: 580px) {
  #logo {
    display: none;
  }
}
</style>
