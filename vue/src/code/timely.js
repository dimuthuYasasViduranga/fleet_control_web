import Vue from 'vue';
import { DateTime } from 'luxon';
import LocalZone from 'luxon/src/zones/localZone.js';

const LOCAL_ZONE = new LocalZone().name;

function isValidTz(tz) {
  if (!tz) {
    return false;
  }
  return DateTime.local().setZone(tz).isValid;
}

class Timely {
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
      console.log(`[Timely] Current tz set to local ${LOCAL_ZONE} (local)`);
      this.current = {
        timezone: LOCAL_ZONE,
        isSite: LOCAL_ZONE === this.siteZone,
        isLocal: true,
      };
      return true;
    }

    if (tz === 'site') {
      console.log(`[Timely] Current tz set to ${this.siteZone} (site)`);
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
        isSite: tz === this.siteZone,
        isLocal: tz === LOCAL_ZONE,
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
  setSiteZone(tz) {
    if (isValidTz(tz)) {
      console.log(`[Timely] Site timezone set to ${tz}`);
      this.siteZone = tz;

      if (this.current.isSite) {
        this.current.timezone = tz;
      }

      this.current = {
        timezone: this.current.timezone,
        isSite: tz === this.siteZone,
        isLocal: tz === LOCAL_ZONE,
      };
      return true;
    }

    console.error(`[Timely] Unable to update site timezone to ${tz} as it is invalid`);
    return false;
  }
}

export default Vue.observable(new Timely());
