<template>
  <div class="pre-start-failures">
    <input type="checkbox" v-model="showLatestOnly" />Latest Only

    <div v-if="assetFailures.length === 0" class="no-failures">
      No {{ showLatestOnly ? 'recent' : ' ' }}failures to report
    </div>

    <div v-else class="failures">
      <PreStartFailure
        v-for="(asset, index) in assetFailures"
        :key="index"
        :assetName="asset.name"
        :icon="icons[asset.type]"
        :submissions="asset.failedSubmissions"
        @refresh="$emit('refresh', $event)"
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

function controlsWithResponses(controls, responses, ticketStatusTypes) {
  return controls.map(c => {
    const r = attributeFromList(responses, 'controlId', c.id) || {};

    const status = getResponseStatus(r, ticketStatusTypes);
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
      status,
    };
  });
}

function getResponseStatus(r, ticketStatusTypes) {
  if (r.answer === true) {
    return 'pass';
  }

  if (r.answer !== false) {
    return 'na';
  }

  if (r.ticket && r.ticket.activeStatus) {
    const status = attributeFromList(
      ticketStatusTypes,
      'id',
      r.ticket.activeStatus.statusTypeId,
      'name',
    );
    return (status || '').toLowerCase().replaceAll(' ', '-');
  }

  return 'fail';
}

function getAssetFailures(
  submissions,
  assets,
  operators,
  ticketStatusTypes,
  assetSubFilter = subs => subs,
) {
  const orderedSubmissions = submissions
    .slice()
    .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  const groupMap = groupBy(orderedSubmissions, 'assetId');

  return Object.entries(groupMap)
    .map(([assetIdStr, subs]) => {
      const assetId = parseInt(assetIdStr, 10);
      const asset = attributeFromList(assets, 'id', assetId) || {};
      return createAssetFailure(asset, assetSubFilter(subs), operators, ticketStatusTypes);
    })
    .filter(a => a.failedSubmissions.length)
    .sort((a, b) => (a.assetName || '').localeCompare(b.assetName || ''));
}

function createAssetFailure(asset, subs, operators, ticketStatusTypes) {
  const failedSubmissions = subs
    .map(s => {
      const responses = controlsWithResponses(getControls(s.form), s.responses, ticketStatusTypes);
      const failedControls = responses.filter(c => c.answer === false);
      const controlsWithComments = responses.filter(c => c.answer !== false && c.comment);
      return {
        id: s.id,
        submission: s,
        timestamp: s.timestamp,
        controls: failedControls.concat(controlsWithComments),
        comments: s.comment,
        operator: getOperator(operators, s.operatorId, s.employeeId),
        employeeId: s.employeeId,
      };
    })
    .filter(s => s.controls.length || !!s.comments);

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
      showLatestOnly: false,
    };
  },
  props: {
    submissions: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
  },
  computed: {
    ticketStatusTypes() {
      return this.$store.state.constants.preStartTicketStatusTypes;
    },
    assetFailures() {
      const filter = this.showLatestOnly ? s => [s[0]] : s => s;
      return getAssetFailures(
        this.submissions,
        this.assets,
        this.operators,
        this.ticketStatusTypes,
        filter,
      );
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