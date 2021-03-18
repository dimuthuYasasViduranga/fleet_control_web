import { DateTime } from 'luxon';
import LocalZone from 'luxon/src/zones/localZone.js';

const LOCAL_ZONE = new LocalZone().name;

function isValidTz(tz) {
  return DateTime.local().setZone(tz).isValid;
}

export class Timely {
  constructor() {
    this.siteZone = LOCAL_ZONE;
    this.localZone = LOCAL_ZONE;
    this.current = {
      timezone: LOCAL_ZONE,
      isSite: true,
      isLocal: true,
    };
  }

  /**
   * Set the current timezone. Can either be a valid timezone, 'local' or 'site'
   * @param {String} tz - a valid timezone
   * @return {Boolean} - success status on change
   */
  setCurrent(tz) {
    if (tz === 'local') {
      console.log(`[Timely] Current tz set to local (${LOCAL_ZONE})`);
      this.current = {
        timezone: LOCAL_ZONE,
        isSite: LOCAL_ZONE === this.siteZone,
        isLocal: false,
      };
      return true;
    }

    if (tz === 'site') {
      console.log(`[Timely] Current tz set to site (${this.siteZone})`);
      this.current = {
        timezone: this.siteZone,
        isSite: true,
        isLocal: this.siteZone === LOCAL_ZONE,
      };
      return true;
    }

    if (isValidTz(tz)) {
      console.log(`[Timely] Current tz set to ${tz}`);
      this.current = {
        timezone: tz,
        isSite: tz === LOCAL_ZONE,
        isLocal: tz === this.siteZone,
      };
      return true;
    }

    console.error(`[Timely] Unable to change timezone to ${tz} as it is invalid`);
    return false;
  }

  /**
   * Set the site equivalent timezone.
   * If the current timezone has isSite: true, the timezone will be automatically updated to the newly provided one
   * @param {String} tz - a valid timezone
   * @return {Boolean} - success status on change
   */
  setsiteZone(tz) {
    if (isValidTz(tz)) {
      console.log(`[Timely] Site timezone set to ${tz}`);
      this.siteZone = tz;

      if (this.current.isSite) {
        this.current.timezone = tz;
      }

      this.current = {
        timezone: this.current.timezone,
        isSite: tz === LOCAL_ZONE,
        isLocal: tz === this.siteZone,
      };
      return true;
    }

    console.error(`[Timely] Unable to update site timezone to ${tz} as it is invalid`);
    return false;
  }
}
