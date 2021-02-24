<template>
  <div class="pre-start-submissions-page">
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

      <div v-if="selectedModeId === 'submissions'">
        <PreStartReport
          v-for="(group, index) in groupedSubmissions"
          :key="index"
          :submission="group.first"
          :otherSubmissions="group.others"
          :assets="assets"
          :icons="icons"
        />
      </div>
      <PreStartFailures
        v-else-if="selectedModeId === 'failures'"
        :submissions="localSubmissions"
        :assets="assets"
        :operators="operators"
        :icons="icons"
      />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import ShiftSelector from '@/components/ShiftSelector.vue';
import PreStartReport from './PreStartReport.vue';
import PreStartFailures from './PreStartFailures.vue';

import ReportIcon from '@/components/icons/Report.vue';

import { attributeFromList, groupBy } from '@/code/helpers';
import { toUtcDate } from '@/code/time';
import { parsePreStartSubmission } from '@/store/store';

export default {
  name: 'PreStartSubmissionsPage',
  components: {
    hxCard,
    ShiftSelector,
    PreStartReport,
    PreStartFailures,
  },
  data: () => {
    const modes = [
      { id: 'submissions', name: 'All Submissions' },
      { id: 'failures', name: 'Failures' },
    ];
    return {
      reportIcon: ReportIcon,
      modes,
      selectedModeId: modes[1].id,
      shift: null,
      fetchingData: false,
      localSubmissions: [],
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
    groupedSubmissions() {
      const groupMap = groupBy(this.localSubmissions, 'assetId');
      const groups = Object.values(groupMap).map(subs => {
        // descending
        subs.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
        const first = subs[0];
        const assetName = attributeFromList(this.assets, 'id', first.assetId, 'name');

        return {
          assetName,
          first,
          others: subs.slice(1),
        };
      });

      groups.sort((a, b) => a.assetName.localeCompare(b.assetName));
      return groups;
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
        this.localSubmissions = [];
        this.$toasted.global[type](msg);
      };

      const payload = {
        ref_id: shift.id,
        start_time: shift.startTime,
        end_time: shift.endTime,
      };

      this.$channel
        .push('pre-start:get submissions', payload)
        .receive('ok', data => {
          this.fetchingData = false;

          if (data.ref_id !== shift.id) {
            console.error('[PreStart Submissions] Received wrong shift');
            return;
          }

          this.localSubmissions = data.submissions.map(parsePreStartSubmission);
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