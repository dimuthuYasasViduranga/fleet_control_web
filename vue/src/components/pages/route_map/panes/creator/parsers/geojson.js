import { textFromFile } from '@/code/io';
import { downloadFromText } from './utils';

const GEOJSON_NOTES = [
  'There can be multiple entries inside "FeatureCollections" or a list of "FeatureCollections"',
  'Name is NOT required. Only helpful for initial grouping',
  'Each coordinate is [longitude, latitude]',
  ['Accepted features', ['LineString', 'MultiLineString']],
];

const GEOJSON_EXAMPLE = `{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Path1"
      },
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [
            123.7205534876523,
            -30.44881012724412
          ],
          [
            123.7182599809588,
            -30.46251176326033
          ],
          [
            123.6995482117065,
            -30.46224611771695
          ],
          [
            123.6890886509589,
            -30.47900106787949
          ],
          [
            123.6769162221561,
            -30.47935005053301
          ]
        ]
      }
    },
    {
      "type": "Feature",
      "properties": {
        "name": "Path2"
      },
      "geometry": {
        "type": "MultiLineString",
        "coordinates": [
          [
            [
              123.7182599809588,
              -30.46251176326033
            ],
            [
              123.7253974206207,
              -30.46596882229109
            ]
          ],
          [
            [
              123.7253974206207,
              -30.46596882229109
            ],
            [
              123.7358279039398,
              -30.45839562461387
            ]
          ]
        ]
      }
    }
  ]
}`;

export function getDefinition() {
  return {
    type: 'geojson',
    notes: GEOJSON_NOTES,
    extensions: ['.geojson', '.json'],
    example: GEOJSON_EXAMPLE,
    download,
    parse: parseGeojson,
  };
}

function download() {
  return downloadFromText(GEOJSON_EXAMPLE, 'geojson-example.geojson');
}

function parseGeojson(file) {
  return textFromFile(file)
    .then(text => {
      const json = parseJSON(text);
      return json ? Promise.resolve(json) : Promise.reject('invalid json');
    })
    .then(findFeatures);
}

function parseJSON(text) {
  try {
    return JSON.parse(text);
  } catch {}
}

function findFeatures(objOrArr, acc = []) {
  if (!objOrArr) {
    return acc;
  }

  if (Array.isArray(objOrArr)) {
    objOrArr.forEach(o => findFeatures(o, acc));
    return acc;
  }

  if (typeof objOrArr === 'object') {
    Object.entries(objOrArr).forEach(([key, value]) => {
      if (key === 'features' && Array.isArray(value)) {
        value.forEach(v => {
          const maybeFeatureOrFeatures = tryExtractFromFeature(v);
          if (maybeFeatureOrFeatures) {
            if (Array.isArray(maybeFeatureOrFeatures)) {
              acc = acc.concat(maybeFeatureOrFeatures);
            } else {
              acc.push(maybeFeatureOrFeatures);
            }
          }
        });
      }

      findFeatures(value, acc);
    });
  }

  return acc;
}

function tryExtractFromFeature(feature) {
  if (!feature) {
    return;
  }

  const name = feature?.properties?.name || 'Path';

  const type = feature?.geometry?.type;

  const coords = feature?.geometry?.coordinates || [];

  if (!coords.length) {
    return;
  }

  if (type === 'LineString') {
    return parseLineString(name, coords);
  }

  if (type === 'MultiLineString') {
    return parseMultiLineString(name, coords);
  }
}

function parseLineString(name, coordinates) {
  const path = coordinates.map(parseCoord).filter(c => c);
  return { name, path };
}

function parseMultiLineString(name, coordinates) {
  return coordinates
    .map((c, index) => {
      const subName = `${name}-${index}`;
      return parseLineString(subName, c);
    })
    .filter(c => c.path.length);
}

function parseCoord(coord) {
  if (typeof coord === 'string') {
    coord = coord.split(',');
  }

  try {
    const [lngStr, latStr] = coord;
    const lng = parseFloat(lngStr);
    const lat = parseFloat(latStr);

    if (!isNaN(lng) && !isNaN(lat)) {
      return { lat, lng };
    }
  } catch {}
}
