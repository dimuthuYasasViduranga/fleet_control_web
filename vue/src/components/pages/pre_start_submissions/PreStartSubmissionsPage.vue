<template>
  <div class="pre-start-submissions-page">
    <hxCard title="Submissions" :icon="reportIcon">
      <div class="modes">
        <button
          v-for="mode in timeModes"
          :key="mode.id"
          class="hx-btn"
          :class="{ highlight: mode.id === selectedTimeModeId }"
          @click="setTimeMode(mode.id)"
        >
          {{ mode.name }}
        </button>
      </div>

      <ShiftSelector
        v-if="selectedTimeModeId === 'shift'"
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

      <PreStartReports
        v-if="selectedModeId === 'submissions'"
        :submissions="submissions"
        :assets="assets"
        :icons="icons"
        :shift="shift"
        @refresh="onRefresh()"
      />
      <PreStartConcerns
        v-else-if="selectedModeId === 'concerns'"
        :submissions="submissions"
        :assets="assets"
        :operators="operators"
        :icons="icons"
        @refresh="onRefresh()"
      />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import ShiftSelector from '@/components/ShiftSelector.vue';
import PreStartReports from './PreStartReports.vue';
import PreStartConcerns from './PreStartConcerns.vue';

import ReportIcon from '@/components/icons/Report.vue';

import { parsePreStartSubmission } from '@/store/store';
import { attributeFromList } from '@/code/helpers';

function toLocalSubmission(submission, closedStatusTypeId) {
  const failures = submission.responses.filter(r => r.answer === false);

  const failuresWithoutTickets = failures.filter(r => !r.ticketId);

  const closedTickets = failures.filter(
    r => r.ticket && r.ticket.activeStatus.statusTypeId === closedStatusTypeId,
  );

  const openTickets = failures.filter(
    r => r.ticket && r.ticket.activeStatus.statusTypeId !== closedStatusTypeId,
  );

  return {
    ...submission,
    responseCounts: {
      failures: failures.length,
      failuresWithoutTickets: failuresWithoutTickets.length,
      closed: closedTickets.length,
      open: openTickets.length,
    },
  };
}

export default {
  name: 'PreStartSubmissionsPage',
  components: {
    hxCard,
    ShiftSelector,
    PreStartReports,
    PreStartConcerns,
  },
  data: () => {
    const timeModes = [
      { id: 'latest', name: 'Latest' },
      { id: 'shift', name: 'By Shift' },
    ];

    const modes = [
      { id: 'submissions', name: 'All Submissions' },
      { id: 'concerns', name: 'Concerns' },
    ];
    return {
      reportIcon: ReportIcon,
      timeModes,
      selectedTimeModeId: timeModes[0].id,
      modes,
      selectedModeId: modes[0].id,
      shift: null,
      fetchingData: false,
      shiftSubmissions: [],
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
    closedStatusTypeId() {
      return attributeFromList(
        this.$store.state.constants.preStartTicketStatusTypes,
        'name',
        'closed',
        'id',
      );
    },
    liveSubmissions() {
      return this.$store.state.currentPreStartSubmissions.map(s =>
        toLocalSubmission(s, this.closedStatusTypeId),
      );
    },
    submissions() {
      return this.selectedTimeModeId === 'latest' ? this.liveSubmissions : this.shiftSubmissions;
    },
  },
  methods: {
    setTimeMode(modeId) {
      this.selectedTimeModeId = modeId;
    },
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
        this.shiftSubmissions = [];
        this.$toaster[type](msg);
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

          this.shiftSubmissions = data.submissions.map(s =>
            toLocalSubmission(parsePreStartSubmission(s), this.closedStatusTypeId),
          );
        })
        .receive('error', resp => onError('error', resp.error))
        .receive('timeout', () => onError('noComms', 'Unable to fetch submissions'));
    },
  },
};
</script>

<style scoped>
.modes {
  margin-bottom: 1rem;
}
.modes .hx-btn {
  min-width: 8rem;
  width: auto;
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