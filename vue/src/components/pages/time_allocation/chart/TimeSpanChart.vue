<template>
  <div :id="id" class="time-span-chart-wrapper" v-resize="updateChart">
    <!-- the chart element that d3 accesses -->
    <div :id="chartId" class="time-span-chart" />

    <!-- the following is what is being dynamically created through createTooltip() -->
    <!-- <div :id="tooltipId" class="time-span-chart-tooltip">
      <div v-if="highlighted" class="time-span-chart-tooltip-wrapper">
        <slot v-bind="highlighted"> </slot>
      </div>
    </div> -->
  </div>
</template>

<script>
import Vue from 'vue';
import * as d3 from 'd3';

import { toTimeSpan } from '../timeSpan.js';
import { createChart, drawTimeline, defaultStyle, parseFill } from './timeSpanChart';
import SlotWrapper from './SlotWrapper.vue';
import { IrregularScaleBand } from './irregularScaleBand.js';
import { setTooltipPosition, getTooltipPosition } from './timeSpanChartTooltip.js';
import { attributeFromList } from '../../../../code/helpers';

const TOOLTIP_LIFE = 5 * 1000;
const DEFAULT_Y_AXIS = {
  show: true,
  rotation: 0,
  xOffset: 0,
  yOffset: 0,
};

function randChartName() {
  return `time-timeline-${Math.trunc(Math.random() * 10000)}`;
}

function defaultMargins() {
  return {
    focus: {
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
    },
    context: {
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
    },
  };
}

function aboveZero(value) {
  return value < 0 ? 0 : value;
}

function parseMargin(margin) {
  if (!margin) {
    return {
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
    };
  }

  return {
    top: aboveZero(margin.top || 0),
    left: aboveZero(margin.left || 0),
    right: aboveZero(margin.right || 0),
    bottom: aboveZero(margin.bottom || 0),
  };
}

function getContextDimensions(height, width, contextHeight, margins) {
  if (!contextHeight) {
    return null;
  }

  const dimensions = {
    height: aboveZero(contextHeight - margins.top - margins.bottom),
    width: aboveZero(width - margins.left - margins.right),
    x: margins.left,
    y: height - contextHeight + margins.top,
  };

  return { ...dimensions, ...margins };
}

function getFocusDimensions(availableHeight, width, margins) {
  const dimensions = {
    height: aboveZero(availableHeight - margins.top - margins.bottom),
    width: aboveZero(width - margins.left - margins.right),
    x: margins.left,
    y: margins.top,
  };

  return { ...dimensions, ...margins };
}

function moveTooltip(component, tooltip, selection, chartSvg, dimensions) {
  // position is called twice because the div does not have a size until rendred
  component.$nextTick(() => {
    setTooltipPosition(tooltip, getTooltipPosition(tooltip, selection, chartSvg, dimensions));
    component.$nextTick(() => {
      setTooltipPosition(tooltip, getTooltipPosition(tooltip, selection, chartSvg, dimensions));
    });
  });
}

function applySelectedStyles(element, styles) {
  element
    .attr('fill', parseFill(styles.selectedFill || styles.fill))
    .attr('fill-opacity', styles.selectedOpacity || styles.opacity)
    .attr('stroke', styles.selectedStroke || styles.stroke)
    .attr('stroke-opacity', styles.selectedStrokeOpacity || styles.strokeOpacity)
    .attr('stroke-width', styles.selectedStokeWidth || styles.strokeWidth);
}

function applyStandardStyles(element, styles) {
  element
    .attr('fill', parseFill(styles.fill))
    .attr('fill-opacity', styles.opacity)
    .attr('stroke', styles.stroke)
    .attr('stroke-opacity', styles.strokeOpacity)
    .attr('stroke-width', styles.strokeWidth);
}

function createTooltip(id, slots, parent, onEnterCallback = () => null) {
  const existingTooltip = document.body.children.namedItem(id);
  if (existingTooltip) {
    return d3.select(`#${id}`);
  }

  // dynamically create a div and attach a component to it
  // the component takes in the slots passed in
  const tooltip = document.createElement('div');
  tooltip.id = id;
  document.body.appendChild(tooltip);
  const instance = new Vue({
    ...SlotWrapper,
    propsData: {
      id,
      parent,
      onEnterCallback,
    },
  });

  instance.$scopedSlots = slots;

  instance.$mount(`#${id}`);

  return d3.select(`#${id}`);
}

