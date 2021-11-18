class Geolocation {
  constructor() {
    this._isAvailable = 'geolocation' in window.navigator;
  }

  get() {
    if (!this._isAvailable) {
      return Promise.reject('Not supported');
    }

    return requestPermission().then(answer => {
      return new Promise((resolve, reject) => {
        if (answer !== false) {
          window.navigator.geolocation.getCurrentPosition(
            pos => resolve(getPosition(pos)),
            e => reject(e),
          );
          return;
        }

        return reject('permission denied');
      });
    });
  }

  watch() {}

  unwatch() {}
}

function requestPermission() {
  return navigator.permissions
    .query({ name: 'geolocation' })
    .then(resp => {
      console.dir(resp);
      if (resp.state === 'granted') {
        return true;
      }

      if (resp.state === 'denied') {
        return false;
      }

      return undefined;
    })
    .catch(e => {
      console.error(e);
      return undefined;
    });
}

function getPosition(pos) {
  return {
    lat: pos.coords.latitude,
    lng: pos.coords.longitude,
    alt: pos.coords.altitude,
    accuracy: {
      lat: pos.coords.accuracy,
      lng: pos.coords.accuracy,
      alt: pos.coords.altitudeAccuracy,
    },
  };
}

export default new Geolocation();
