<template>
  <div class="pre-start-submission-modal">
    <pre>{{ submission }}</pre>
  </div>
</template>

<script>
import { attributeFromList } from '@/code/helpers';
import { mapState } from 'vuex';

function getOperator(operators, operatorId, employeeId) {
  return (
    attributeFromList(operators, 'id', operatorId) ||
    attributeFromList(operators, 'employeeId', employeeId) ||
    {}
  );
}

export default {
  name: 'PreStartSubmissionModal',
  wrapperClass: 'pre-start-submission-modal-wrapper',
  props: {
    submission: { type: Object, required: true },
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
    }),
    asset() {
      return attributeFromList(this.assets, 'id', this.submission.assetId) || {};
    },
    operator() {
      return getOperator(this.operator, this.submission.operatorId, this.submission.employeeId);
    },
  },
};
</script>

<style>
.pre-start-submission-modal-wrapper .modal-container {
  max-width: 60rem;
}
</style>

<style>
</style>