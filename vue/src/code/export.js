export function downloadFromText(text, nameWithExtension) {
  const extension = nameWithExtension.split('.').pop();
  const content = encodeURI(`data:text/${extension};charset=utf-8,${text}`);
  downloadData(content, nameWithExtension);
}

function downloadData(content, nameWithExtension) {
  const link = document.createElement('a');
  link.setAttribute('href', content);
  link.setAttribute('download', nameWithExtension);

  // required for ff
  document.body.appendChild(link);
  link.click();
  link.remove();
}

export function isoDate(date) {
  if (!date) {
    return date;
  }

  return date.toISOString();
}
