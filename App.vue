<template>
  <div tabindex="-1">
    <Layout :routes="routes" :username="username" :logout="logout" :login="login" />
  </div>
</template>

<script>
import Layout from './Layout.vue';

export default {
  name: 'App',
  components: {
    Layout,
  },
  props: {
    routes: Array,
    logout: Function,
    login: Function,
  },
  data: () => {
    return {
      title: 'App',
      username: ' ',
      eventSet: new Set(),
    };
  },
  async mounted() {
    this.getUserInfo();
  },
  methods: {
    getUserInfo() {
      this.username = 'Unknown';
    },
  },
};
</script>

<style>
.wrapper {
  display: flex;
}

.contents-wrapper {
  display: contents;
}

a {
  cursor: pointer;
  color: #007acc;
}

.hxCard .vue-slider-dot {
  z-index: 4;
}

.gm-style .gm-style-iw-c {
  border-radius: 0px;
}
a[href^='#/gap'] {
  pointer-events: none;
  cursor: default;
  display: block;
}

a[href^='#/gap'] div {
  height: 1.5em;
  background-color: #121f26;
}

div[id^='chart-'] {
  line-height: normal !important;
}

select {
  width: 8em;
  height: 1.55em;
  color: #0c1419;
  background-color: #ededed;
  border-style: none;
  text-align: center;
  margin: 0.1em;
}
</style>
