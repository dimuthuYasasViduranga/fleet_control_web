<template>
  <div class="pre-start-submissions">
    <hxCard title="Submissions" :icon="reportIcon">
      <PreStartReport
        v-for="submission in submissions"
        :key="submission.id"
        :submission="submission"
      />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import PreStartReport from './PreStartReport.vue';

import ReportIcon from '@/components/icons/Report.vue';
import { attributeFromList } from '@/code/helpers';

function toLocalSubmission(sub, assets, operators, icons) {
  const [assetName, assetType] = attributeFromList(assets, 'id', sub.assetId, ['name', 'type']);
  const operator = getOperator(operators, sub.operatorId, sub.employeeId);

  const icon = icons[assetType];
  return {
    id: sub.id,
    formId: sub.formId,
    assetId: sub.assetId,
    assetName,
    assetType,
    icon,
    employeeId: sub.employeeId,
    operatorId: operator.id,
    operatorName: operator.fullname,
    form: sub.form,
    comment: sub.comment,
    timestamp: sub.timestamp,
    serverTimestamp: sub.serverTimestamp,
  };
}

function getOperator(operators, operatorId, employeeId) {
  return (
    attributeFromList(operators, 'id', operatorId) ||
    attributeFromList(operators, 'employeeId', employeeId) ||
    {}
  );
}

export default {
  name: 'PreStartSubmissions',
  components: {
    hxCard,
    PreStartReport,
  },
  data: () => {
    return {
      reportIcon: ReportIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
      icons: state => state.icons,
    }),
    submissions() {
      return this.$store.state.preStartSubmissions.map(s =>
        toLocalSubmission(s, this.assets, this.operators, this.icons),
      );
    },
  },
};
</script>

<style>
</style>