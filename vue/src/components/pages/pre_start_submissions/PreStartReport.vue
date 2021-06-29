<template>
  <hxCard class="pre-start-report" :icon="icon">
    <Icon
      v-if="hasOrphanedTickets"
      v-tooltip="'Orphaned tickets detected'"
      class="orphaned-tickets-alert"
      slot="title-pre"
      :icon="alertIcon"
    />
    <div class="title-post" slot="title-post">
      <div class="submission-time">
        {{ asset.name }} ({{ formatTime(latestSubmission.timestamp) }})
      </div>
      <div class="status gap-left">
        <div v-if="latestSubmission.responseCounts.failuresWithoutTickets" class="failure">
          Fail {{ latestSubmission.comment ? '- has Comments' : '' }}
        </div>
        <div v-else-if="latestSubmission.responseCounts.open" class="open">Open Tickets</div>

        <div v-else-if="latestSubmission.responseCounts.closed" class="closed">Rectified</div>
        <div v-else class="pass">
          Pass {{ responsesHaveComments(latestSubmission) ? '- has Comments' : '' }}
        </div>
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
        v-for="(item, index) in submissionItems"
        :key="index"
        :class="item.classes"
        v-tooltip="!item.inShift ? 'From another shift' : ''"
        @click="onOpenViewer(item.submission)"
      >
        <div style="display: inline-flex">
          {{ item[showFullDate ? 'fullLabel' : 'label'] }}
          <Icon v-if="item.hasComments" class="has-comments-icon" :icon="commentIcon" />
        </div>
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
import AlertIcon from '@/components/icons/Alert.vue';
import CommentIcon from '@/components/icons/Comment.vue';

import { formatDateIn, isSameDownTo } from '@/code/time';
import { attributeFromList } from '@/code/helpers';

function getFailCount(responses) {
  return responses.filter(r => r.answer === false).length;
}

function getItemClass(responses, closedStatusTypeId) {
  const failures = responses.filter(r => r.answer === false);

  if (failures.length === 0) {
    return 'pass';
  }

  if (failures.filter(r => !r.ticketId).length) {
    return 'failure';
  }

  if (failures.every(r => r.ticket.activeStatus.statusTypeId === closedStatusTypeId)) {
    return 'closed';
  }

  return 'open';
}

function isInShift(submission, shift) {
  if (!shift) {
    return true;
  }

  const shiftStart = shift.startTime.getTime();
  const shiftEnd = shift.endTime.getTime();
  const timestamp = submission.timestamp.getTime();
  return timestamp > shiftStart && timestamp < shiftEnd;
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
    shift: { type: Object, default: null },
  },
  data: () => {
    return {
      infoIcon: InfoIcon,
      crossIcon: CrossIcon,
      chevronIcon: ChevronIcon,
      alertIcon: AlertIcon,
      tickIcon: TickIcon,
      commentIcon: CommentIcon,
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
    submissionItems() {
      const subs = this.submissions.slice();

      subs.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());

      return subs.map(s => {
        const itemClass = getItemClass(s.responses, this.closedTicketStatusId);
        const hasComments = !!s.comment || (itemClass === 'pass' && this.responsesHaveComments(s));
        const inShift = isInShift(s, this.shift);

        const classes = [itemClass];

        if (!inShift) {
          classes.push('out-of-shift');
        }

        return {
          classes,
          label: this.formatTime(s.timestamp, 'HH:mm'),
          fullLabel: this.formatTime(s.timestamp, '(MMM dd) HH:mm'),
          hasComments,
          inShift,
          submission: s,
        };
      });
    },
    latestSubmission() {
      return this.submissionItems[this.submissionItems.length - 1].submission;
    },
    hasOrphanedTickets() {
      const submissions = this.submissionItems;
      if (submissions.length < 2) {
        return false;
      }

      const latestTicketIds = submissions[submissions.length - 1].submission.responses
        .map(r => r.ticketId)
        .filter(id => id);

      const otherSubmissions = submissions.slice(0, -1);

      return otherSubmissions.some(sub => {
        const ticketIds = sub.submission.responses.map(r => r.ticketId).filter(id => id);
        return (
          !sub.classes.includes('closed') && ticketIds.some(id => !latestTicketIds.includes(id))
        );
      });
    },
    showFullDate() {
      if (!this.submissions.length) {
        return false;
      }
      const first = this.submissions[0].timestamp;
      const second = this.submissions[this.submissions.length - 1].timestamp;

      const tz = this.$timely.current.timezone;
      return !isSameDownTo(first, second, tz, 'day');
    },
  },
  watch: {
    submissions() {
      this.showSubmissions = false;
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
    formatTime(date, format = 'HH:mm') {
      const tz = this.$timely.current.timezone;
      return formatDateIn(date, tz, { format });
    },
    responsesHaveComments(submission) {
      return submission.responses.some(r => r.comment);
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

.pre-start-report .orphaned-tickets-alert {
  stroke: orange;
}

.pre-start-report .orphaned-tickets-alert svg {
  stroke-width: 1.2;
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
  margin: 0.1rem;
}

.pre-start-report .all-submissions .out-of-shift {
  opacity: 0.75;
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

.pre-start-report .all-submissions .has-comments-icon {
  width: 1rem;
  margin-left: 0.5rem;
}

.pre-start-report .all-submissions .has-comments-icon svg {
  stroke-width: 2.5;
}
</style>