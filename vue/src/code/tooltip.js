let FSObserver = null;

export function startFullscreenObserver() {
  if (!FSObserver) {
    FSObserver = new FullscreenObserver();
  }
  return FSObserver;
}

class FullscreenObserver {
  constructor() {
    this.observer = new MutationObserver(handleMutions);
    document.addEventListener('fullscreenchange', () => this.onFullscreenChange(), true);
  }

  onFullscreenChange() {
    document.fullscreenElement ? this.addObserver() : this.removeObserver();
  }

  addObserver() {
    // move all existing tooltips from body to fullscreen
    const activeTooltips = getTooltipsInElement(document.body);
    activeTooltips.forEach(e => {
      try {
        document.fullscreenElement.appendChild(e);
      } catch {}
    });

    this.observer.observe(document.body, { subtree: false, childList: true, attributes: false });
  }

  removeObserver() {
    this.observer.disconnect();
  }
}

function handleMutions(mutations) {
  mutations.forEach(m => {
    m.addedNodes.forEach(n => {
      try {
        const role = n.attributes.getNamedItem('role') || {};
        if (role.nodeValue === 'tooltip') {
          document.fullscreenElement.appendChild(n);
        }
      } catch {}
    });
  });
}

function getTooltipsInElement(element) {
  return [...element.children].filter(
    e => e?.attributes?.getNamedItem('role')?.nodeValue === 'tooltip',
  );
}
