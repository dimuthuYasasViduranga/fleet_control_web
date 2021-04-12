<template>
  <div class="operator-time-span-info">
    <div class="info">
      <div class="operator-icon-wrap">
        <Icon class="operator-icon" :icon="userIcon" />
      </div>
      <div class="operator-name">{{ operatorName }}</div>
      <table class="summary">
        <tr>
          <th class="key">Ready</th>
          <td class="value">{{ formatDuration(summary.Ready) }}</td>
        </tr>
        <tr>
          <th class="key">Process</th>
          <td class="value">{{ formatDuration(summary.Process) }}</td>
        </tr>
        <tr>
          <th class="key">Standby</th>
          <td class="value">{{ formatDuration(summary.Standby) }}</td>
        </tr>
        <tr>
          <th class="key">Down</th>
          <td class="value">{{ formatDuration(summary.Down) }}</td>
        </tr>
        <tr v-if="summary.Unknown">
          <th class="key">Unknown</th>
          <td class="value">{{ formatDuration(summary.Unknown) }}</td>
        </tr>
        <tr>
          <th class="key">Off Asset</th>
          <td class="value">{{ formatDuration(summary['Off Asset']) }}</td>
        </tr>
      </table>
    </div>
    <div class="chart-wrapper">
      <TimeSpanChart
        v-if="allocations.length"
        :name="operatorId"
        :timeSpans="allTimeSpans"
        :layout="chartLayout"
        :margins="margins"
        :colors="timeSpanColors"
        :styler="timeSpanStyler"
        :minDatetime="rangeStart"
        :maxDatetime="rangeEnd"
        :contextHeight="contextHeight"
      >
        <template slot-scope="timeSpan">
          <div class="__tooltip-boundary">
            <OperatorTimeSpanTooltip :timeSpan="timeSpan" />
          </div>
        </template>
      </TimeSpanChart>
      <div v-else class="no-data">-- No Data --</div>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import TimeSpanChart from '../time_allocation/chart/TimeSpanChart.vue';
import OperatorTimeSpanTooltip from './OperatorTimeSpanTooltip.vue';
import { toOperatorTimeSpans, operatorStyler, operatorColors } from './operatorTimeSpans.js';

import UserIcon from '@/components/icons/Man.vue';
import { groupBy, uniq } from '@/code/helpers';
import { firstBy } from 'thenby';
import { formatSeconds } from '@/code/time';

const NO_ASSET = 'No Asset';

function getChartLayoutGroups(timeSpansByAsset) {
  const count = timeSpansByAsset.length;
  const percent = count === 0 ? 1 : 1 / count;
  return timeSpansByAsset
    .map(asset => {
      return {
        group: asset.assetName,
        label: asset.assetName,
        percent,
        subgroups: uniq(asset.timeSpans.map(ts => ts.level || 0)),
      };
    })
    .reverse();
}

function getAllocsByAsset(allocations) {
  return Object.values(groupBy(allocations, 'assetId'))
    .map(allocs => {
      const first = allocs[0];

      return {
        assetName: first.assetName || NO_ASSET,
        allocations: allocs,
      };
    })
    .sort(firstBy('assetName'));
}

export default {
  name: 'OperatorTimeSpanInfo',
  components: {
    Icon,
    TimeSpanChart,
    OperatorTimeSpanTooltip,
  },
  props: {
    operatorId: { type: [String, Number] },
    operatorName: { type: String, default: '' },
    allocations: { type: Array, default: () => [] },
    rangeStart: { type: Date },
    rangeEnd: { type: Date },
  },
  data: () => {
    return {
      userIcon: UserIcon,
      margins: {
        focus: {
          top: 15,
          left: 100,
          right: 5,
          bottom: 30,
        },
        context: {
          top: 15,
          left: 100,
          right: 5,
          bottom: 30,
        },
      },
      contextHeight: 80,
    };
  },
  computed: {
    summary() {
      const summary = {
        Ready: 0,
        Standby: 0,
        Process: 0,
        Down: 0,
        Unknown: 0,
        'Off Asset': 0,
      };

      this.allocations.forEach(alloc => {
        const duration = alloc.endTime.getTime() - alloc.startTime.getTime();
        const key = !alloc.assetId ? 'Off Asset' : alloc.timeCodeGroup || 'Unknown';
        summary[key] += duration;
      });
      return summary;
    },
    timeSpanColors() {
      return operatorColors();
    },
    timeSpansByAsset() {
      return getAllocsByAsset(this.allocations).map(asset => {
        return {
          assetName: asset.assetName,
          timeSpans: toOperatorTimeSpans(asset.allocations, asset.assetName),
        };
      });
    },
    allTimeSpans() {
      return this.timeSpansByAsset.map(a => a.timeSpans).flat();
    },
    chartLayout() {
      const groups = getChartLayoutGroups(this.timeSpansByAsset);

      return {
        groups,
        padding: 5,
        yAxis: {
          rotation: 0,
          yOffset: 0,
          xOffset: 0,
        },
      };
    },
  },
  methods: {
    timeSpanStyler(timeSpan, region) {
      return operatorStyler(timeSpan, region);
    },
    formatDuration(ms) {
      const seconds = Math.trunc(ms / 1000);

      if (!seconds) {
        return '--';
      }
      return formatSeconds(seconds);
    },
  },
};
</script>

<style>
.operator-time-span-info {
  text-align: center;
  display: flex;
  width: 100%;
  border-bottom: 0.05rem solid #677e8c;
  margin: 2rem 0;
}

.operator-time-span-info .info {
  width: 12rem;
}

.operator-time-span-info .info .summary {
  width: 100%;
  table-layout: fixed;
}

.operator-time-span-info .info .summary tr {
  height: 1.5rem;
}

.operator-time-span-info .info .operator-name {
  font-size: 1.25rem;
  text-decoration: underline;
  padding-bottom: 0.5rem;
}

.operator-time-span-info .info .operator-icon {
  width: 100%;
  height: 3rem;
  margin-bottom: 0.25rem;
}

.operator-time-span-info .chart-wrapper {
  transition: width 0.2s, height 0.2s;
  width: 100%;
  height: 300px;
  margin: 0 0.5rem;
}

.operator-time-span-info .chart-wrapper .no-data {
  width: 100%;
  height: 100%;
  font-size: 1.25rem;
  font-style: italic;
  color: gray;
  padding-top: 120px;
}

.operator-time-span-info .axis--y .tick {
  font-size: 1rem;
}

.__tooltip-boundary {
  margin: 10px;
}
</style>