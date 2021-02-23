const Google = com.google.android.gms.maps;
const imageSourceModule = require('tns-core-modules/image-source');
const BitmapFactory = require('nativescript-bitmap-factory');
const Color = require('tns-core-modules/color').Color;

export function defaultOps() {
  return {
    scale: 1,
    color: null,
    rate: 0.5,
  };
}

export function createBitmapDescriptor(path, options) {
  const { scale, color, rate, imgRotation } = { ...defaultOps(), ...options };
  const nativeColor = toColor(color);
  // maybe use the color module here to get the right format

  // load the image
  const image = imageSourceModule.fromFile(path);

  if (scale === 1 && nativeColor === null) {
    return imageToDescriptor(image);
  }

  // make it mutable
  const mutableImage = BitmapFactory.makeMutable(image);

  // manipulate the image
  return BitmapFactory.asBitmap(mutableImage).dispose(b => {
    let bAltered = colorShiftBitmap(b, nativeColor, rate);

    if (imgRotation) {
      bAltered = bAltered.rotate(imgRotation)
    }

    bAltered = scaleBitmap(bAltered, scale);
    return imageToDescriptor(bAltered.toImageSource());
  });
}

function imageToDescriptor(image) {
  const bitmap = image.android;
  return Google.model.BitmapDescriptorFactory.fromBitmap(bitmap);
}

function scaleBitmap(bmp, scale) {
  if (!scale || scale === 1) {
    return bmp;
  }

  const height = bmp.size.height;
  const newHeight = Math.trunc(height * scale);
  return bmp.resizeHeight(newHeight);
}

function colorShiftBitmap(bmp, color, rate = 1) {
  if (!color) {
    return bmp;
  }

  const { width, height } = bmp.size;

  for (let i = 0; i < width; i++) {
    for (let j = 0; j < height; j++) {
      const point = { x: i, y: j };
      const pixel = bmp.getPoint(point);
      const blendedColor = blendARGB(pixel, color, rate);
      bmp.setPoint({ x: i, y: j }, blendedColor);
    }
  }

  return bmp;
}

export function toColor(a, r, g, b) {
  try {
    if (a === undefined || a === null) {
      return null;
    }

    // 'something, opacity'
    if (r !== undefined && g === undefined) {
      return setOpacity(toColor(a), r);
    }

    // 'green' '#332'
    if (typeof a === 'string') {
      return new Color(a);
    }

    if (typeof a === 'object') {
      return new Color(a.a, a.r, a.g, a.b);
    }

    // 'a, r, g, b'
    if (
      a !== undefined &&
      r !== undefined &&
      g !== undefined &&
      b !== undefined
    ) {
      return new Color(a, r, g, b);
    }
  } catch (error) {
    console.error(error);
    return null;
  }
}

export function setOpacity(color, opacity) {
  const alpha = Math.trunc(mapRange(opacity, [0, 1], [0, 255]));
  return new Color(alpha, color.r, color.g, color.b);
}

function mapRange(a, [a1, a2], [b1, b2]) {
  const num = (a - a1) * (b2 - b1);
  const den = a2 - a1;
  const b = b1 + num / den;
  return b;
}

function combineColors(val1 = 0, val2 = 0, rate) {
  return Math.trunc((val2 - val1) * rate) + val1;
}

function blendARGB(argb1, argb2, rate) {
  return {
    a: argb1.a || 0,
    r: combineColors(argb1.r, argb2.r, rate) || 0,
    g: combineColors(argb1.g, argb2.g, rate) || 0,
    b: combineColors(argb1.b, argb2.b, rate) || 0,
  };
}
