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
import { Timely } from './code/timely.js';
import { Toaster } from './code/toasts.js';

import 'vue-datetime/dist/vue-datetime.css';

import * as VueGoogleMaps from 'gmap-vue';
import { nowTimer } from './code/time.js';

declare var window: { location: { href: string; origin: string } };

const isDev = process.env.NODE_ENV === 'development';
let hostname = window.location.origin;
let uiHost = '';
if (isDev) {
  hostname = 'http://localhost:4010';
  uiHost = 'http://localhost:8080';
}

// in the future this will be required when on the kube
// hostname += '/fleet-control'

Vue.prototype.$hostname = hostname;
axios.defaults.withCredentials = true;
Vue.use(VTooltip);
Vue.use(VueResizeObserver);
Vue.use(Vue2TouchEvents);

// Create an event bug
Vue.prototype.$eventBus = new Vue();

// Create a global channel wrapper
Vue.prototype.$channel = new Channel(false ? 'debug' : null);

Vue.prototype.$modal = new Modal(store);

Vue.prototype.$toaster = new Toaster();

const timely = Vue.observable(new Timely());
Vue.prototype.$timely = timely;

Vue.prototype.$everySecond = nowTimer(1000);

// setup routes

const logout = function() {
  window.location.href = `${hostname}/auth/logout`;
};

async function startApp() {
  const whitelist = store.state.constants.whitelist;
  const [routes, router] = setupRouter(whitelist);

  // logout function

  // configure toasted
  Vue.use(Toasted, {
    position: 'top-right',
    theme: 'hx-toast',
    duration: 3000,
    keepOnHover: true,
    iconPack: 'callback',
    router,
    action: {
      text: 'Clear',
      onClick: (_, toastObject) => {
        toastObject.goAway(0);
      },
    },
  });

  function createApp(data: { map_config: { key: string } }) {
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

  store.dispatch('constants/getStaticData', [hostname, createApp, timely]);
  store.dispatch('trackStore/startPendingInterval');
}

// fetch whitelist
const whitelistPromise = store.dispatch('constants/fetchRouteWhitelist', { hostname });

const promises = [whitelistPromise];

Promise.all(promises)
  .then(startApp)
  .catch(error => {
    console.error(error);
    if (isDev) {
      console.error('While rendering from 8080, ensure that bypass_auth is true');
    } else {
      document.location.href = uiHost || hostname;
    }
  });
