const CHIME = require('@/assets/audio/chime.mp3');

class AVPlayerClass {
  constructor() {
    this._chime = new Audio(CHIME);
  }

  chime() {
    this._chime.play();
  }
}

export const AVPlayer = new AVPlayerClass();