import { textFromFile } from '@/code/io';
import { downloadFromText, lowifyKeys } from './utils';

const CUSTOM_NOTES = [
  'Name is NOT required. Only helpful for initial grouping',
  ['Coordinates can be', ['(longitude, latitude)', '{lng | longitude, lat | latitude}']],
];

const CUSTOM_EXAMPLE = `[
  {
    "name": "Path1",
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
  },
  {
    "name": "Path2",
    "coordinates": [
      {
        "lng": 123.7182599809588,
        "lat": -30.46251176326033
      },
      {
        "lng": 123.7253974206207,
        "lat": -30.46596882229109
      },
      {
        "longitude": 123.7358279039398,
        "latitude": -30.45839562461387
      }
    ]
  }
]`;

export function getDefinition() {
  return {
    type: 'custom json',
    notes: CUSTOM_NOTES,
    extensions: ['.json'],
    example: CUSTOM_EXAMPLE,
    download,
    parse: parseCustomJson,
  };
}

function download() {
  return downloadFromText(CUSTOM_EXAMPLE, 'custom-json-example.json');
}

export function parseCustomJson(file) {
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

function findFeatures(arr) {
  if (!Array.isArray(arr)) {
    return [];
  }

  return arr.map(tryExtractFromFeature).filter(f => f);
}

function tryExtractFromFeature(feature) {
  if (!feature) {
    return;
  }

  const props = lowifyKeys(feature);

  const name = props?.name || 'Path';

  const path = (props?.coordinates || []).map(parseCoord);

  if (path.length < 2) {
    return;
  }

  return {
    name,
    path,
  };
}

function parseCoord(coord) {
  try {
    if (typeof coord === 'string') {
      coord = coord.split(',');
    }

    if (Array.isArray(coord)) {
      const [lngStr, latStr] = coord;
      const lng = parseFloat(lngStr);
      const lat = parseFloat(latStr);

      if (!isNaN(lng) && !isNaN(lat)) {
        return { lat, lng };
      }
    }

    const lat = coord.lat || coord.latitude;
    const lng = coord.lng || coord.longitude;

    if (!isNaN(lng) && !isNaN(lat)) {
      return { lat, lng };
    }
  } catch {}
}
