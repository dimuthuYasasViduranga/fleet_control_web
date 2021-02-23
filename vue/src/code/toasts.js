import Vue from 'vue';

import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import NoWifi from './../components/icons/noWifi.vue';

export function registerToasts() {
  Vue.toasted.register('error', msg => msg || 'Something went wrong', {
    type: 'error',
    duration: 5000,
    icon: () => {
      const placeholder = document.createElement('div');

      setTimeout(() => {
        const instance = new Vue({ ...Icon, propsData: { icon: ErrorIcon } });
        instance.$mount(placeholder);
      });

      return placeholder;
    },
  });
  Vue.toasted.register('noComms', msg => msg || 'No Comms', {
    type: 'error',
    duration: 5000,
    icon: () => {
      const placeholder = document.createElement('div');

      setTimeout(() => {
        const instance = new Vue({ ...Icon, propsData: { icon: NoWifi } });
        instance.$mount(placeholder);
        instance.$el.classList.add('no-comms');
      });

      return placeholder;
    },
  });
  Vue.toasted.register('info', msg => msg || 'Unknown notification', {
    type: 'info',
  });
}
