import { createRouter, createWebHistory } from 'vue-router';
import UserIcon from './icons/User.vue';

interface Route {
  name: string;
  path: string;
  component: object;
  icon: object;
}
interface Redirect {
  path: string;
  redirect: string;
}
interface Gap {
  path: string;
}
type Routes = Array<Route | Redirect | Gap>;

export default function setupRouter() {
  const host = window.location.hostname;
  const User = () => '<div>Demo App</div>';
  const routes: Routes = [
    {
      name: 'Downloads',
      path: '/downloads',
      component: User,
      icon: UserIcon,
    },
    {
      name: 'NotFound',
      path: '/:catchAll(.*)',
      redirect: '/downloads',
    },
  ];

  //   routes.push('/downloads');
  const router = createRouter({ history: createWebHistory(), routes });
  router.push('/downloads');
  return [routes, router];
}
