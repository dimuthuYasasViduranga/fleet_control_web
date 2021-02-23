import { TNSPlayer } from 'nativescript-audio';

export class AVPlayer {
  constructor() {
    this._player = new TNSPlayer();
    this._isPlaying = false;
  }

  playFile(path) {
    if (this._isPlaying === false) {
      const opts = {
        audioFile: path,
        loop: false,
        completeCallback: () => {
          this._isPlaying = false;
        },
        errorCallback: () => {
          this._isPlaying = false;
        },
      };

      this._isPlaying = true;
      return this._player.playFromFile(opts);
    }
  }

  playNotification() {
    return this.playFile('~/assets/audio/correct-sweet-louder.mp3');
  }

  playNewMessage() {
    return this.playFile('~/assets/audio/correct-sweet.mp3');
  }
}
