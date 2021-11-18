import Vue from 'vue';
const NOT_SUPPORTED = 'not supported';
const PERMISSION_DENIED = 'permission denied';

class Geolocation {
  constructor() {
    this._isAvailable = 'geolocation' in window.navigator;
    this._position = null;
    this._watchId = null;
  }

  get watching() {
    return !!this._watchId;
  }

  get position() {
    return this._position;
  }

  async get() {
    if (!this._isAvailable) {
      console.error('[Geolocation] not supported');
      return Promise.reject(NOT_SUPPORTED);
    }

    return requestPermission().then(() => {
      return new Promise((resolve, reject) => {
        window.navigator.geolocation.getCurrentPosition(
          pos => resolve(getPosition(pos)),
          e => reject(e),
        );
      });
    });
  }

  async watch() {
    if (!this._isAvailable) {
      console.error('[Geolocation] not supported');
      return Promise.reject(NOT_SUPPORTED);
    }

    return requestPermission().then(() => {
      console.log('[Geolocation] Watching location');
      return new Promise(resolve => {
        this._watchId = window.navigator.geolocation.watchPosition(
          pos => (this._position = getPosition(pos)),
          e => console.error(e),
        );

        resolve(true);
      });
    });
  }

  unwatch() {
    if (this._watchId) {
      console.log('[Geolocation] Unwatching location');
      window.navigator.geolocation.clearWatch(this._watchId);
      this._position = null;
      this._watchId = null;
      return true;
    }

    return false;
  }
}

function requestPermission() {
  return new Promise((resolve, reject) => {
    return navigator.permissions
      .query({ name: 'geolocation' })
      .then(resp => {
        if (resp.state === 'denied') {
          return reject(PERMISSION_DENIED);
        }

        resolve(true);
      })
      .catch(e => {
        console.error(e);
        reject(PERMISSION_DENIED);
      });
  });
}

function getPosition(pos) {
  return {
    position: {
      lat: pos.coords.latitude,
      lng: pos.coords.longitude,
      alt: pos.coords.altitude,
    },
    accuracy: {
      lat: pos.coords.accuracy,
      lng: pos.coords.accuracy,
      alt: pos.coords.altitudeAccuracy,
    },
  };
}

export default Vue.observable(new Geolocation());
