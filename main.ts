import { createApp, configureCompat } from 'vue';
import setupRouter from './setup_routes';
import App from './App.vue';

configureCompat({
  MODE: 3,
});

declare var document: { location: { href: string } };
// config
let hostname = '';
if (import.meta.env.MODE === 'development') {
  hostname = 'http://localhost:4000';
}

// setup routes
const [routes, router] = setupRouter();

// logout function
const logout = () => {
  document.location.href = hostname;
};

// startApp
const props = { routes, logout };
console.log(props);

// const app = createApp({ routes, logout, router, ...App });
const app = createApp(App, props);

app.config.globalProperties.$hostname = hostname;
app.use(router);
app.mount('#app');
