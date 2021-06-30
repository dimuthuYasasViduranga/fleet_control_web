<template>
  <div class="pre-start-concerns">
    <div><input type="checkbox" v-model="showLatestOnly" />Latest Only</div>

    <div v-if="assetConcerns.length === 0" class="no-concerns">
      No {{ showLatestOnly ? 'recent' : ' ' }}concerns to report
    </div>

    <div v-else class="concerns">
      <PreStartConcern
        v-for="(asset, index) in assetConcerns"
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

import PreStartConcern from './PreStartConcern.vue';

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

function getAssetConcerns(submissions, assets, operators, ticketStatusTypes, opts) {
  const orderedSubmissions = submissions
    .slice()
    .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  const groupMap = groupBy(orderedSubmissions, 'assetId');

  return Object.entries(groupMap)
    .map(([assetIdStr, subs]) => {
      const assetId = parseInt(assetIdStr, 10);
      const asset = attributeFromList(assets, 'id', assetId) || {};

      const filteredSubs = opts.latestOnly ? [subs[0]] : subs;

      return createAssetConcern(asset, filteredSubs, operators, ticketStatusTypes);
    })
    .filter(a => a.failedSubmissions.length)
    .sort((a, b) => (a.assetName || '').localeCompare(b.assetName || ''));
}

function createAssetConcern(asset, subs, operators, ticketStatusTypes) {
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
  name: 'PreStartConcerns',
  components: {
    PreStartConcern,
  },
  data: () => {
    return {
      showLatestOnly: true,
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
    assetConcerns() {
      const opts = {
        latestOnly: this.showLatestOnly,
      };
      return getAssetConcerns(
        this.submissions,
        this.assets,
        this.operators,
        this.ticketStatusTypes,
        opts,
      );
    },
  },
};
</script>

<style>
.pre-start-concerns {
  padding-bottom: 1rem;
}

.pre-start-concerns .no-concerns {
  padding: 2rem 0;
  font-size: 1.5rem;
  font-style: italic;
  text-align: center;
}

.pre-start-concerns .pre-start-concern .submissions {
  max-width: 70rem;
  margin: auto;
}

.pre-start-concerns input[type='checkbox'] {
  cursor: pointer;
}
</style>