<template>
  <header id="header" role="banner">
    <div id="header-wrapper">
      <img id="logo" src="../assets/hps.png">
      <div id="login" >
        <button id="login-btn" v-on:click="showLogout = !showLogout">

          <span class="login-icon-wrapper">
            <svg viewBox="0 0 22 22" class="login-icon">
              <g>
                <path stroke-linejoin="round" d="M16.17 12l4.33 3v6.5h-19V15l4.33-3"></path>
                <rect x="6.5" y=".5" width="9" height="11" rx="4.5" ry="4.5" stroke-linejoin="round"></rect>
              </g>
            </svg>
          </span>

          {{username || "Sign in"}}

          <span class="login-icon-wrapper">
            <svg viewBox="0 0 16 16" class="login-icon" >
              <g>
                <path stroke-linejoin="round" d="M2.4 6.2l5.5 5.5 5.5-5.5"> </path>
              </g>
            </svg>
          </span>
        </button>
        <div v-show="showLogout">
          <i class="triangle-up"></i>
          <button id="logout-btn" @click="logoutClicked()">
            Sign Out
          </button>
        </div>
      </div>
    </div>

  </header>
</template>

<script>

export default {
  name: 'hxHeader',
  props: {
    username: String,
    logout: Function
  },
  data: () => {
    return { showLogout: false };
  },
  methods: {
    logoutClicked: function() {
      this.logout();
      this.showLogout = false;
    }
  }
}

</script>

<style>
#header {
  box-sizing: border-box ;
  line-height: 19.9999px ;
  width: 100%;
  display: block;
  margin: auto;
  height: 4rem;
  background-color: #0c1419;
}

.login-icon {
  pointer-events: none;
  display: block;
  width: 100%;
  height: 100%;
}

.login-icon-wrapper {
  fill: none;
  height: 2em;
  width: 3em;
  position: relative;
  display: flex;
}

.triangle-up {
  position: absolute;
  z-index: 10;
  width: 0;
  height: 0;
  border-left: 0.8em solid transparent;
  border-right: 0.8em solid transparent;
  border-bottom: 1em solid #23343f;
  margin-left: 3.8rem;
  margin-top: 0.5em;
}

#logout-btn {
  color: #b6c3cc;
  position: absolute;
  margin-top: 1em;
  margin-left: 1.5em;
  z-index: 9;
  padding-left: 2em;
  padding-right: 2em;
  border: 1px solid #0c1419;
  background: #23343f;
  max-width: 12rem;
  display: flex;
  box-shadow: none;
  overflow: visible;
  text-transform: none;
  white-space: nowrap;
  text-decoration: none;
  cursor: pointer;
  height: 4rem;
}

#login {
  position: relative;
}

#login-btn:hover, #logout-btn:hover {
  color: #45ace5;
  stroke: #45ace5;
}

#login-btn {
  color: #b7c3cd;
  stroke: #b7c3cd;
  -webkit-appearance: button;
  max-width: 12rem;
  display: flex;
  align-items: center;
  margin-left: auto;
  margin-right: auto;
  line-height: 2rem;
  box-shadow: none;
  background: 0 0;
  outline: 0;
  border: 0!important;
  border-radius: 0!important;
  padding-left: 0;
  padding-right: 0;
  overflow: visible;
  min-width: 4.66667em;
  margin: 0;
  height: 2em;
  padding: 0 calc(2em/ 2);
  text-align: center;
  text-transform: none;
  white-space: nowrap;
  text-decoration: none;
  cursor: pointer;
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
</style>
