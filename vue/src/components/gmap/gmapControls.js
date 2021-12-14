export function attachControl(map, google, selectorOrElement, position) {
  let element = getElement(selectorOrElement);

  if (!element) {
    console.log(`[GControl] Could not attach element for selector '${selectorOrElement}'`);
    return;
  }

  const control = document.createElement('div');
  control.classList.add('g-control');

  const parentClass = element.attributes.getNamedItem('parentClass');
  if (parentClass) {
    control.classList.add(parentClass.nodeValue);
  }

  control.setAttribute('g-position', position);
  control.appendChild(element);

  map.controls[google.maps.ControlPosition[position]].push(control);
}

function getElement(selectorOrElement) {
  if (typeof selectorOrElement === 'object') {
    return selectorOrElement.$el || selectorOrElement;
  }

  if (typeof selectorOrElement === 'string') {
    return document.querySelector(selectorOrElement);
  }

  return;
}
