function flattenTree(subgroups = [], parent = {}) {
  if (['string', 'number'].includes(typeof subgroups[0])) {
    const percent = 1 / subgroups.length;
    const formedSubgroups = subgroups.map(name => {
      return {
        group: `${name}`,
        percent,
      };
    });
    return flattenTree(formedSubgroups, parent);
  }

  let movingOffset = parent.min || 0;

  return subgroups
    .map(group => {
      const parentWidth = parent.width || 1;
      const localWidth = group.percent || 1 / subgroups.length;
      const width = localWidth * parentWidth;
      const path = (parent.path || []).slice();
      path.push(group.group);

      const subgroup = {
        group: group.group,
        path,
        width,
        min: movingOffset,
        max: movingOffset + width,
      };
      movingOffset += width;
      return [subgroup].concat(flattenTree(group.subgroups, subgroup));
    })
    .flat();
}

function minMax(list) {
  return [Math.min(...list), Math.max(...list)];
}

function toLookup(roots, lowerBound, upperBound) {
  const lookup = {};
  const boundWidth = upperBound - lowerBound;

  flattenTree(roots)
    .flat()
    .map(e => {
      const [minPixel, maxPixel] = minMax([
        lowerBound + e.min * boundWidth,
        lowerBound + e.max * boundWidth,
      ]);

      return {
        ...e,
        minPixel,
        maxPixel,
        pixelWidth: maxPixel - minPixel,
      };
    })
    .forEach(e => (lookup[e.path.join('.')] = e));

  return lookup;
}

export class IrregularScaleBand {
  constructor(lowerBound, upperBound, scale) {
    this._lowerBound = lowerBound;
    this._upperBound = upperBound;
    this._scale = null;
    this._scaleLookup = {};
    this.setScale(scale);
  }

  scale(x) {
    return this.toRange(x);
  }

  setScale(scale) {
    this._scale = scale;
    this._scaleLookup = toLookup(scale, this._lowerBound, this._upperBound);
  }

  toRange(keys) {
    let accessor = keys;
    if (Array.isArray(keys)) {
      accessor = keys.map(k => k || 0).join('.');
    }
    return this._scaleLookup[accessor];
  }

  toDomain(pixel) {
    let longestKey = 0;
    let bestRange = null;
    Object.values(this._scaleLookup).forEach(range => {
      if (range.minPixel <= pixel && pixel < range.maxPixel && range.path.length > longestKey) {
        longestKey = range.path.length;
        bestRange = range;
      }
    });
    return bestRange;
  }

  domain() {
    return this._scale.map(d => d.group);
  }

  range() {
    return [this._lowerBound, this._upperBound];
  }

  copy() {
    return new IrregularScaleBand(this._lowerBound, this._upperBound, this._scale);
  }

  call(_svgElement, data) {
    return data;
  }
}

const slice = Array.prototype.slice;
function identity(x) {
  return x;
}

var top = 1,
  right = 2,
  bottom = 3,
  left = 4,
  epsilon = 1e-6;

function translateX(x) {
  return 'translate(' + (x + 0.5) + ',0)';
}

function translateY(y) {
  return 'translate(0,' + (y + 0.5) + ')';
}

function number(irregularScale) {
  return function(d) {
    const band = irregularScale.toRange(d);
    return band.minPixel + band.pixelWidth / 2;
  };
}

function center(scale) {
  var offset = Math.max(0, scale.bandwidth() - 1) / 2; // Adjust for 0.5px offset.
  if (scale.round()) offset = Math.round(offset);
  return function(d) {
    return +scale(d) + offset;
  };
}

function entering() {
  return !this.__axis;
}

