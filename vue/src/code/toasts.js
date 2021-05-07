import Vue from 'vue';

import Icon from 'hx-layout/Icon.vue';
import ErrorIcon from 'hx-layout/icons/Error.vue';
import NoWifi from './../components/icons/noWifi.vue';

let NEXT_ID = 0;

function getNextId() {
  const id = NEXT_ID;
  NEXT_ID += 1;
  return id;
}

// need to convert this to use show instead (more control)

export class Toaster {
  clearAll() {
    Vue.toasted.clear();
  }

  clear(predicate) {
    Vue.toasted.toasts.filter(predicate).forEach(t => t.remove());
  }

  info(msg, opts = {}) {
    return this.custom(msg, 'info', { duration: 3000, ...opts });
  }

  error(msg, opts = {}) {
    return this.custom(msg, 'error', { duration: 5000, ...opts, icon: ErrorIcon });
  }

  noComms(msg, opts = {}) {
    return this.custom(msg, 'no-comms', { duration: 5000, ...opts, icon: NoWifi });
  }

  custom(msg, type, opts = {}) {
    const options = {
      ...opts,
      className: type,
    };

    const actions = opts.action || opts.actions;
    if (actions) {
      options.action = actions;
    }

    if (opts.replace) {
      for (const t of Vue.toasted.toasts) {
        if ((opts.id && t.id === opts.id) || (t.type === type && t.text === msg)) {
          t.remove();
        }
      }
    }

    if (opts.onlyOne) {
      const alreadyExists = Vue.toasted.toasts.some(
        t => (opts.id && t.id === opts.id) || (t.type === type && t.text === msg),
      );

      if (alreadyExists) {
        console.log('[Toaster] Msg skipped as it already exists');
        return;
      }
    }

    return createToast(msg, type, options);
  }
}

function createToast(msg, type, options) {
  const toast = Vue.toasted.show(' ', { ...options, icon: undefined });

  toast.type = type;
  toast.id = options.id || getNextId();

  // create new sections
  const container = toast.el;

  const iconSpan = document.createElement('span');
  iconSpan.classList.add('icon');

  if (options.icon) {
    const iconPlaceholder = document.createElement('div');
    iconSpan.appendChild(iconPlaceholder);

    new Vue({ ...Icon, propsData: { icon: options.icon } }).$mount(iconPlaceholder);
  }

  const textSpan = document.createElement('span');
  textSpan.classList.add('text');
  textSpan.innerText = msg;

  container.prepend(textSpan);
  container.prepend(iconSpan);

  // override text changer
  toast._text = msg;
  Object.defineProperty(toast, 'text', {
    set: function(text) {
      toast._text = text;
      textSpan.innerText = text;
    },
    get: function() {
      return toast._text;
    },
  });

  return toast;
}
