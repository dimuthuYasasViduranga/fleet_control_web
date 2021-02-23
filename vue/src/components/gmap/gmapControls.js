export function createBar(extraClasses) {
  // Creates a bar to be inserted into a google map
  let controlBar = document.createElement('div');
  controlBar.classList.add('g-control-bar');
  if (extraClasses) {
    controlBar.classList.add(extraClasses);
  }

  return controlBar;
}

export function addButton(bar, value, onclick, extraClasses) {
  // create button element
  let button = document.createElement('span');

  // add classes
  button.classList.add('g-control');
  if (extraClasses) {
    extraClasses.forEach(c => button.classList.add(c));
  }

  // Add attributes
  button.innerText = value;
  button.onclick = onclick;

  // Add to bar
  bar.appendChild(button);
  return button;
}

export function pinBar(map, google, bar, position) {
  // used to pin the given bar to a google maps reference
  map.controls[google.maps.ControlPosition[position]].push(bar);
}

export function attachControl(map, google, selector, position) {
  const element = document.querySelector(selector);

  if (!element) {
    console.log(`[GControl] Could not attach element for selector '${selector}'`);
    return;
  }

  const control = document.createElement('div');
  control.classList.add('g-control');
  control.setAttribute('g-position', position);
  control.appendChild(element);

  map.controls[google.maps.ControlPosition[position]].push(control);
}
