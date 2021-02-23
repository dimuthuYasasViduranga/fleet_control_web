import Vue from 'nativescript-vue';
import App from './clients/App.vue';
import VueDevtools from 'nativescript-vue-devtools';
import store from './store/store';

import { AVPlayer } from './clients/code/avPlayer.js';
import { ModalBus } from './clients/code/modalBus.js';
import { Channel } from './clients/code/channel.js';
import * as Toaster from './clients/code/toaster.js';
import { implementGlobals, setErrorHandler } from './clients/code/process.js';
import { ensureDisableSleep } from './clients/code/wake_lock';
import DateTimePicker from 'nativescript-datetimepicker/vue';

// register MapView (google maps sdk) globally
Vue.registerElement('MapView', () => require('nativescript-google-maps-sdk').MapView);
Vue.use(DateTimePicker);

const IS_PRODUCTION = TNS_ENV === 'production';

if (!IS_PRODUCTION) {
  Vue.config.devtools = true;
  Vue.use(VueDevtools);
}

let hostname = HX_URL;
if (!hostname) {
  hostname = 'http://10.0.2.2:4010';
}
Vue.prototype.$hostname = hostname;

Vue.prototype.$clientVersion = HX_VERSION;

Vue.prototype.$site = HX_SITE || 'haultrax';

Vue.prototype.$avPlayer = new AVPlayer();

Vue.prototype.$channel = new Channel(IS_PRODUCTION ? 'normal' : 'debug');

Vue.prototype.$modalBus = new ModalBus();

Vue.prototype.$toaster = Toaster;

// Prints Vue logs when --env.production is *NOT* set while building
Vue.config.silent = IS_PRODUCTION;

// register some process handlers
implementGlobals();
global.process.restartOnError = IS_PRODUCTION;

// set error handler so that production apps are restarted
setErrorHandler();

Vue.registerElement('RadSideDrawer', () => require('nativescript-ui-sidedrawer').RadSideDrawer);

new Vue({
  store,
  render: h => h('frame', [h(App)]),
}).$start();

store.commit('setPromptExceptionOnLogout', IS_PRODUCTION);
store.commit('setPromptEngineHoursOnLogin', IS_PRODUCTION);
store.commit('setPromptEngineHoursOnLogout', false);
store.dispatch('location/startLocationMonitor');
store.dispatch('network/startMonitor');

ensureDisableSleep().then(() => {
  store.dispatch('battery/startMonitor', HX_WAKELOCK);
});
