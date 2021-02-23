const application = require('tns-core-modules/application');
const traceModule = require('tns-core-modules/trace');

export function implementGlobals() {
  if (!global.process) {
    global.process = {
      restartOnError: false,
    };
  }
  if (!global.process.restart) {
    global.process.restart = function(msg) {
      if (global.android) {
        //noinspection JSUnresolvedFunction,JSUnresolvedVariable
        const mStartActivity = new android.content.Intent(
          application.android.context,
          application.android.startActivity.getClass(),
        );
        const mPendingIntentId = parseInt(Math.random() * 100000, 10);
        //noinspection JSUnresolvedFunction,JSUnresolvedVariable
        const mPendingIntent = android.app.PendingIntent.getActivity(
          application.android.context,
          mPendingIntentId,
          mStartActivity,
          android.app.PendingIntent.FLAG_CANCEL_CURRENT,
        );
        //noinspection JSUnresolvedFunction,JSUnresolvedVariable
        const mgr = application.android.context.getSystemService(
          android.content.Context.ALARM_SERVICE,
        );
        //noinspection JSUnresolvedFunction,JSUnresolvedVariable
        mgr.set(
          android.app.AlarmManager.RTC,
          java.lang.System.currentTimeMillis() + 100,
          mPendingIntent,
        );
        //noinspection JSUnresolvedFunction,JSUnresolvedVariable
        android.os.Process.killProcess(android.os.Process.myPid());
      } else if (global.ios) {
        this.exit(0);
      }
    };
  }
  if (!global.process.exit) {
    global.process.exit = function() {
      if (global.android) {
        application.android.foregroundActivity.finish();
      } else if (global.ios) {
        exit(0);
      }
    };
  }
}

function handleError(args) {
  console.error(`${args.error} ${args.ReferenceError}`);
  if (global.process.restartOnError) {
    global.process.restart();
  } else {
    console.error(`StackTrace: ${args.android.stackTrace}`);
    console.error(`NativeException: ${args.android.nativeException}`);
  }
}

export function setErrorHandler() {
  application.on(application.uncaughtErrorEvent, args => {
    handleError(args);
  });
}
