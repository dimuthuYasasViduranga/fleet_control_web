import * as application from 'tns-core-modules/application';
import { isAndroid } from 'tns-core-modules/platform';

import { Observable } from 'tns-core-modules/data/observable';

// this is used to obtain the serial number of the device. Painfull right
export class AndroidInterface extends Observable {
  constructor() {
    super();
    if (typeof android !== 'undefined') {
      let serialNumber = '';
      try {
        const cl = application.android.context.getClassLoader();
        const SystemProperties = cl.loadClass('android.os.SystemProperties');
        const paramTypes = Array.create(java.lang.Class, 2);
        paramTypes[0] = java.lang.String.class;
        paramTypes[1] = java.lang.String.class;
        const getMethod = SystemProperties.getMethod('get', paramTypes);
        const params = Array.create(java.lang.Object, 2);
        params[0] = new java.lang.String('ril.serialnumber');
        params[1] = new java.lang.String('unknown');
        serialNumber = getMethod.invoke(SystemProperties, params) || android.os.Build.SERIAL;
      } catch (err) {
        console.error(err);
      }
      this._serialNumber = serialNumber;
      this.set('serialNumber', serialNumber);
    }
  }

  getSerialNumber() {
    return this._serialNumber;
  }
}

export function disableModalCloseOutside(e) {
  if (isAndroid) {
    e.object._dialogFragment.getDialog().setCanceledOnTouchOutside(false);
  }
}
