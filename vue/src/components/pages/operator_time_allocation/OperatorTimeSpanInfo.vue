<template>
  <div class="operator-time-span-info">
    <div class="info">
      <div class="operator-icon-wrap">
        <Icon class="operator-icon" :icon="userIcon" />
      </div>
      <div class="operator-name">{{ operatorName }}</div>
      <div class="summary">Summary</div>
    </div>
    <div class="chart-wrapper">
      <TimeSpanChart
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
      </TimeSpanChart>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import TimeSpanChart from '../time_allocation/chart/TimeSpanChart.vue';
import { toOperatorTimeSpans, operatorStyler, operatorColors } from './operatorTimeSpans.js';

import UserIcon from '@/components/icons/Man.vue';
import { groupBy, uniq } from '@/code/helpers';
import { firstBy } from 'thenby';

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
          left: 60,
          right: 5,
          bottom: 30,
        },
        context: {
          top: 15,
          left: 60,
          right: 5,
          bottom: 30,
        },
      },
      contextHeight: 80,
    };
  },
  computed: {
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
  height: 400px;
  margin: 0 0.5rem;
}

.__tooltip-boundary {
  margin: 10px;
}
</style>