function removeTooltip(tooltip) {
  if (tooltip) {
    tooltip.remove();
  }
}

function parseLayout(custom = {}) {
  const yAxis = custom.yAxis || {};

  return {
    groups: custom.groups || [],
    padding: custom.padding || 0,
    yAxis: { ...DEFAULT_Y_AXIS, ...yAxis },
  };
}

// -------------------- new functions ------------------

export default {
  name: 'TimeSpanChart',
  components: {
    SlotWrapper,
  },
  props: {
    name: { type: String, default: randChartName() },
    timeSpans: { type: Array, default: () => [] },
    layout: { type: Object, default: () => ({}) },
    colors: { type: Array, default: () => [] },
    styler: { type: Function, default: () => defaultStyle() },
    margins: { type: Object, default: () => defaultMargins() },
    contextHeight: { type: Number, default: 0 },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
  },
  data: () => {
    return {
      chart: null,
      dimensions: {
        margin: null,
        height: null,
        width: null,
        innerHeight: null,
        innerWidth: null,
        focusHeight: null,
        contextHeight: null,
      },
      tooltip: null,
      tooltipExpiry: null,
      brushMin: null,
      brushMax: null,
      highlighted: null,
    };
  },
  computed: {
    id() {
      return `time-span-chart-${this.name}`.replace(' ', '_');
    },
    chartId() {
      return `${this.id}-chart`;
    },
    tooltipId() {
      return `${this.id}-tooltip`;
    },
    canvas() {
      return d3.select(`#${this.id}`);
    },
    hasTooltipSlot() {
      return !!this.$scopedSlots.default;
    },
    chartLayout() {
      return parseLayout(this.layout);
    },
    timezone() {
      return this.$timely.current.timezone;
    },
  },
  watch: {
    margin() {
      this.updateChart();
    },
    timeSpans: {
      deep: true,
      handler(newTimeSpans) {
        this.updateChart();
      },
    },
    name() {
      this.updateChart();
    },
    chartLayout() {
      this.updateChart();
    },
    styler() {
      this.updateChart();
    },
    contextHeight() {
      this.updateChart();
    },
    timezone() {
      this.updateChart();
    },
  },
  mounted() {
    this.updateChart();
  },
  beforeDestroy() {
    removeTooltip(this.tooltip);
  },
  methods: {
    getExpiringTooltip() {
      // set a timeout to kill the tooltip
      clearTimeout(this.tooltipExpiry);
      this.tooltipExpiry = setTimeout(() => {
        if (this.highlighted) {
          this.getExpiringTooltip();
          return;
        }

        removeTooltip(this.tooltip);
        this.tooltip = null;
      }, TOOLTIP_LIFE);

      this.tooltip =
        this.tooltip ||
        createTooltip(this.tooltipId, this.$scopedSlots, this, () => {
          removeTooltip(this.tooltip);
          this.tooltip = null;
        });
      return this.tooltip;
    },
    clearChart() {
      this.canvas.selectAll('svg').remove();
    },
    updateChart() {
      // update chart area dimensions
      const canvasDiv = this.canvas.node();

      // get overall dimensions
      const height = canvasDiv.clientHeight;
      const width = canvasDiv.clientWidth;

      // calculate margins
      const focusMargin = parseMargin(this.margins.focus);
      const contextMargin = parseMargin(this.margins.context);

      // calculate dimensions
      const contextHeight = this.contextHeight;
      const availableHeight = contextHeight ? height - contextHeight : height;

      const contextDimensions = getContextDimensions(height, width, contextHeight, contextMargin);
      const focusDimensions = getFocusDimensions(availableHeight, width, focusMargin);

      const dimensions = {
        height,
        width,
        focus: focusDimensions,
        context: contextDimensions,
      };

      this.dimensions = dimensions;

      // clear the chart and draw a new one

      this.clearChart();
      const range = { min: this.minDatetime, max: this.maxDatetime };
      const chart = createChart(
        this.canvas,
        this.chartId,
        this.dimensions,
        this.timeSpans,
        this.colors,
        range,
        this.chartLayout,
        () => this.onContextBrushEnd(chart),
        this.timezone,
      );

      this.chart = chart;
      this.drawChart();
    },
    drawChart() {
      this.drawFocusTimeline();
      this.drawContextTimeline();
    },
    drawFocusTimeline() {
      if (!this.chart) {
        console.error('[TimeSpanChart] cannot draw focus at this time');
        return;
      }

      const self = this;

      const focusArea = drawTimeline(
        this.chartId,
        'focus',
        this.chart.focus,
        this.timeSpans,
        this.chartLayout,
        this.styler,
      );

      focusArea
        .on('mouseenter', function (selection) {
          const highlighted = selection;
          self.$emit('entered', highlighted);
          self.highlighted = highlighted;

          applySelectedStyles(d3.select(this), selection.style);

          if (self.hasTooltipSlot) {
            const tooltip = self.getExpiringTooltip();
            moveTooltip(self, tooltip, this, self.chart.svg, self.dimensions);
          }
        })
        .on('mouseleave', function (selectionLeft) {
          self.highlighted = null;
          applyStandardStyles(d3.select(this), selectionLeft.style);
        })
        .on('click', selected => {
          self.$emit('select', selected);
        });
    },
    drawContextTimeline() {
      if (!this.contextHeight) {
        return;
      }

      if (!this.chart || !this.chart.context) {
        console.error('[TimeSpanChart] cannot draw context at this time');
        return;
      }

      const context = this.chart.context;
      drawTimeline(this.chartId, 'context', context, this.timeSpans, this.chartLayout, this.styler);

      // brush always drawn last so that it is over the top of context
      const brushRange = this.getCurrentBrushRange();
      context.svg
        .append('g')
        .attr('class', 'brush')
        .call(context.brush)
        .call(context.brush.move, brushRange)
        .call(gBrush =>
          gBrush.select('.selection').on('mousedown', function () {
            if (this.clicked) {
              gBrush.call(context.brush.move, [0, 0]);
            } else {
              this.clicked = true;
              setTimeout(() => (this.clicked = false), 200);
            }
          }),
        );
    },
    getCurrentBrushRange() {
      if (!this.chart || !this.brushMin || !this.brushMin) {
        return null;
      }

      const xScale = this.chart.context.xScale;
      return [xScale(this.brushMin), xScale(this.brushMax)];
    },
    onContextBrushEnd(chart) {
      this.highlighted = null;
      if (!chart || (d3.event.sourceEvent && d3.event.sourceEvent.type === 'zoom')) {
        return; // ignore brush-by-zoom
      }

      const { focus, context } = chart;

      // the selection is in pixels
      const selection = d3.event.selection || context.xScale.range();
      const domain = selection.map(context.xScale.invert, context.xScale);
      const maxDomain = context.xScale.domain();
      if (
        maxDomain[0].getTime() === domain[0].getTime() &&
        maxDomain[1].getTime() === domain[1].getTime()
      ) {
        this.brushMin = null;
        this.brushMax = null;
      } else {
        this.brushMin = domain[0];
        this.brushMax = domain[1];
      }

      focus.xScale.domain(domain);
      focus.svg.select('.axis--x').call(focus.xAxis);

      this.drawFocusTimeline();
    },
  },
};
</script>

<style>
.time-span-chart-wrapper {
  width: 100%;
  height: 100%;
}

.time-span-chart {
  width: 100%;
  height: 100%;
}

.time-span-chart .axis {
  user-select: none;
}

.time-span-chart-tooltip {
  position: absolute;
  min-width: 1rem;
  width: auto;
  height: auto;
  z-index: 10000;
}

.time-span-chart-tooltip-wrapper {
  font-family: 'GE Inspira Sans', sans-serif;
  background-color: transparent;
  color: #b6c3cc;
}

.time-span-chart-wrapper .timespan {
  cursor: pointer;
}
</style>