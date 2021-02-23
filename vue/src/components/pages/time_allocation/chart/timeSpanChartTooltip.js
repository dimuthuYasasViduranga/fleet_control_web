import * as d3 from 'd3';

export function getTooltipPosition(tooltip, selectedContext, chartSvg, dimensions) {
  const chartAbsOrigin = getAbsCoordOrigin(chartSvg);
  const chartWidth = chartSvg.node().clientWidth - dimensions.focus.right - dimensions.focus.left;

  const selectedSvg = d3
    .select(selectedContext)
    .node()
    .getBBox();

  const tooltipWidth = tooltip.node().clientWidth;
  const tooltipHeight = tooltip.node().clientHeight;

  // check if svg overflows chartspace
  const overflowingLeft = selectedSvg.x < 0;
  const overflowingRight = selectedSvg.x + selectedSvg.width > chartWidth;

  // calculate x position
  let selectedCenter = selectedSvg.x + selectedSvg.width / 2;
  if (overflowingLeft && overflowingRight) {
    selectedCenter = chartWidth / 2;
  } else if (overflowingLeft) {
    selectedCenter = (selectedSvg.x + selectedSvg.width) / 2;
  } else if (overflowingRight) {
    selectedCenter = (selectedSvg.x + chartWidth) / 2;
  }

  let x = chartAbsOrigin.x + selectedCenter - tooltipWidth / 2 + dimensions.focus.left;

  const availableSpaceRight = document.documentElement.clientWidth - x - tooltipWidth;
  if (availableSpaceRight < 0) {
    x += availableSpaceRight;
  }

  // calculate the y position
  const barHeight = selectedSvg.height;

  let y = chartAbsOrigin.y + selectedSvg.y + dimensions.focus.top;

  // if there is not enough space above
  const tooHigh = y - (window || {}).scrollY - tooltipHeight < 0;

  if (tooHigh) {
    y += barHeight;
  } else {
    y -= tooltipHeight;
  }

  return { x, y };
}

function getAbsCoordOrigin(element) {
  const coords = element.node().getBoundingClientRect();
  return {
    x: coords.x + (window || {}).scrollX,
    y: coords.y + (window || {}).scrollY,
  };
}

export function setTooltipPosition(tooltip, position) {
  tooltip.style('left', `${position.x}px`);
  tooltip.style('top', `${position.y}px`);
}
