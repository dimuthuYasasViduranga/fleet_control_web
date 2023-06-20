import d3 from './d3';

import { copyDate, setTimeZone, fromJSDate } from '@/code/time';
import { dedupBy, attributeFromList } from '@/code/helpers';

import { IrregularScaleBand, irregularAxisLeft } from './irregularScaleBand.js';

export function defaultStyle() {
  return {
    // regular styles
    fill: 'orange',
    opacity: 0.5,
    stroke: 'black',
    strokeWidth: 1,
    strokeOpacity: 1,
    // styles when selected (any can be set manually)
    // selectedFill: 'orange',
    selectedOpacity: 0.25,
    // selectedStroke: 'pruple',
    // selectedStrokeWidth: 10,
    // selectedStrokeOpacity: 1,
  };
}

function mergeStyle(base = {}, changes = {}) {
  return { ...base, ...changes };
}

export function matchesHighlighted(highlighted, group, timeSpan) {
  if (!highlighted) {
    return null;
  }

  return (
    highlighted.group === group &&
    highlighted.level === timeSpan.level &&
    highlighted.selection.startTime.getTime() === timeSpan.startTime.getTime()
  );
}

function parsePadding(padding) {
  if (!padding) {
    return [0, 0];
  }
  if (isNaN(padding)) {
    return [padding.top || 0, padding.bottom || 0];
  }
  return [padding, padding];
}

// makes a padding lookup for [group][level] = {yOffset, heightOffset}
function getGroupPaddings({ groups, padding }) {
  const [defaultTopPadding, defaultBottomPadding] = parsePadding(padding);
  const lookup = {};
  groups.forEach((g, groupIndex) => {
    const levels = g.subgroups.map(subgroup => {
      if (['string', 'number'].includes(typeof subgroup)) {
        return `${subgroup}`;
      }
      return subgroup.group;
    });

    const [groupTopPadding, groupBottomPadding] = parsePadding(g.padding);

    const maxIndex = levels.length - 1;
    const levelPadding = {};
    levels.forEach((level, index) => {
      let top = 0;
      let bottom = 0;
      if (index === 0) {
        bottom = groupTopPadding || defaultTopPadding;
      }

      if (index === maxIndex) {
        top = groupBottomPadding || defaultBottomPadding;
      }

      if (index === 0 && groupIndex === 0) {
        bottom = 0;
      }

      levelPadding[level] = { yOffset: top, heightOffset: bottom + top };
    });

    lookup[g.group] = levelPadding;
  });

  return lookup;
}

export function drawTimeline(
  chartId,
  region,
  props,
  timeSpans,
  layout,
  styleCallback = () => null,
) {
  props.svg.selectAll('.timespans').remove();

  const drawableGroups = layout.groups.map(g => g.group);
  const paddings = getGroupPaddings(layout);
  const drawableTimeSpans = timeSpans.filter(ts => drawableGroups.includes(ts.group)).map(ts => {
    const customStyle = styleCallback(ts, region);
    const style = mergeStyle(defaultStyle(), customStyle);
    return {
      ...ts,
      style,
    };
  });

  return (
    props.svg
      .append('g')
      .attr('class', 'timespans')
      // small translation so the y axis is not overlapped
      .attr('transform', 'translate(1, 0)')
      .attr('clip-path', `url(#${chartId}-clip)`)
      .selectAll()
      .data(drawableTimeSpans)
      .enter()
      .append('rect')
      .attr('class', d => `timespan timespan-${d.level}`)
      .attr('x', d => props.xScale(d.startTime))
      .attr('y', d => {
        let yOffset = 0;
        if (region === 'focus') {
          yOffset = paddings[d.group][`${d.level || 0}`].yOffset;
        }
        return props.yScale.toRange([d.group, d.level]).minPixel + yOffset;
      })
      .attr('height', d => {
        let heightOffset = 0;
        if (region === 'focus') {
          heightOffset = paddings[d.group][`${d.level || 0}`].heightOffset;
        }
        const height = props.yScale.toRange([d.group, d.level]).pixelWidth - heightOffset;
        return height < 1 ? 1 : height;
      })
      .attr('width', d => {
        const width = props.xScale(d.endTime || d.activeEndTime) - props.xScale(d.startTime);
        return width < 0 ? 0 : width;
      })
      .attr('fill', d => parseFill(d.style.fill))
      .attr('fill-opacity', d => d.style.opacity)
      .attr('stroke', d => d.style.stroke)
      .attr('stroke-opacity', d => d.style.strokeOpacity)
      .attr('stroke-width', d => d.style.strokeWidth)
  );
}

