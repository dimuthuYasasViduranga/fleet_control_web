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

      <PreStartReports
        v-if="selectedModeId === 'submissions'"
        :submissions="localSubmissions"
        :assets="assets"
        :icons="icons"
        @refresh="onRefresh()"
      />
      <PreStartFailures
        v-else-if="selectedModeId === 'failures'"
        :submissions="localSubmissions"
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
import PreStartFailures from './PreStartFailures.vue';

import ReportIcon from '@/components/icons/Report.vue';

import { parsePreStartSubmission } from '@/store/store';
import { attributeFromList } from '@/code/helpers';
import { addJsDate } from '@/code/time';

const SHIFT_CROSSOVER_DURATION = 1 * 3600 * 1000; // 1 hour in ms

function toLocalSubmission(rawSub, closedStatusTypeId) {
  const submission = parsePreStartSubmission(rawSub);

  const failures = submission.responses.filter(r => r.answer === false);

  const failuresWithoutTickets = failures.filter(r => !r.ticketId);

  const closedTickets = failures.filter(
    r => r.ticket && r.ticket.activeStatus.statusTypeId === closedStatusTypeId,
  );

  const openTickets = failures.filter(
    r => r.ticket && r.ticket.activeStatus.statusTypeId !== closedStatusTypeId,
  );

  submission.responseCounts = {
    failures: failures.length,
    failuresWithoutTickets: failuresWithoutTickets.length,
    closed: closedTickets.length,
    open: openTickets.length,
  };

  return submission;
}

export default {
  name: 'PreStartSubmissionsPage',
  components: {
    hxCard,
    ShiftSelector,
    PreStartReports,
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
      selectedModeId: modes[0].id,
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
    closedStatusTypeId() {
      return attributeFromList(
        this.$store.state.constants.preStartTicketStatusTypes,
        'name',
        'closed',
        'id',
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
        this.localSubmissions = [];
        this.$toaster[type](msg);
      };

      const payload = {
        ref_id: shift.id,
        start_time: addJsDate(shift.startTime, -SHIFT_CROSSOVER_DURATION),
        end_time: addJsDate(shift.endTime, SHIFT_CROSSOVER_DURATION),
      };

      this.$channel
        .push('pre-start:get submissions', payload)
        .receive('ok', data => {
          this.fetchingData = false;

          if (data.ref_id !== shift.id) {
            console.error('[PreStart Submissions] Received wrong shift');
            return;
          }

          this.localSubmissions = data.submissions.map(s =>
            toLocalSubmission(s, this.closedStatusTypeId),
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