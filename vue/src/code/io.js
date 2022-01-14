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
