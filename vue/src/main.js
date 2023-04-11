import { applyFills } from './polyfills.js';
applyFills();

import Vue from 'vue';
import axios from 'axios';
import VTooltip from 'v-tooltip';
import VueResizeObserver from 'vue-resize-observer';
import Vue2TouchEvents from 'vue2-touch-events';
import Toasted from 'vue-toasted';

import { Modal } from 'hx-vue';

import setupRouter from './code/routes';
import App from './App.vue';
import UnauthorizedApp from './UnauthorizedApp.vue';
import UnknownErrorApp from './UnknownErrorApp.vue';
import store from './store/store.js';
import Channel from './code/vue_properties/channel.js';
import Timely from './code/vue_properties/timely.js';
import Toaster from './code/toaster.js';
import ContextMenu from './code/vue_properties/context_menu.js';
import Geolocation from './code/vue_properties/geolocation.js';
import { startFullscreenObserver } from './code/tooltip';

import 'vue-datetime/dist/vue-datetime.css';

import * as VueGoogleMaps from 'gmap-vue';
import { nowTimer } from './code/time.js';

const isDev = process.env.NODE_ENV === 'development';
let hostname = window.location.origin;
if (isDev) {
  hostname = 'http://localhost:4010';
}
hostname += '/fleet-control';

Vue.prototype.$hostname = hostname;
axios.defaults.withCredentials = true;
Vue.use(VTooltip);
Vue.use(VueResizeObserver);
Vue.use(Vue2TouchEvents);

startFullscreenObserver();

// Create an event bug
Vue.prototype.$eventBus = new Vue();

// Create a global channel wrapper
Vue.prototype.$channel = Channel;

Modal.store = store;
Vue.prototype.$modal = Modal;

Vue.prototype.$toaster = Toaster;

Vue.prototype.$contextMenu = ContextMenu;

Vue.prototype.$geolocation = Geolocation;

Vue.prototype.$timely = Timely;

Vue.prototype.$everySecond = nowTimer(1000);

// Logout function
const logout = function () {
  window.location.href = `${hostname}/auth/logout`;
};

const configureToasts = function (router) {
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
};

async function startApp(staticData) {
  store.dispatch('constants/setStaticData', staticData);
  store.dispatch('trackStore/startPendingInterval');

  const whitelist = staticData.whitelist;

  const [routes, router] = setupRouter(whitelist);

  // configure toasted
  configureToasts(router);

  const props = { routes, logout };
  const key = staticData.data.map_config.key;

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

async function startUnauthorized(user) {
  const props = { user };
  new Vue({
    render(createElement) {
      return createElement(UnauthorizedApp, { props });
    },
  }).$mount('#app');
}

async function startUnknownError(error) {
  const props = { error };
  new Vue({
    render(createElement) {
      return createElement(UnknownErrorApp, { props });
    },
  }).$mount('#app');
}

axios
  .get(`${hostname}/api/static_data`)
  .then(resp => {
    if (resp.data.authorized) {
      startApp(resp.data);
      return;
    }

    startUnauthorized(resp.data.user);
  })
  .catch(error => {
    console.error(error);
    if (isDev) {
      console.error('While rendering from 8080, ensure that bypass_auth is true');
    }

    if (error.response?.status === 401) {
      document.location.href = hostname;
    } else {
      startUnknownError(error);
    }
  });
