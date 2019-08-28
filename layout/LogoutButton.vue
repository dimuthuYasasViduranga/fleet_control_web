<template>
  <div id="login" v-show="username">
    <button id="login-btn" v-on:click="showLogout = !showLogout">
      <span class="login-icon-wrapper">
        <svg viewBox="0 0 22 22" class="login-icon">
          <g>
            <path stroke-linejoin="round" d="M16.17 12l4.33 3v6.5h-19V15l4.33-3"></path>
            <rect
              x="6.5"
              y=".5"
              width="9"
              height="11"
              rx="4.5"
              ry="4.5"
              stroke-linejoin="round"
            ></rect>
          </g>
        </svg>
      </span>

      {{ username || 'Sign in' }}

      <span class="login-icon-wrapper">
        <svg viewBox="0 0 16 16" class="login-icon">
          <g>
            <path stroke-linejoin="round" d="M2.4 6.2l5.5 5.5 5.5-5.5"></path>
          </g>
        </svg>
      </span>
    </button>
    <div v-show="showLogout">
      <i class="triangle-up"></i>
      <button id="logout-btn" @click="emitLogout()">
        Sign Out
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LogoutButton',
  props: {
    username: String,
  },
  data: () => {
    return {
      showLogout: false,
    };
  },
  methods: {
    emitLogout() {
      this.$emit('logout');
    },
  },
};
</script>

<style>
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
  border: 0 !important;
  border-radius: 0 !important;
  padding-left: 0;
  padding-right: 0;
  overflow: visible;
  min-width: 4.66667em;
  margin: 0;
  height: auto;
  padding: 0 calc(2em / 2);
  text-align: center;
  text-transform: none;
  white-space: nowrap;
  text-decoration: none;
  cursor: pointer;
}

#logout-btn {
  color: #b6c3cc;
  position: absolute;
  margin: 1em 0;
  z-index: 9;
  padding-left: 2em;
  padding-right: 2em;
  border: 1px solid #0c1419;
  background: #23343f;
  max-width: 12rem;
  box-shadow: none;
  overflow: visible;
  text-transform: none;
  white-space: nowrap;
  text-decoration: none;
  cursor: pointer;
  height: 4rem;
}

#login-btn:hover,
#logout-btn:hover {
  color: #45ace5;
  stroke: #45ace5;
}

</style>