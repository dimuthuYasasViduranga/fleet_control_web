<template>
  <hxCard class="pre-start-report" :icon="icon">
    <div class="title-post" slot="title-post">
      <div class="submission-time">
        {{ asset.name }} ({{ formatTime(latestSubmission.timestamp) }})
      </div>
      <div class="status gap-left">
        <div v-if="latestSubmission.responseCounts.failuresWithoutTickets" class="failure">
          Fail
        </div>
        <div v-else-if="latestSubmission.responseCounts.open" class="open">Open Tickets</div>

        <div v-else-if="latestSubmission.responseCounts.closed" class="closed">Rectified</div>
        <div v-else class="pass">Pass</div>
      </div>
      <Icon
        v-if="latestSubmission"
        v-tooltip="'Open Pre-Start'"
        class="info-icon gap-left"
        :icon="infoIcon"
        @click="onOpenViewer(latestSubmission)"
      />
      <template v-if="submissions.length > 1">
        <Icon
          v-tooltip="showSubmissions ? 'Show Less' : 'Show More'"
          class="chevron-icon gap-left"
          :icon="chevronIcon"
          :rotation="showSubmissions ? 270 : 90"
          @click="toggleShowSubmissions"
        />
        <span class="count">({{ submissions.length }})</span>
      </template>
    </div>
    <div v-if="showSubmissions" class="all-submissions">
      <button
        class="hx-btn"
        v-for="(item, index) in allSubmissions"
        :key="index"
        :class="item.class"
        @click="onOpenViewer(item.submission)"
      >
        {{ item.label }}
      </button>
    </div>
  </hxCard>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import PreStartSubmissionModal from '@/components/modals/PreStartSubmissionModal.vue';

import InfoIcon from '@/components/icons/Info.vue';
import TickIcon from '@/components/icons/Tick.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import ChevronIcon from '@/components/icons/ChevronRight.vue';

import { formatDateIn } from '@/code/time';
import { attributeFromList } from '@/code/helpers';

function getFailCount(responses) {
  return responses.filter(r => r.answer === false).length;
}

function getItemClass(responses, closedStatusTypeId) {
  const failures = responses.filter(r => r.answer === false);

  if (failures.length === 0) {
    return '';
  }

  if (failures.filter(r => !r.ticketId).length) {
    return 'failure';
  }

  if (failures.every(r => r.ticket.activeStatus.statusTypeId === closedStatusTypeId)) {
    return 'closed';
  }

  return 'open';
}

export default {
  name: 'PreStartReport',
  components: {
    hxCard,
    Icon,
  },
  props: {
    asset: { type: Object, required: true },
    submissions: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
  },
  data: () => {
    return {
      infoIcon: InfoIcon,
      crossIcon: CrossIcon,
      chevronIcon: ChevronIcon,
      tickIcon: TickIcon,
      showSubmissions: false,
    };
  },
  computed: {
    icon() {
      return this.icons[this.asset.type];
    },
    closedTicketStatusId() {
      return attributeFromList(
        this.$store.state.constants.preStartTicketStatusTypes,
        'name',
        'closed',
        'id',
      );
    },
    failCount() {
      return getFailCount(this.latestSubmission.responses);
    },
    allSubmissions() {
      const subs = this.submissions.slice();

      subs.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());

      return subs.map(s => {
        const itemClass = getItemClass(s.responses, this.closedTicketStatusId);
        return {
          class: itemClass,
          label: this.formatTime(s.timestamp),
          submission: s,
        };
      });
    },
    latestSubmission() {
      return this.allSubmissions[this.allSubmissions.length - 1].submission;
    },
  },
  methods: {
    toggleShowSubmissions() {
      this.showSubmissions = !this.showSubmissions;
    },
    onOpenViewer(submission) {
      this.$modal.create(PreStartSubmissionModal, { submission }).onClose(resp => {
        if (resp === 'refresh') {
          this.$emit('refresh');
        }
      });
    },
    formatTime(date) {
      const tz = this.$timely.current.timezone;
      return formatDateIn(date, tz, { format: 'HH:mm' });
    },
  },
};
</script>

<style>
/* hxCard styling */
.pre-start-report.hxCardIcon {
  height: 2.5rem;
}

.pre-start-report.hxCard {
  border-left: 2px solid transparent;
}

.pre-start-report .hxCardIcon {
  height: 2.5rem;
}

.pre-start-report .hxCardHeaderWrapper {
  font-size: 1.5rem;
}

.pre-start-report .title-post {
  text-transform: capitalize;
  display: flex;
  flex-direction: row;
  margin-left: 1rem;
  height: 2rem;
  line-height: 2rem;
}

.pre-start-report .title-post .value {
  line-height: 1.5rem;
  margin-left: 1rem;
}

/* status indicator */
.pre-start-report .status {
  width: 10rem;
  text-align: center;
}

.pre-start-report .status .failure {
  color: red;
}

.pre-start-report .status .open {
  color: orange;
}

.pre-start-report .status .closed {
  color: green;
}

.pre-start-report .status .pass {
  color: green;
}

.pre-start-report .gap-left {
  margin-left: 1rem;
}

/* info icon */
.pre-start-report .info-icon {
  margin-right: 0.25rem;
  height: 1.5rem;
  width: 1.5rem;
  cursor: pointer;
}

.pre-start-report .chevron-icon {
  margin-top: 0.25rem;
  height: 1.5rem;
  width: 1.5rem;
  padding: 0.1rem;
  cursor: pointer;
}

.pre-start-report .count {
  font-size: 1rem;
  padding-left: 0.2rem;
}

.pre-start-report .info-icon:hover {
  opacity: 0.5;
}

/* other submissions */
.pre-start-report .all-submissions {
  margin-bottom: 1rem;
}

.pre-start-report .all-submissions .hx-btn {
  width: 6rem;
  margin: 0.1rem;
}

.pre-start-report .all-submissions .failure {
  background-color: rgba(139, 0, 0, 0.644);
}

.pre-start-report .all-submissions .closed {
  background-color: rgba(126, 126, 126, 0.644);
}

.pre-start-report .all-submissions .open {
  background-color: rgba(139, 74, 0, 0.644);
}
</style>