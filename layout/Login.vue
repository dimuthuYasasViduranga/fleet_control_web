<template>
  <div>
    <hxCard title="Login" :icon="icon" :icon_size="icon_size">
      <error :error="error" />

      <div class="form-group">
        <input 
        class="login-textbox"
        type="text"
        placeholder="Enter your username"
        v-model="username"
        >
      </div>
      <div class="login-gap" />
      <div class="form-group">
        <input
        class="login-textbox"
        type="password"
        placeholder="Enter your password"
        v-model="password"
        >
      </div>
      <div class="login-gap" />
      <button 
        class="login-btn" 
        @click="submit()"
        >
        Login &nbsp; <i class="fa fa-arrow-circle-o-right"></i>
      </button>
    </hxCard>
  </div>
</template>

<script>

import hxCard from 'hx-layout/Card.vue'
import error from 'hx-layout/Error.vue'
import UserIcon from '../icons/User.vue'

export default {
  name: 'hxLogin',
  props: {
    login: Function,
  },
  data: () => {
    return {
      icon: UserIcon,
      icon_size: 22,
      username: "",
      password: "",
      error: "",
    }
  },
  components: {
    hxCard,
    error,
  },
  methods: {
    submit: function() {
      this.error = "";

      this.login(this.username, this.password)
        .catch((error) => {
          console.error(error);
          console.dir(error);
          this.error = error.toString();
        });
    }
  }
}

</script>

<style>
.login-gap {
  height: 1em;
}

.login-wrapper {
  display: block;
  width: 100%;
}

.login-textbox {
  font: inherit;
  height: 2em;
  width: 22em;
  border: none;
  border-radius: 0;
  border-bottom: 1px solid #677e8c;
  padding: 0 0.33333rem;
  color: #b6c3cc;
  background-color: transparent;
  transition: background .4s, border-color .4s, color .4s;
}

.login-textbox:focus {
  background-color: white;
  color: #0c1419;
}

.login-btn {
  color: white;
  display: inline-block;
  overflow: visible;
  height: 2em;
  min-width: 4.66667em;
  margin: 0;
  border: 1px solid transparent;
  border-radius: 0 !important;
  padding: 0 calc(2em / 2);
  box-shadow: none;
  font: inherit;
  line-height: calc(2em - 2px);
  -webkit-font-smoothing: antialiased;
  cursor: pointer;
  text-align: center;
  text-decoration: none;
  text-transform: none;
  white-space: nowrap;
  background-color: #425866;
  transition: background .4s, border-color .4s, color .4s;
}

</style>
