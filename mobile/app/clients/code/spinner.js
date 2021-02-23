const LoadingIndicator = require('@nstudio/nativescript-loading-indicator')
  .LoadingIndicator;
const Mode = require('@nstudio/nativescript-loading-indicator').Mode;

const DEFAULT_OPTS = {
  dimBackground: true,
  color: '#007acc',
  userInteractionEnabled: false,
  mode: Mode.Indeterminate,
};

function copyOpts(options) {
  return JSON.parse(JSON.stringify(options));
}

function mergeOptions(opts1, opts2) {
  return { ...opts1, ...opts2 };
}

export class Spinner {
  constructor(defaultMsg, options) {
    this.spinner = new LoadingIndicator();
    this.isVisible = false;
    this.options = DEFAULT_OPTS;
    this.message = defaultMsg;

    this.setOptions(options);
  }

  get isOpen() {
    return this.isVisible;
  }

  show(message) {
    if (this.isVisible === true) {
      return;
    }
    this.isVisible = true;

    let opts = this.options;
    if (message !== undefined) {
      opts = mergeOptions(opts, { message });
    }
    try {
      this.spinner.show(opts);
    } catch (error) {
      console.error(error);
    }
  }

  hide() {
    this.isVisible = false;
    try {
      this.spinner.hide();
    } catch (error) {
      console.error(error);
    }
  }

  setMessage(message) {
    this.message = message;
  }

  setOptions(options) {
    const userOpts = copyOpts(options || {});
    const opts = { ...DEFAULT_OPTS, ...userOpts, ...{ message: this.message } };
    this.options = opts;
  }

  getOptions() {
    return this.options;
  }

  getMessage() {
    return this.message;
  }
}
