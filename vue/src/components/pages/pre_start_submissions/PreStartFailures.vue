<template>
  <div class="pre-start-failures">
    <div v-if="failures.length === 0" class="no-failures">No failures to report</div>

    <div v-else class="failures">
      <PreStartFailure
        v-for="(failure, index) in failures"
        :key="index"
        :assetName="failure.assetName"
        :icon="failure.icon"
        :submissions="failure.submissions"
      />
    </div>
  </div>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import { attributeFromList, groupBy } from '@/code/helpers';
import { formatDateIn } from '@/code/time';

import PreStartFailure from './PreStartFailure.vue';

function getControls(form) {
  return form.sections.map(s => s.controls).flat();
}

function getFailCount(form) {
  return getControls(form).filter(c => c.answer === false).length;
}

function getOperator(operators, operatorId, employeeId) {
  return (
    attributeFromList(operators, 'id', operatorId) ||
    attributeFromList(operators, 'employeeId', employeeId) ||
    {}
  );
}

export default {
  name: 'PreStartFailures',
  components: {
    hxCard,
    PreStartFailure,
  },
  props: {
    submissions: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
  },
  computed: {
    failures() {
      const failedSubs = this.submissions.filter(s => getFailCount(s.form) > 0);
      const groupMap = groupBy(failedSubs, 'assetId');

      const groups = Object.entries(groupMap).map(([assetIdStr, submissions]) => {
        const asset = attributeFromList(this.assets, 'id', parseInt(assetIdStr, 10)) || {};

        const subs = submissions.map(s => {
          const failedControls = getControls(s.form).filter(c => c.answer === false);
          return {
            id: s.id,
            submission: s,
            timestamp: s.timestamp,
            controls: failedControls,
            operator: getOperator(this.operators, s.operatorId, s.employeeId),
            employeeId: s.employeeId,
          };
        });
        subs.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());

        return {
          assetName: asset.name,
          icon: this.icons[asset.type],
          submissions: subs,
        };
      });

      groups.sort((a, b) => a.assetName.localeCompare(b.assetName));
      return groups;
    },
  },
};
</script>

<style>
.pre-start-failures {
  padding-bottom: 1rem;
}

.pre-start-failures .no-failures {
  padding: 2rem 0;
  font-size: 1.5rem;
  font-style: italic;
  text-align: center;
}

.pre-start-failures .pre-start-failure .submissions {
  max-width: 70rem;
  margin: auto;
}
</style>