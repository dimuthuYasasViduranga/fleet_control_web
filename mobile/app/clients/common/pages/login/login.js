import axios from 'axios';

const MAX_CONNECT_PERIOD = 10 * 1000;

function axiosPost(url, data, timeout = 4000) {
  const source = axios.CancelToken.source();

  // create a timeout
  const cancelTimer = setTimeout(() => {
    source.cancel(`Timeout of ${timeout}s`);
  }, timeout);

  const config = {
    cancelToken: source.token,
  };

  return axios
    .post(url, data, config)
    .then(response => {
      clearTimeout(cancelTimer);
      return success(response);
    })
    .catch(error => {
      if (axios.isCancel(error)) {
        return failure({ error: 'connection timeout' });
      }
      return failure(error);
    });
}

function success(result) {
  return new Promise(resolve => resolve(result));
}

function failure(result) {
  return new Promise((_resolve, reject) => reject(result));
}

function processError(error) {
  if (!error.response) {
    return error;
  }
  const resp = error.response;
  return { code: resp.status, error: statusToError(resp) };
}

function statusToError(resp) {
  switch (resp.status) {
    case 401:
      return { code: resp.status, error: '401 - Invalid Employee Id' };

    case 403:
      const reason = (resp.data || {}).error || 'Device Unauthorized';
      return { code: resp.status, error: `403 - ${reason}` };

    default:
      return { code: resp.status, error: `${resp.status} - ${resp.statusText}` };
  }
}

function connect(hostname, payload) {
  return axiosPost(`${hostname}/auth/operator_login`, payload, MAX_CONNECT_PERIOD)
    .then(({ data }) => {
      if (data && data.token) {
        return { token: data.token };
      }
      return data;
    })
    .catch(error => {
      return processError(error);
    });
}

export class LoginLooper {
  constructor(hostname) {
    this._hostname = hostname;
    this._activeAttempt = null;
  }

  connect(payload, opts = {}) {
    this.cancel();
    this._activeAttempt = new LoginAttempt(this._hostname);
    return this._activeAttempt.ensureConnect(payload, opts);
  }

  cancel(reason) {
    if (this._activeAttempt) {
      this._activeAttempt.cancel(reason);
    }
  }
}

class LoginAttempt {
  constructor(hostname) {
    this._hostname = hostname;
    this._reject = () => null;
    this.cancelled = false;
  }

  async ensureConnect(payload, opts = {}) {
    const maxAttempts = opts.maxAttempts || 30;
    let attempt = 1;

    return new Promise(async (resolve, reject) => {
      this._reject = reject;
      while (attempt < maxAttempts) {
        if (this.cancelled) {
          return;
        }
        console.log(`[Login Attempt] Attempt ${attempt}`);
        attempt += 1;

        const resp = await connect(
          this._hostname,
          payload,
        );

        if (resp) {
          if (resp.token) {
            resolve(resp);
            return;
          }

          if (resp.error !== 'connection timeout') {
            reject(resp);
            return;
          }
        }

        console.log('[Login Attempt] No connection, waiting');
        await new Promise(resolve => setTimeout(() => resolve(), MAX_CONNECT_PERIOD));
      }

      reject({ error: 'max attempts reached' });
    });
  }

  cancel(reason) {
    this.cancelled = true;
    this._reject({ cancelled: true, reason });
  }
}
