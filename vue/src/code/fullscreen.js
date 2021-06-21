export function isElementFullscreen() {
  return !!(
    document.msFullscreenElement ||
    document.webkitFullscreenElement ||
    document.mozFullScreenElement ||
    document.msFullscreenElement
  );
}

export function requestFullscreen(element) {
  if (element.requestFullscreen) {
    return element.requestFullscreen();
  } else if (element.webkitRequestFullScreen) {
    return element.webkitRequestFullScreen();
  } else if (element.mozRequestFullScreen) {
    return element.mozRequestFullScreen();
  } else if (element.msRequestFullScreen) {
    return element.msRequestFullScreen();
  }
  return Promise.reject();
}

export function exitFullscreen() {
  if (document.exitFullscreen) {
    return document.exitFullscreen();
  } else if (document.webkitExitFullscreen) {
    return document.webkitExitFullscreen();
  } else if (document.mozCancelFullScreen) {
    return document.mozCancelFullScreen();
  } else if (document.msCancelFullScreen) {
    return document.msCancelFullScreen();
  }
  return Promise.reject();
}
