import Vue from 'vue';

class Visibility {
  constructor() {
    this._hidden = false;
    addListeners(this);
  }

  get hidden() {
    return this._hidden;
  }
}

function addListeners(ctx) {
  const { hiddenTopic, visibilityTopic } = getTopics();

  document.addEventListener(
    visibilityTopic,
    () => {
      if (document.hidden == null) {
        ctx._hidden = document[hiddenTopic];
      } else {
        ctx._hidden = document.hidden;
      }
    },
    false,
  );
}

function getTopics() {
  if (typeof document.hidden !== 'undefined') {
    // Opera 12.10 and Firefox 18 and later support
    return { hiddenTopic: 'hidden', visibilityTopic: 'visibilitychange' };
  }

  if (typeof document.msHidden !== 'undefined') {
    return { hiddenTopic: 'msHidden', visibilityTopic: 'msvisibilitychange' };
  }

  if (typeof document.webkitHidden !== 'undefined') {
    return { hiddenTopic: 'webkitHidden', visibilityTopic: 'webkitvisibilitychange' };
  }

  return { hiddenTopic: 'hidden', visibilityTopic: 'visibilitychange' };
}

export const PageVisibility = Vue.observable(new Visibility());
