import axios from 'axios';

function fileReadBase(file, as) {
  return new Promise((resolve, reject) => {
    const fr = new FileReader();
    fr.onload = e => resolve(e.target.result);
    fr.onerror = e => reject(e);
    fr[as](file);
  });
}

export function textFromFile(file) {
  return fileReadBase(file, 'readAsText');
}

export function bufferArrayFromFile(file) {
  return fileReadBase(file, 'readAsArrayBuffer');
}

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

export function downloadCSV(name, keys, rows) {
  let csvContent = 'data:text/csv/csv;charset=utf-8,';
  csvContent += keys.join(',') + '\r\n';

  rows.forEach(row => {
    const encodedRow = keys.map(key => row[key]).join(',');
    csvContent += encodedRow + '\r\n';
  });

  const encodedURI = encodeURI(csvContent);

  const link = document.createElement('a');
  link.setAttribute('href', encodedURI);
  link.setAttribute('download', name);

  // required for firefox
  document.body.appendChild(link);
  link.click();
}
