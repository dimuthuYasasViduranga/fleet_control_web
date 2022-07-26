import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router';
import UserIcon from './icons/User.vue';

type Routes = Array<RouteRecordRaw>;

export default function setupRouter() {
  const routes: Routes = [
    {
      name: 'Downloads',
      path: '/downloads',
      component: () => import('./SamplePage.vue'),
      meta: {
        icon: UserIcon,
        title: 'testing',
      },
    },
    {
      name: 'NotFound',
      path: '/:catchAll(.*)',
      redirect: '/downloads',
    },
  ];

  const router = createRouter({ history: createWebHistory(), routes });
  return [routes, router];
}
