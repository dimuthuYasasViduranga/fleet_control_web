class TitlerClass {
  constructor() {
    this._original = document.title;
  }

  change(title) {
    document.title = title;
  }

  reset() {
    document.title = this._original;
  }
}

export const Titler = new TitlerClass();
