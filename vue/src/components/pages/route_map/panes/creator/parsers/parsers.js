import * as kml from './kml';

export function getDefinitions() {
  return [kml.getDefinition()];
}

export async function parseFile(file, definitions) {
  const extension = `.${file.name.split('.').pop()}`;
  const relevantDefs = definitions.filter(d => d.extensions.includes(extension));
  for (let def of relevantDefs) {
    const parsedData = await def.parse(file);
    if (parsedData && parsedData.length > 0) {
      console.log(`[parser] File parsed as '${def.type}'`);
      return parsedData;
    }
  }

  return [];
}
