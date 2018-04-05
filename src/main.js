import Vue from 'vue'
import App from './App.vue'
import VueRouter from 'vue-router'

import HelloWorld from './components/HelloWorld.vue'
import HelloGalaxy from './components/HelloGalaxy.vue'

Vue.config.productionTip = false;
Vue.use(VueRouter);

const routes = [
      { name: 'Hello World', path: '/hello-world', component: HelloWorld },
      { name: 'Hello Galaxy', path: '/hello-galaxy', component: HelloGalaxy }
    ]

const router = new VueRouter({
  routes
});

const props = { routes };

new Vue({
  el: '#app',
  router,
  render: function(createElement) {
    return createElement(App, {props})
  },
  data: { routes }
});
