const app = require('tns-core-modules/application');

export function ensureDisableSleep() {
  return new Promise(resolve => {
    disableSleep()
      .then(() => {
        resolve();
      })
      .catch(() => {
        setTimeout(() => {
          resolve(ensureDisableSleep());
        }, 500);
      });
  });
}

export function disableSleep() {
  return new Promise((resolve, reject) => {
    try {
      const activity = app.android.foregroundActivity || app.android.startActivity;
      if (activity) {
        const window = activity.getWindow();
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        console.log('[WakeLock] disabled sleep');
        resolve();
      } else {
        throw new Error('[WakeLock] cannot get activity');
      }
    } catch (error) {
      console.error(error);
      reject(error);
    }
  });
}

export function allowSleep() {
  return new Promise((resolve, reject) => {
    try {
      const activity = app.android.foregroundActivity || app.android.startActivity;
      if (activity) {
        const window = activity.getWindow();
        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        console.log('[WakeLock] enabled sleep');
        resolve();
      } else {
        throw new Error('[WakeLock] cannot get activity');
      }
    } catch (error) {
      console.error(error);
      reject(error);
    }
  });
}