export function createChart(
  canvas,
  chartId,
  dimensions,
  timeSpans,
  colors,
  range,
  layout,
  onContextBrushEnd,
  timezone,
) {
  // create the overall svg area
  const svg = canvas
    .select(`#${chartId}`)
    .append('svg')
    .attr('class', 'timespan-chart')
    .attr('width', '100%')
    .attr('height', '100%');

  // create the scales (x axis needs to be redone once window is used)
  const xRange = calculateXRange(timeSpans, range);

  // create focus (main) and context (slicer) areas
  const focus = createFocusChart(svg, dimensions.focus, xRange, layout, timezone);
  const context = createContextChart(
    svg,
    dimensions.context,
    xRange,
    layout,
    onContextBrushEnd,
    timezone,
  );

  // create some defs (culling path and hatching)
  const defs = svg.append('defs');

  defs
    .append('clipPath')
    .attr('id', `${chartId}-clip`)
    .append('rect')
    .attr('width', focus.dimensions.width)
    .attr('height', focus.dimensions.height);

  createHatchings(defs, colors);

  return {
    svg,
    dimensions,
    defs,
    focus,
    context,
  };
}

function createHatchings(defs, colors) {
  const hatchingWdith = 5;
  const hatchingHeight = 10;

  for (const color of colors) {
    const hatching = defs
      .append('pattern')
      .attr('id', `hatch-${color}`)
      .attr('patternUnits', 'userSpaceOnUse')
      .attr('width', hatchingWdith)
      .attr('height', hatchingHeight)
      .attr('patternTransform', 'rotate(45)');

    hatching
      .append('rect')
      .attr('class', 'hatching-bg')
      .attr('width', hatchingWdith)
      .attr('height', hatchingHeight)
      .attr('fill', color);

    hatching
      .append('line')
      .attr('class', 'hatching-stroke')
      .attr('x1', 0)
      .attr('y1', 0)
      .attr('x2', 0)
      .attr('y2', hatchingHeight)
      .attr('stroke-width', 0.8)
      .attr('stroke', 'black');
  }
}

export function parseFill(fill) {
  if (!fill) {
    return fill;
  }

  const splits = fill.split('|');
  if (splits.length === 1) {
    return fill;
  }

  return `url(#${splits[0]}-${splits[1]})`;
}

function calculateXRange(timeSpans, range) {
  const [minTimestamp, maxTimestamp] = minMaxTimeSpans(timeSpans);

  return {
    min: copyDate(range.min || minTimestamp),
    max: copyDate(range.max || maxTimestamp),
  };
}

function minMaxTimeSpans(timeSpans) {
  const timestamps = timeSpans
    .map(a => [a.startTime, a.endTime || a.activeEndTime])
    .flat()
    .filter(a => a)
    .map(a => a.getTime());

  // sort ascending
  timestamps.sort((a, b) => a - b);

  const minTime = timestamps[0];
  const maxTime = timestamps[timestamps.length - 1];

  return [minTime, maxTime];
}

function removeSeconds(dateString) {
  if (!dateString) {
    return dateString;
  }

  const parts = dateString.split(':');

  if (parts.length > 2) {
    return parts.slice(0, 2).join(':');
  }

  return dateString;
}

