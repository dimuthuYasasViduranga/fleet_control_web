import * as Geolocation from 'nativescript-geolocation';

function toDate(date) {
  if (!date) {
    return null;
  }
  return new Date(date);
}

function defaultOptions() {
  return {
    desiredAccuracy: 3,
    updateTime: 5 * 1000,
    callback: () => ({}),
  };
}

export class DeviceLocationMonitor {
  constructor(options = {}) {
    this._latitude = 0;
    this._longitude = 0;
    this._altitude = 0;
    this._horizontalAccuracy = 0;
    this._verticalAccuracy = 0;
    this._heading = 0;
    this._speed = 0;
    this._valid = false;
    this._timestamp = null;
    this._setOptions(options);
    this._watchId = null;
  }

  _setOptions(opts = {}) {
    this._options = { ...defaultOptions(), ...opts };
  }

  start(opts) {
    this._setOptions(opts);
    this._enable();
  }

  stop() {
    this._unwatch();
  }

  isActive() {
    return !!this._watchId;
  }

  _enable() {
    this._unwatch();
    Geolocation.isEnabled()
      .then(enabled => {
        if (enabled) {
          this._watch();
        } else {
          this._request();
        }
      })
      .catch(error => {
        console.error(error);
      });
  }

  _request() {
    Geolocation.enableLocationRequest()
      .then(() => {
        console.log('[LocationMonitor] Requesting location permission');
        this._watch();
      })
      .catch(error => {
        console.error('[LocationMonitor] failed to enable geolocation');
        console.error(error);
      });
  }

  _watch() {
    Geolocation.watchLocation(
      pos => {
        const newPos = this._setPosition(pos);
        this._options.callback(newPos);
      },
      e => {
        console.error('[LocationMonitor] failed to get location');
        console.error(e);
      },
      this._options,
    );
  }

  _unwatch() {
    if (this._watchId) {
      Geolocation.clearWatch(this._watchId);
      this._watchId = null;
    }
  }

  _setPosition(pos) {
    this._latitude = pos.latitude;
    this._longitude = pos.longitude;
    this._altitude = pos.altitude;
    this._horizontalAccuracy = pos.horizontalAccuracy;
    this._verticalAccuracy = pos.verticalAccuracy;
    this._speed = pos.speed;
    this._heading = pos.direction;
    this._valid = !!(pos.latitude && pos.longitude && pos.altitude);
    this._timestamp = toDate(pos.timestamp);

    return this.get();
  }

  get() {
    return {
      position: {
        lat: this._latitude,
        lng: this._longitude,
        alt: this._altitude,
      },
      velocity: {
        speed: this._speed,
        heading: this._heading,
      },
      accuracy: {
        horizontal: this._horizontalAccuracy,
        vertical: this._verticalAccuracy,
      },
      valid: this._valid,
      timestamp: toDate(this._timestamp),
    };
  }
}
