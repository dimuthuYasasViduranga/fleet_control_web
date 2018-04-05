<template>
  <header role="banner">
    <div id="header-wrapper">
      <img id="logo" src="../assets/hps.png">
      <span id="login">
        <button id="login-btn">
          <span class="icon-wrapper">
            <svg viewBox="0 0 22 22" preserveAspectRatio="xMidYMid meet" focusable="false" class="icon" style="pointer-events: none; display: block; width: 100%; height: 100%;"><g class="style-scope iron-icon"><path stroke-linejoin="round" d="M16.17 12l4.33 3v6.5h-19V15l4.33-3" class="style-scope iron-icon"></path><rect x="6.5" y=".5" width="9" height="11" rx="4.5" ry="4.5" stroke-linejoin="round" class="style-scope iron-icon"></rect></g></svg>
          </span>

          {{username || "Sign in"}}

          <span class="icon-wrapper">
            <svg viewBox="0 0 16 16" preserveAspectRatio="xMidYMid meet" focusable="false" class="style-scope iron-icon" style="pointer-events: none; display: block; width: 100%; height: 100%;"><g class="style-scope iron-icon"><path stroke-linejoin="round" d="M2.4 6.2l5.5 5.5 5.5-5.5" class="style-scope iron-icon"></path></g></svg>
          </span>
        </button>
      </span>
    </div>
  </header>
</template>

<script>

export default {
  name: 'hxHeader',
  props: {
    username: String,
    logoutUrl: String,
  }
}

</script>

<style>
header {
  box-sizing: border-box ;
  line-height: 19.9999px ;
  width: 100%;
  display: block;
  margin: auto;
  height: 4rem;
  color: #b6c3cc;
  background-color: #0c1419;
}

.icon-wrapper {
  fill: none;
  height: 2em;
  width: 4em;
  position: relative;
  display: flex;
}

#login {
  position: relative;
  display: flex;
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
  height: 3.8rem;
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
