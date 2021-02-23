require('nativescript-websockets');
const Phx = require('./phoenix');

export function create(deviceUUID, socketToken, hostname) {
  const wsHostname = hostname.replace(/^http/, 'ws');

  let socket = new Phx.Socket(`${wsHostname}/device-auth-socket`, {
    params: { token: socketToken },
    transport: WebSocket,
  });

  socket.onClose(() => {
    // on error, do not try and reconnect (used for when the token becomes invalid)
    socket.reconnectTimer.reset();
  });

  socket.connect();

  let channel = socket.channel(`device_auth:${deviceUUID}`, {});

  channel
    .join()
    .receive('ok', () => {
      console.log('[Auth Channel] Joined');
    })
    .receive('error', resp => {
      console.log('[Auth Channel] Unable to join', resp);
    });

  return channel;
}

export function destroy(channel) {
  console.log('[Auth Channel] Destroying');
  if (!channel) {
    return;
  }

  channel.leave();
  channel.socket.disconnect();
}
