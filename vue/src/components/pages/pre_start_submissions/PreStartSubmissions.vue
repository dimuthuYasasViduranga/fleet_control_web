<template>
  <div class="pre-start-submissions">
    <hxCard title="Submissions" :icon="reportIcon">
      <ShiftSelector
        :value="shift"
        :shifts="shifts"
        :shiftTypes="shiftTypes"
        :disabled="fetchingData"
        @change="onShiftChange"
        @refresh="onRefresh"
      />
      <div class="modes">
        <button
          v-for="mode in modes"
          :key="mode.id"
          class="hx-btn"
          :class="{ highlight: mode.id === selectedModeId }"
          @click="setMode(mode.id)"
        >
          {{ mode.name }}
        </button>
      </div>
      <!-- <PreStartReport
        v-for="submission in submissions"
        :key="submission.id"
        :submission="submission"
      /> -->
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import ShiftSelector from '@/components/ShiftSelector.vue';
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
    ShiftSelector,
  },
  data: () => {
    const modes = [
      { id: 'submissions', name: 'All Submissions' },
      { id: 'failures', name: 'Failures' },
    ];
    return {
      reportIcon: ReportIcon,
      modes,
      selectedModeId: modes[0].id,
      shift: null,
      fetchingData: false,
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
      shifts: state => state.shifts,
      shiftTypes: state => state.shiftTypes,
      icons: state => state.icons,
    }),
    submissions() {
      return this.$store.state.preStartSubmissions.map(s =>
        toLocalSubmission(s, this.assets, this.operators, this.icons),
      );
    },
  },
  methods: {
    setMode(modeId) {
      this.selectedModeId = modeId;
    },
    onShiftChange(shift) {
      this.shift = shift;
      this.fetchSubmissionsByShift(shift);
    },
    onRefresh() {
      this.fetchSubmissionsByShift(this.shift);
    },
    fetchSubmissionsByShift(shift) {
      if (!shift) {
        console.error('[PreStart Submissions] No shift to fetch from');
        this.fetchingData = false;
        return;
      }

      this.fetchingData = true;

      const onError = (type, msg) => {
        this.fetchingData = false;
        // clear data here
        this.$toasted.global[type](msg);
      };

      this.$channel
        .push('pre-start:get submissions', shift.id)
        .receive('ok', data => {
          console.dir(data);
          this.fetchingData = false;

          // if (shift.id !== data.shift.id) {
          //   console.error('[PreStart Submissions] Received wrong shift');
          //   return;
          // }
        })
        .receive('error', resp => onError('error', resp.error))
        .receive('timeout', () => onError('noComms', 'Unable to fetch submissions'));
    },
  },
};
</script>

<style scoped>
.modes {
  display: flex;
  width: 100%;
}

.modes .hx-btn {
  width: 100%;
  margin-left: 0.05rem;
  border: 1px solid transparent;
}

.modes .hx-btn.highlight {
  background-color: #2c404c;
  border: 1px solid #898f94;
}

.modes .hx-btn:first-child {
  margin-left: 0;
}
</style>