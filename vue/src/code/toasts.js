import Vue from 'vue';

import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import NoWifi from './../components/icons/noWifi.vue';

const VALID_TYPES = ['info', 'error', 'no-comms'];

export class Toaster {
  clearAll() {
    Vue.toasted.toasts.forEach(t => t.remove());
  }

  clear(predicate) {
    Vue.toasted.toasts.filter(predicate).forEach(t => t.remove());
  }

  info(msg, opts) {
    return this.custom(msg, 'info', opts);
  }

  error(msg, opts) {
    return this.custom(msg, 'error', opts);
  }

  noComms(msg, opts) {
    return this.custom(msg, 'no-comms', opts);
  }

  custom(msg, type, options) {
    if (!VALID_TYPES.includes(type)) {
      console.error(`[Toasted] Invalid toast type ${type}`);
      return;
    }

    const opts = options || {};

    if (opts.delay > 0) {
      console.log(`[Toaster] Delaying toast for ${opts.delay} ms`);
      setTimeout(() => {
        this.custom(msg, type, { ...opts, delay: null });
      }, opts.delay);
      return;
    }

    if (opts.replace) {
      for (const t of Vue.toasted.toasts) {
        if (t.type === type && t.text === msg) {
          t.remove();
        }
      }
    }

    if (opts.onlyOne) {
      const alreadyExists = Vue.toasted.toasts.some(t => t.type === type && t.text == msg);

      if (alreadyExists) {
        console.log('[Toaster] Msg skipped as it already exists');
        return;
      }
    }

    if (opts.if) {
      const canProceed = Vue.toasted.toasts.every(opts.if);
      if (!canProceed) {
        return;
      }
    }

    return createToast(msg, type);
  }
}

function createToast(msg, type) {
  const newToast = Vue.toasted.global[type](`<span class="toast-text">${msg}</span>`);
  newToast.type = type;
  newToast._text = msg;

  Object.defineProperty(newToast, 'text', {
    set: function(text) {
      newToast._text = text;
      const textEl = Array.prototype.slice
        .call(newToast.el.childNodes)
        .find(e => e.classList.contains('toast-text'));
      if (textEl) {
        textEl.innerText = text;
      }
    },
    get: function() {
      return newToast._text;
    },
  });

  return newToast;
}

export function registerCustomToasts() {
  console.log('[Toaster] Registering custom toasts');
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
  Vue.toasted.register('no-comms', msg => msg || 'No Comms', {
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
