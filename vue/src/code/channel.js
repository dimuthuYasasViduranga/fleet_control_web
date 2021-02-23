// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in 'lib/my_app/endpoint.ex':

import { Socket, Presence } from 'phoenix';
import { copyDate } from './time';

function create(hostname, userToken, presenceSyncCallback) {
  // create socket
  const wsHostname = hostname.replace(/^http/, 'ws');

  const socket = new Socket(`${wsHostname}/dispatcher-socket`, {
    params: { token: userToken },
  });

  // join channel, setup presence
  const channel = socket.channel('dispatchers:all', {});
  const presence = new Presence(channel);
  presence.onSync(() => presenceSyncCallback(presence));

  // connect socket and return
  socket.connect();
  return channel;
}

function setChannelOns(channel, opts) {
  opts.forEach(([topic, callback]) => channel.on(topic, callback));
}

function parseMode(mode) {
  switch (mode) {
    case 'debug':
      return 'debug';
    case 'debug-full':
      return 'debug-full';
  }
  return 'normal';
}

function setDebugging(channel, mode, addMessage) {
  if (mode === 'debug') {
    channel.onMessage = (event, payload, ref) => {
      const message = `event: ${event}, ref: ${ref}`;
      addMessage(message);
      console.log(message);
      return payload;
    };
  }

  if (mode === 'debug-full') {
    channel.onMessage = (event, payload, ref) => {
      console.log(`event: ${event}, ref: ${ref}`);
      const message = { event, payload, ref, at: new Date() };
      addMessage(message);
      return payload;
    };
  }
}

class PushFailure {
  constructor() {}

  receive(status, callback) {
    if (status === 'error') {
      console.error('Channel does not exist to push on');
      callback({ reason: 'Channel does not exist' });
    }
  }
}

export class Channel {
  constructor(mode = 'normal') {
    this._mode = parseMode(mode);
    this._channel = null;
    this._isAlive = false;
    this._isConnected = false;
    this._lastConnectedAt = null;
    this._lastDisconnectedAt = null;
    this._log = [];

    this._monitor = () => null;
    this._onConnectCallback = () => null;
    this._onDisconnectCallback = () => null;
    this._onErrorCallback = () => null;
    this._onCloseCallback = () => null;
  }

  _addMessage(message) {
    const log = this._log.slice(0, 10);
    log.push(message);
    this._log = log;
    this._monitor('event', this.getInfo());
  }

  get isAlive() {
    return this._isAlive;
  }

  get lastConnectedAt() {
    return copyDate(this._lastConnectedAt);
  }

  get lastDisconnectedAt() {
    return copyDate(this._lastDisconnectedAt);
  }

  get mode() {
    return this._mode;
  }

  getInfo() {
    return {
      mode: this._mode,
      isAlive: this._isAlive,
      isConnected: this._isConnected,
      lastConnectedAt: copyDate(this._lastConnectedAt),
      lastDisconnectedAt: copyDate(this._lastDisconnectedAt),
      log: this._log,
    };
  }

  registerMonitor(callback = () => null) {
    this._monitor = callback;
  }

  create(hostname, userToken, presenceSyncCallback) {
    this.destroy();
    const channel = create(hostname, userToken, presenceSyncCallback);

    setDebugging(channel, this.mode, message => this._addMessage(message));

    this._monitor('created', this.getInfo());

    channel
      .join()
      .receive('ok', response => this._onConnect(response))
      .receive('error', resp => {
        this._onDisconnect();
        this._isConnected = false;
        console.error('[Channel] Cannot join', resp);
      });

    channel.onError(() => {
      if (this._mode !== 'normal') {
        console.error('[Channel] Error');
      }
      this._onDisconnect();
      this._onErrorCallback();
    });

    channel.onClose(() => {
      console.error('[Channel] Closed');
      this._onDisconnect();
      this._onCloseCallback();
    });

    this._isAlive = true;
    this._channel = channel;
  }

  join() {
    return this._channel.join();
  }

  destroy() {
    this._isAlive = false;
    this._lastDisconnectedAt = new Date();
    this._isConnected = false;

    if (!this._channel) {
      return;
    }

    console.log('[Destroying] Destroyed');
    this._channel.leave();
    this._channel.socket.disconnect();
    this._channel = null;
    this._monitor('destroyed', this.getInfo());
  }

  on(topic, callback) {
    this._channel.on(topic, callback);
  }

  setOns(opts) {
    setChannelOns(this._channel, opts);
  }

  setOnConnect(callback = () => null) {
    this._onConnectCallback = callback;
  }

  setOnDisconnect(callback = () => null) {
    this._onDisconnectCallback = callback;
  }

  setOnError(callback = () => null) {
    this._onErrorCallback = callback;
  }

  setOnClose(callback = () => null) {
    this._onCloseCallback = callback;
  }

  _onConnect(response) {
    console.log('[Channel] Connected');
    this._isConnected = true;
    this._lastConnectedAt = new Date();
    this._onConnectCallback(response);
    this._monitor('connected', this.getInfo());
  }

  _onDisconnect() {
    if (this._isConnected) {
      console.error('[Channel] Disconnected');
      this._isConnected = false;
      this._lastDisconnectedAt = new Date();
      this._onDisconnectCallback();
      this._monitor('disconnected', this.getInfo());
    }
  }

  push(event, payload = {}, timeout) {
    if (this._channel) {
      return this._channel.push(event, payload || {}, timeout);
    }
    return new PushFailure();
  }
}
