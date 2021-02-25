<template>
  <div class="pre-start-reports">
    <div v-if="reports.length === 0" class="no-reports">No reports to show</div>
    <div class="reports">
      <PreStartReport
        v-for="(report, index) in reports"
        :key="index"
        :asset="report.asset"
        :submissions="report.submissions"
      />
    </div>
  </div>
</template>

<script>
import { attributeFromList, groupBy } from '@/code/helpers';
import PreStartReport from './PreStartReport.vue';
export default {
  name: 'PreStartReports',
  components: {
    PreStartReport,
  },
  props: {
    submissions: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
  },
  computed: {
    reports() {
      const groupMap = groupBy(this.submissions, 'assetId');
      const groups = Object.values(groupMap).map(subs => {
        // descending
        subs.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
        const first = subs[0];
        const asset = attributeFromList(this.assets, 'id', first.assetId);

        return {
          asset,
          submissions: subs,
        };
      });

      groups.sort((a, b) => a.asset.name.localeCompare(b.asset.name));
      return groups;
    },
  },
};
</script>

<style>
.pre-start-reports {
  padding-bottom: 1rem;
}

.pre-start-reports .no-reports {
  padding: 2rem 0;
  font-size: 1.5rem;
  font-style: italic;
  text-align: center;
}
</style>