<template>
  <hxCard class="pre-start-failure" :icon="icon">
    <div class="title-post" slot="title-post">
      <div class="heading">{{ assetName }} ({{ breakdown }})</div>
      <Icon
        v-tooltip="show ? 'Show Less' : 'Show More'"
        class="chevron-icon gap-left"
        :icon="chevronIcon"
        :rotation="show ? 270 : 90"
        @click="toggleShow"
      />
    </div>
    <div v-if="show" class="submissions">
      <div class="submission" v-for="(submission, index) in submissions" :key="index">
        <div class="identifier">
          <div class="timestamp">{{ formatTime(submission.timestamp) }}</div>
          <div class="operator">{{ submission.operator.fullname }}</div>
          <div v-if="!submission.operator.id" class="employee-id">
            {{ submission.employeeId }}
          </div>
          <Icon
            class="info-icon"
            v-tooltip="'View Pre-Start'"
            :icon="infoIcon"
            @click="onOpenViewer(submission.submission)"
          />
        </div>

        <div
          class="control"
          v-for="(control, cIndex) in submission.controls"
          :key="cIndex"
          :class="{
            closed: control.ticketId && control.ticket.activeStatus.statusTypeId === closedStatusId,
            open: control.ticketId && control.ticket.activeStatus.statusTypeId !== closedStatusId,
          }"
        >
          <div class="outline">
            <div class="label">{{ control.label }}</div>
            <div class="answer">
              <div v-if="!control.ticketId" class="fail-answer">
                <span class="red-text">Fail</span>
              </div>
              <div v-else class="ticket-status">
                <div class="status">
                  {{ getTicketStatus(control.ticket.activeStatus.statusTypeId) }}
                </div>
              </div>
            </div>
          </div>
          <div v-if="control.comment" class="comment">• {{ control.comment }}</div>
        </div>
      </div>
    </div>
  </hxCard>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';

import PreStartSubmissionModal from '@/components/modals/PreStartSubmissionModal.vue';

import { formatDateIn, toUtcDate } from '@/code/time';

import ChevronIcon from '@/components/icons/ChevronRight.vue';
import InfoIcon from '@/components/icons/Info.vue';
import { attributeFromList } from '@/code/helpers';

function statusChanged(a, b) {
  return (
    a.reference !== b.reference || a.details !== b.details || a.statusTypeId !== b.statusTypeId
  );
}

function breakdownText(counts) {
  const text = [];
  if (counts.failuresWithoutTickets) {
    text.push(`Failures: ${counts.failuresWithoutTickets}`);
  }

  if (counts.closed) {
    text.push(`Closed: ${counts.closed}`);
  }

  if (counts.open) {
    text.push(`Open: ${counts.open}`);
  }

  return text.join(' | ');
}

export default {
  name: 'PreStartFailure',
  components: {
    hxCard,
    Icon,
  },
  props: {
    assetName: { type: String, required: true },
    icon: { type: Object, default: null },
    submissions: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      chevronIcon: ChevronIcon,
      infoIcon: InfoIcon,
      show: true,
    };
  },
  computed: {
    breakdown() {
      const counts = this.submissions
        .map(s => s.submission.responseCounts)
        .reduce(
          (acc, responseCount = {}) => {
            Object.entries(responseCount).forEach(([key, count]) => (acc[key] += count));
            return acc;
          },
          { closed: 0, failures: 0, failuresWithoutTickets: 0, open: 0 },
        );

      return breakdownText(counts);
    },
    ticketStatusTypes() {
      return this.$store.state.constants.preStartTicketStatusTypes;
    },
    closedStatusId() {
      return attributeFromList(this.ticketStatusTypes, 'name', 'closed', 'id');
    },
  },
  methods: {
    toggleShow() {
      this.show = !this.show;
    },
    formatTime(date) {
      const tz = this.$timely.current.timezone;
      return formatDateIn(date, tz, { format: 'HH:mm:ss' });
    },
    onOpenViewer(submission) {
      this.$modal.create(PreStartSubmissionModal, { submission }).onClose(resp => {
        if (resp === 'refresh') {
          this.$emit('refresh');
        }
      });
    },
    getTicketStatus(statusId) {
      return attributeFromList(this.ticketStatusTypes, 'id', statusId, 'name');
    },
  },
};
</script>

<style>
/* hxCard styling */
.pre-start-failure.hxCardIcon {
  height: 2.5rem;
}

.pre-start-failure.hxCard {
  border-left: 2px solid transparent;
}

.pre-start-failure .hxCardIcon {
  height: 2.5rem;
}

.pre-start-failure .hxCardHeaderWrapper {
  font-size: 1.5rem;
}

.pre-start-failure .title-post {
  text-transform: capitalize;
  display: flex;
  margin-left: 1rem;
  height: 2rem;
  line-height: 2rem;
}

.pre-start-failure .title-post .chevron-icon {
  margin-left: 1rem;
  margin-top: 0.25rem;
  height: 1.5rem;
  width: 1.5rem;
  padding: 0.1rem;
  cursor: pointer;
}

/* submissions */
.pre-start-failure .submission {
  margin-bottom: 0.75rem;
}

.pre-start-failure .submission .identifier {
  display: flex;
  justify-content: space-around;
  padding: 0.25rem;
  font-size: 1.25rem;
  background-color: #425866;
  color: #c4d1da;
}

.pre-start-failure .submission .identifier .info-icon {
  height: 1.25rem;
  cursor: pointer;
}

.pre-start-failure .submission .identifier .info-icon:hover {
  opacity: 0.5;
}

/* controls */
.pre-start-failure .submission .control {
  padding-left: 0.5rem;
  background-color: rgba(139, 0, 0, 0.281);
  min-height: 2.5rem;
  line-height: 2.5rem;
  border-bottom: 1px solid #677e8c;
}

.pre-start-failure .control.closed {
  background-color: rgba(88, 88, 88, 0.281);
}

.pre-start-failure .control.open {
  background-color: rgba(139, 67, 0, 0.281);
}

.pre-start-failure .submission .control .outline {
  display: grid;
  grid-template-columns: auto auto;
}

.pre-start-failure .submission .control .comment {
  margin-left: 2rem;
}

.pre-start-failure .submission .control .answer {
  font-weight: bold;
  font-size: 1.25rem;
  justify-self: right;
  padding-right: 1rem;
}
</style>