// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":

require('nativescript-websockets');
const Phx = require('./phoenix');

function copyDate(date) {
  if (!date) {
    return null;
  }

  return new Date(date);
}

const onJoin = (channel, extension, topic, initParams = {}) => {
  return resp => {
    console.log(`[Channel|${extension}:${topic}] Joined`, resp);
    channel.push('get device state', initParams).receive('ok', (initParams = {}));
  };
};

function create(hostname, extension, topic, deviceUUID, operatorToken, connectType) {
  const wsHostname = hostname.replace(/^http/, 'ws');

  let socket = new Phx.Socket(`${wsHostname}/${extension}`, {
    params: { operator_token: operatorToken },
    transport: WebSocket,
    // logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data) }
  });

  socket.connect();

  // Now that you are connected, you can join channels with a topic:
  let channel = socket.channel(`${topic}:${deviceUUID}`, {});

  // there are cleared on successful login
  const initParams = { connect: connectType };

  channel
    .join()
    .receive('ok', onJoin(channel, extension, topic, initParams))
    .receive('error', resp => {
      console.log(`[Channel|${extension}:${topic}] Unable to join`, resp);
    });

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

function setInboundDebugging(channel, mode) {
  if (mode === 'debug') {
    channel.onMessage = (event, payload) => {
      const message = `[Channel|in] event: ${event}`;
      console.log(message);
      return payload;
    };
  }

  if (mode === 'debug-full') {
    channel.onMessage = (event, payload) => {
      console.dir({ event, payload, at: new Date() });
      return payload;
    };
  }
}

class PushFailure {
  constructor() {}

  receive(status, callback) {
    if (status === 'error') {
      callback({ reason: 'Channel does not exist' });
    }
    return this;
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
    this._monitor = () => null;
  }

  get isAlive() {
    return this._isAlive;
  }

  get lastConnectedAt() {
    return this._lastConnectedAt;
  }

  get lastDisconnectedAt() {
    return this._lastDisconnectedAt;
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
    };
  }

  registerMonitor(callback = () => null) {
    this._monitor = callback;
  }

  create(hostname, extension, topic, deviceUUID, operatorToken, connectType) {
    this.destroy();
    const channel = create(hostname, extension, topic, deviceUUID, operatorToken, connectType);

    setInboundDebugging(channel, this.mode);
    this._setOutboundDebugging();

    this._monitor('created', this.getInfo());

    this._isAlive = true;
    this._channel = channel;
  }

  _setOutboundDebugging() {
    switch (this._mode) {
      case 'debug':
        this.push = this._debuggingPush;
        break;
      case 'debug-full':
        this.push = this._fullDebuggingPush;
        break;
    }
  }

  destroy() {
    this._isAlive = false;
    this._lastDisconnectedAt = new Date();
    this._isConnected = false;

    if (!this._channel) {
      console.log('[Channel] No channel to destroy');
      return;
    }

    console.log('[Channel] Destroying channel');
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

  setOnConnect(callback) {
    this._channel.on('set device state', payload => {
      console.log('[Channel] connected');
      this._lastConnected = new Date();
      this._isConnected = true;
      this._monitor('connected', this.getInfo());
      callback(payload);
    });
  }

  setOnError(callback) {
    this._channel.onError(() => {
      console.error('[Channel] Error');
      this._onDisconnect();
      callback();
    });
  }

  setOnClose(callback) {
    this._channel.onClose(() => {
      console.error('[Channel] Closed');
      this._onDisconnect();
      callback();
    });
  }

  _onDisconnect() {
    if (this._isConnected) {
      this._isConnected = false;
      this._lastDisconnectedAt = new Date();
      this._monitor('disconnected', this.getInfo());
    }
  }

  push(event, payload, timeout) {
    if (this._channel) {
      return this._channel.push(event, payload, timeout);
    }
    return new PushFailure();
  }

  _debuggingPush(event, payload, timeout) {
    if (this._channel) {
      console.log(`[Channel|out] event: ${event}`);
      return this._channel.push(event, payload, timeout);
    }
    console.error('[Channel|out] Unable to push at this time');
    return new PushFailure();
  }

  _fullDebuggingPush(event, payload, timeout) {
    if (this._channel) {
      console.log({ event, payload, at: new Date() });
      return this._channel.push(event, payload, timeout);
    }
    console.error('[Channel|out] Unable to push at this time');
    return new PushFailure();
  }
}
