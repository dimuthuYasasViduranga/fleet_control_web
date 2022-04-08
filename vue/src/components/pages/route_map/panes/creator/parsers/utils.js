import axios from 'axios';

export function downloadFromText(text, nameWithExtension) {
  const extension = nameWithExtension.split('.').pop();
  const content = `data:text/${extension};charset=utf-8,${text}`;

  const encodedURI = encodeURI(content);

  const link = document.createElement('a');
  link.setAttribute('href', encodedURI);
  link.setAttribute('download', nameWithExtension);

  // required for ff
  document.body.appendChild(link);
  link.click();
  link.remove();
}

export function downloadFromURL(url, mimeType, nameWithExtension) {
  axios
    .get(url, { responseType: 'blob', withCredentials: false })
    .then(resp => {
      const blob = new Blob([resp.data], { type: mimeType });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = nameWithExtension;

      // required for ff
      document.body.appendChild(link);

      link.click();
      URL.revokeObjectURL(link.href);
      link.remove();
    })
    .catch(console.error);
}

export function lowifyKeys(obj) {
  return Object.entries(obj).reduce((acc, [key, value]) => {
    const lKey = typeof key === 'string' ? key.toLowerCase() : key;
    acc[lKey] = value;
    return acc;
  }, {});
}

export function anyOf(obj, keys) {
  for (const key of keys) {
    if (obj[key]) {
      return obj[key];
    }
  }
}
