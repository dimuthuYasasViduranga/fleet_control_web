<template>
  <div class="pre-start-failures">
    Show All Failures <input type="checkbox" v-model="showAllFailures" />
    <div v-if="assetFailures.length === 0" class="no-failures">
      No {{ showAllFailures ? '' : 'recent ' }}failures to report
    </div>

    <div v-else class="failures">
      <PreStartFailure
        v-for="(asset, index) in assetFailures"
        :key="index"
        :assetName="asset.name"
        :icon="icons[asset.type]"
        :submissions="asset.failedSubmissions"
      />
    </div>
  </div>
</template>

<script>
import { attributeFromList, groupBy } from '@/code/helpers';

import PreStartFailure from './PreStartFailure.vue';

function getControls(form) {
  return form.sections.map(s => s.controls).flat();
}

function getOperator(operators, operatorId, employeeId) {
  return (
    attributeFromList(operators, 'id', operatorId) ||
    attributeFromList(operators, 'employeeId', employeeId) ||
    {}
  );
}

function controlsWithResponses(controls, responses) {
  return controls.map(c => {
    const r = attributeFromList(responses, 'controlId', c.id) || {};
    return {
      id: c.id,
      sectionId: c.id,
      responseId: r.id,
      order: c.order,
      label: c.label,
      answer: r.answer,
      comment: r.comment,
      ticketId: r.ticketId,
      ticket: r.ticket,
    };
  });
}

function getAssetFailures(submissions, assets, operators, assetSubFilter = subs => subs) {
  const orderedSubmissions = submissions
    .slice()
    .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  const groupMap = groupBy(orderedSubmissions, 'assetId');

  return Object.entries(groupMap)
    .map(([assetIdStr, subs]) => {
      const assetId = parseInt(assetIdStr, 10);
      const asset = attributeFromList(assets, 'id', assetId) || {};
      return createAssetFailure(asset, assetSubFilter(subs), operators);
    })
    .filter(a => a.failedSubmissions.length)
    .sort((a, b) => (a.assetName || '').localeCompare(b.assetName || ''));
}

function createAssetFailure(asset, subs, operators) {
  const failedSubmissions = subs
    .map(s => {
      const failedControls = controlsWithResponses(getControls(s.form), s.responses).filter(
        c => c.answer === false,
      );
      return {
        id: s.id,
        submission: s,
        timestamp: s.timestamp,
        controls: failedControls,
        operator: getOperator(operators, s.operatorId, s.employeeId),
        employeeId: s.employeeId,
      };
    })
    .filter(s => s.controls.length);

  return {
    name: asset.name,
    type: asset.type,
    failedSubmissions,
  };
}

export default {
  name: 'PreStartFailures',
  components: {
    PreStartFailure,
  },
  data: () => {
    return {
      showAllFailures: false,
    };
  },
  props: {
    submissions: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
  },
  computed: {
    assetFailures() {
      const filter = this.showAllFailures ? s => s : s => [s[0]];
      return getAssetFailures(this.submissions, this.assets, this.operators, filter);
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