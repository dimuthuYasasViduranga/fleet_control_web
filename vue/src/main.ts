import { applyFills } from './polyfills.js';
applyFills();

import Vue from 'vue';
import axios from 'axios';
import VTooltip from 'v-tooltip';
import VueResizeObserver from 'vue-resize-observer';
import Vue2TouchEvents from 'vue2-touch-events';
import Toasted from 'vue-toasted';

import setupRouter from './code/routes';
import App from './App.vue';
import store from './store/store.js';
import { Channel } from './code/channel.js';
import { Modal } from './code/modal.js';
import { registerToasts } from './code/toasts.js';

import 'vue-datetime/dist/vue-datetime.css';

import * as VueGoogleMaps from 'gmap-vue';

// config
const isDev = process.env.NODE_ENV === 'development';
let hostname = '';
if (isDev) {
  hostname = 'https://hx-dispatch-test.azurewebsites.net';
  hostname = 'http://localhost:4010';
}

Vue.prototype.$hostname = hostname;
axios.defaults.withCredentials = true;
Vue.use(VTooltip);
Vue.use(VueResizeObserver);
Vue.use(Vue2TouchEvents);

// configure toasted
Vue.use(Toasted, {
  position: 'top-right',
  duration: 3000,
  keepOnHover: true,
  className: 'hx-toasted',
  iconPack: 'callback',
  action: {
    text: 'Clear',
    onClick: (_, toastObject) => {
      toastObject.goAway(0);
    },
  },
});
registerToasts();

// Create an event bug
Vue.prototype.$eventBus = new Vue();

// Create a global channel wrapper
Vue.prototype.$channel = new Channel(false ? 'debug' : null);

Vue.prototype.$modal = new Modal(store);

// setup routes
declare var document: { location: { href: string } };

// fetch whitelist
const whitelistPromise = store.dispatch('constants/fetchRouteWhitelist', { hostname });

const promises = [whitelistPromise];

Promise.all(promises).then(() => {
  const whitelist = store.state.constants.whitelist;
  const [routes, router] = setupRouter(whitelist);

  // logout function
  const logout = function() {
    document.location.href = `${hostname}/auth/logout`;
  };

  function createApp(data: { map_config: object }) {
    const props = { routes, logout };
    const key = data.map_config.key;

    // maps
    Vue.use(VueGoogleMaps, { load: { key, libraries: 'drawing' } });

    new Vue({
      router,
      store,
      render(createElement) {
        return createElement(App, { props });
      },
    }).$mount('#app');
  }

  store.dispatch('constants/getStaticData', [hostname, createApp]);
  store.dispatch('trackStore/startPendingInterval');
});
