import Vue from 'vue';
import VueSimpleContextMenu from 'vue-simple-context-menu';
import 'vue-simple-context-menu/dist/vue-simple-context-menu.css';

class ContextMenu {
  constructor() {
    this._instances = {};
  }

  removeAll() {
    Object.values(this.instances).forEach(v => {
      destroyContext(v.instance);
      v.resolve();
    });
    this._instances = {};
  }

  remove(id) {
    const elementId = `context-menu-${id}`;
    const existing = this._instances[elementId];
    if (existing) {
      destroyContext(existing.instance);
      delete this._instances[elementId];
    }
  }

  create(id, mouseEvent, items, opts = {}) {
    if (!id) {
      console.error('[CM] Unable to create context menu without an id');
      return;
    }

    const elementId = `context-menu-${id}`;

    // destory the instance if it already exists
    const existing = this._instances[elementId];

    if (existing) {
      destroyContext(existing.instance);
      if (opts.toggle) {
        this.remove(id);
        return Promise.resolve();
      }
    }

    // create the context menu element mounting
    const contextDiv = document.createElement('div');
    document.body.appendChild(contextDiv);

    // create the context menu vue component
    const context = new Vue({
      ...VueSimpleContextMenu,
      propsData: { elementId, options: items },
    });

    setTimeout(() => context.showMenu(mouseEvent));

    const promise = new Promise(resolve => {
      // track the instance
      this._instances[elementId] = {
        instance: context,
        resolve,
      };
      // intercept on close events
      const onClose = resp => {
        destroyContext(context);
        delete this._instances[elementId];
        resolve(resp);
      };
      context.onClickOutside = () => onClose();
      context.onEscKeyRelease = keyEvent => {
        if (keyEvent.keyCode === 27) {
          onClose();
        }
      };
      context.$on('option-clicked', resp => onClose(resp.option));
    });

    // mount component
    context.$mount(contextDiv);

    return promise;
  }
}

function destroyContext(context) {
  if (context) {
    context.$destroy();
    context.$el.remove();
  }
}

export default new ContextMenu();
