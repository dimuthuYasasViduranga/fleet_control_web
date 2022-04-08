import xml2js from 'xml2js';
import { textFromFile } from '@/code/io';
import { downloadFromText } from './utils';

const KML_NOTES = [
  'There can be multiple <Placemarks> (ie paths) inside <Folder>',
  'Name is NOT required. Only helpful for initial grouping',
  [
    'Each Coordinate',
    ['longitude, latitude, altitude (ignored)', 'separated by a space, or a new line'],
  ],
];

const KML_EXAMPLE = `<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Folder>
    <name>ExampleRoute</name>
    <Placemark>
      <name>Path1</name>
      <LineString>
        <coordinates>
          123.7205534876523,-30.44881012724412,0
          123.7182599809588,-30.46251176326033,0
          123.6995482117065,-30.46224611771695,0
          123.6890886509589,-30.47900106787949,0
          123.6769162221561,-30.47935005053301,0
        </coordinates>
      </LineString>
    </Placemark>
    <Placemark>
      <name>Path2</name>
      <LineString>
        <coordinates>
          123.7182599809588,-30.46251176326033,0
          123.7253974206207,-30.46596882229109,0
          123.7358279039398,-30.45839562461387,0
        </coordinates>
      </LineString>
    </Placemark>
  </Folder>
</kml>`;

export function getDefinition() {
  return {
    type: 'kml',
    notes: KML_NOTES,
    extensions: ['.kml'],
    example: KML_EXAMPLE,
    download,
    parse: parseKML,
  };
}

function download() {
  downloadFromText(KML_EXAMPLE, 'kml-example.kml');
}

export function parseKML(file) {
  return textFromFile(file).then(xml2js.parseStringPromise).then(findPlacemarks);
}

function findPlacemarks(objOrArr, acc = []) {
  if (!objOrArr) {
    return acc;
  }

  if (Array.isArray(objOrArr)) {
    objOrArr.forEach(o => findPlacemarks(o, acc));
    return acc;
  }

  if (typeof objOrArr === 'object') {
    Object.entries(objOrArr).forEach(([key, value]) => {
      if (!value || typeof value !== 'object' || key === '$') {
        return;
      }

      if (key === 'Placemark') {
        value.forEach(pm => {
          const maybePlacemark = tryExtractFromPlacemark(pm);
          if (maybePlacemark) {
            acc.push(maybePlacemark);
          }
        });
      }

      findPlacemarks(value, acc);
    });
  }

  return acc;
}

function tryExtractFromPlacemark(placemark) {
  if (!placemark) {
    return;
  }

  const name = fetch(placemark, 'name') || 'Path';
  const lineString = fetch(placemark, 'LineString');
  const path = parseCoords(fetch(lineString, 'coordinates') || []);

  return {
    name,
    path,
  };
}

function fetch(obj, keys) {
  if (typeof keys === 'string') {
    keys = [keys];
  }
  return keys.reduce((acc, key) => {
    acc = acc?.[key];

    if (Array.isArray(acc)) {
      acc = acc[0];
    }

    return acc;
  }, obj);
}

function parseCoords(coords) {
  if (typeof coords === 'string') {
    coords = coords
      .replaceAll(' ', '\n')
      .split('\n')
      .filter(c => c);
  }
  return coords.reduce((acc, coord) => {
    const validCoord = parseCoord(coord);
    if (validCoord) {
      acc.push(validCoord);
    }
    return acc;
  }, []);
}

function parseCoord(coord) {
  try {
    const [lngStr, latStr] = coord.split(',');
    const lng = parseFloat(lngStr);
    const lat = parseFloat(latStr);

    if (!isNaN(lng) && !isNaN(lat)) {
      return { lat, lng };
    }
  } catch {}
}