function tickToDateFormatter(date, index, textElements, timezone = 'local') {
  const luxDate = setTimeZone(fromJSDate(date), timezone);
  const startOfDay = luxDate.startOf('day');
  const isStartOfDay = luxDate.equals(startOfDay);

  let format = 'HH:mm:ss';

  // if the last element, check for duplicates in elements
  if (index === textElements.length - 1) {
    const dateStrings = textElements
      .map((text, index) => ({
        index,
        short: removeSeconds(text.textContent),
        text: text.textContent,
      }))
      .filter(ds => ds.text);

    // dedup the strings
    const dedupedStrings = dedupBy(dateStrings, 'short');

    // if there are duplicates, clear everything except the first element, then make all other elements the short hand
    let textContent = 'text';
    if (dedupedStrings.length >= dateStrings.length) {
      textContent = 'short';
      format = 'HH:mm';
    }

    textElements.forEach((text, index) => {
      text.textContent = (dedupedStrings.find(ds => ds.index === index) || {})[textContent];
    });
  }

  return isStartOfDay ? luxDate.toFormat('LLL dd') : luxDate.toFormat(format);
}

function createFocusChart(svg, dimensions, xRange, layout, timezone) {
  // create scales
  const focusXScale = d3
    .scaleTime()
    .range([0, dimensions.width])
    .domain([xRange.min, xRange.max]);

  const focusYScale = new IrregularScaleBand(dimensions.height, 0, layout.groups);

  // attach axis
  const focusXAxis = d3.axisBottom(focusXScale);
  const focusYAxis = irregularAxisLeft(focusYScale);

  // create the chart area itself
  const focus = svg
    .append('g')
    .attr('class', 'timespan-focus')
    .attr('width', dimensions.width)
    .attr('height', 100)
    .attr('transform', `translate(${dimensions.x}, ${dimensions.y})`);

  // attach x-axis
  focus
    .append('g')
    .attr('class', 'axis axis--x')
    .attr('transform', `translate(0, ${dimensions.height})`)
    .call(
      focusXAxis.tickFormat((date, index, textElements) => {
        return tickToDateFormatter(date, index, textElements, timezone);
      }),
    );

  // attach y-axis
  if (layout.yAxis.show) {
    focus
      .append('g')
      .attr('class', 'axis axis--y')
      .attr('transform', `translate(0, 0)`)
      .call(
        focusYAxis.tickFormat(
          group => attributeFromList(layout.groups, 'group', group, 'label') || group,
        ),
      )
      .selectAll('text')
      .attr(
        'transform',
        `translate(${layout.yAxis.yOffset}, ${layout.yAxis.xOffset}) rotate(${
          layout.yAxis.rotation
        })`,
      );
  }

  return {
    svg: focus,
    dimensions,
    xAxis: focusXAxis,
    xScale: focusXScale,
    yScale: focusYScale,
  };
}

function createContextChart(svg, dimensions, xRange, layout, onContextBrushEnd, timezone) {
  // no dimensions === dont render
  if (!dimensions) {
    return null;
  }

  // create scales
  const contextXScale = d3
    .scaleTime()
    .range([0, dimensions.width])
    .domain([xRange.min, xRange.max]);

  const contextYScale = new IrregularScaleBand(dimensions.height, 0, layout.groups);

  const contextXAxis = d3.axisBottom(contextXScale);

  // create the chart area itself
  const context = svg
    .append('g')
    .attr('class', 'timespan-context')
    .attr('transform', `translate(${dimensions.x}, ${dimensions.y})`);

  // attach x-axis
  context
    .append('g')
    .attr('class', 'axis axis--x')
    .attr('transform', `translate(0, ${dimensions.height})`)
    .call(
      contextXAxis.ticks(6).tickFormat((date, index, textElements) => {
        return tickToDateFormatter(date, index, textElements, timezone);
      }),
    );

  // create a context brush
  const contextBrush = d3
    .brushX()
    .extent([[0, 0], [dimensions.width, dimensions.height]])
    .on('brush end', onContextBrushEnd);

  return {
    svg: context,
    dimensions,
    xAxis: contextXAxis,
    xScale: contextXScale,
    yScale: contextYScale,
    brush: contextBrush,
  };
}