function axis(orient, scale) {
  var tickArguments = [],
    tickValues = null,
    tickFormat = null,
    tickSizeInner = 6,
    tickSizeOuter = 6,
    tickPadding = 3,
    k = orient === top || orient === left ? -1 : 1,
    x = orient === left || orient === right ? 'x' : 'y',
    transform = orient === top || orient === bottom ? translateX : translateY;

  function axis(context) {
    var values =
        tickValues == null
          ? scale.ticks
            ? scale.ticks.apply(scale, tickArguments)
            : scale.domain()
          : tickValues,
      format =
        tickFormat == null
          ? scale.tickFormat
            ? scale.tickFormat.apply(scale, tickArguments)
            : identity
          : tickFormat,
      spacing = Math.max(tickSizeInner, 0) + tickPadding,
      range = scale.range(),
      range0 = +range[0] + 0.5,
      range1 = +range[range.length - 1] + 0.5,
      position = (scale.bandwidth ? center : number)(scale.copy()),
      selection = context.selection ? context.selection() : context,
      path = selection.selectAll('.domain').data([null]),
      tick = selection
        .selectAll('.tick')
        .data(values, scale)
        .order(),
      tickExit = tick.exit(),
      tickEnter = tick
        .enter()
        .append('g')
        .attr('class', 'tick'),
      line = tick.select('line'),
      text = tick.select('text');

    path = path.merge(
      path
        .enter()
        .insert('path', '.tick')
        .attr('class', 'domain')
        .attr('stroke', 'currentColor'),
    );

    tick = tick.merge(tickEnter);

    line = line.merge(
      tickEnter
        .append('line')
        .attr('stroke', 'currentColor')
        .attr(x + '2', k * tickSizeInner),
    );

    text = text.merge(
      tickEnter
        .append('text')
        .attr('fill', 'currentColor')
        .attr(x, k * spacing)
        .attr('dy', orient === top ? '0em' : orient === bottom ? '0.71em' : '0.32em'),
    );

    if (context !== selection) {
      path = path.transition(context);
      tick = tick.transition(context);
      line = line.transition(context);
      text = text.transition(context);

      tickExit = tickExit
        .transition(context)
        .attr('opacity', epsilon)
        .attr('transform', function(d) {
          return isFinite((d = position(d))) ? transform(d) : this.getAttribute('transform');
        });

      tickEnter.attr('opacity', epsilon).attr('transform', function(d) {
        var p = this.parentNode.__axis;
        return transform(p && isFinite((p = p(d))) ? p : position(d));
      });
    }

    tickExit.remove();

    path.attr(
      'd',
      orient === left || orient == right
        ? tickSizeOuter
          ? 'M' + k * tickSizeOuter + ',' + range0 + 'H0.5V' + range1 + 'H' + k * tickSizeOuter
          : 'M0.5,' + range0 + 'V' + range1
        : tickSizeOuter
        ? 'M' + range0 + ',' + k * tickSizeOuter + 'V0.5H' + range1 + 'V' + k * tickSizeOuter
        : 'M' + range0 + ',0.5H' + range1,
    );

    tick.attr('opacity', 1).attr('transform', function(d) {
      return transform(position(d));
    });

    line.attr(x + '2', k * tickSizeInner);

    text.attr(x, k * spacing).text(format);

    selection
      .filter(entering)
      .attr('fill', 'none')
      .attr('font-size', 10)
      .attr('font-family', 'sans-serif')
      .attr('text-anchor', orient === right ? 'start' : orient === left ? 'end' : 'middle');

    selection.each(function() {
      this.__axis = position;
    });
  }

  axis.scale = function(_) {
    return arguments.length ? ((scale = _), axis) : scale;
  };

  axis.ticks = function() {
    return (tickArguments = slice.call(arguments)), axis;
  };

  axis.tickArguments = function(_) {
    return arguments.length
      ? ((tickArguments = _ == null ? [] : slice.call(_)), axis)
      : tickArguments.slice();
  };

  axis.tickValues = function(_) {
    return arguments.length
      ? ((tickValues = _ == null ? null : slice.call(_)), axis)
      : tickValues && tickValues.slice();
  };

  axis.tickFormat = function(_) {
    return arguments.length ? ((tickFormat = _), axis) : tickFormat;
  };

  axis.tickSize = function(_) {
    return arguments.length ? ((tickSizeInner = tickSizeOuter = +_), axis) : tickSizeInner;
  };

  axis.tickSizeInner = function(_) {
    return arguments.length ? ((tickSizeInner = +_), axis) : tickSizeInner;
  };

  axis.tickSizeOuter = function(_) {
    return arguments.length ? ((tickSizeOuter = +_), axis) : tickSizeOuter;
  };

  axis.tickPadding = function(_) {
    return arguments.length ? ((tickPadding = +_), axis) : tickPadding;
  };

  return axis;
}

export function irregularAxisTop(scale) {
  return axis(top, scale);
}

export function irregularAxisRight(scale) {
  return axis(right, scale);
}

export function irregularAxisBottom(scale) {
  return axis(bottom, scale);
}

export function irregularAxisLeft(scale) {
  return axis(left, scale);
}