<template>
  <div class="pre-start-report-table">
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      :data="assetLatestPreStartsReports"
      :show-caption="false"
      :show-filter="false"
      :cache-lifetime="0"
    >
      <table-column cell-class="table-cel" label="Assets">
        <template slot-scope="row">
          <table class="asset-table">
            <tr>
              <td v-if="hasOrphanedTickets">
                <Icon
                  v-tooltip="'Orphaned tickets detected'"
                  class="orphaned-tickets-alert"
                  slot="title-pre"
                  :icon="alertIcon"
                />
              </td>
              <td><Icon :icon="row.icon" /></td>
              <td>
                <div>{{ row.assetName }}</div>
              </td>
            </tr>
          </table>
        </template>
      </table-column>

      <table-column
        cell-class="table-cel"
        class="submission-time"
        label="Timestamp"
        show="latestSubmission.timestamp"
        data-type="date"
        :formatter="formatHeadingTime"
      />

      <table-column cell-class="table-cel" label="Status">
        <template slot-scope="row">
          <table class="status-table">
            <tr v-if="row.latestSubmission.responseCounts.failuresWithoutTickets" class="status">
              <td class="failure">
                Fail {{ row.latestSubmission.comment ? '- has Comments' : '' }}
              </td>
              <td>
                <Icon
                  v-if="row.latestSubmission"
                  v-tooltip="'Open Pre-Start'"
                  class="info-icon gap-left"
                  :icon="infoIcon"
                  @click="onOpenViewer(row.latestSubmission)"
                />
              </td>
            </tr>
            <tr v-else-if="row.latestSubmission.responseCounts.open" class="status">
              <td class="open">Open Tickets</td>
              <td>
                <Icon
                  v-if="row.latestSubmission"
                  v-tooltip="'Open Pre-Start'"
                  class="info-icon gap-left"
                  :icon="infoIcon"
                  @click="onOpenViewer(row.latestSubmission)"
                />
              </td>
            </tr>
            <tr v-else-if="row.latestSubmission.responseCounts.closed" class="status">
              <td class="closed">Rectified</td>
              <td>
                <Icon
                  v-if="row.latestSubmission"
                  v-tooltip="'Open Pre-Start'"
                  class="info-icon gap-left"
                  :icon="infoIcon"
                  @click="onOpenViewer(row.latestSubmission)"
                />
              </td>
            </tr>
            <tr v-else class="status">
              <td class="pass">
                Pass
                {{
                  responsesHaveComments(row.latestSubmission) || row.latestSubmission.comment
                    ? '- has Comments'
                    : ''
                }}
              </td>
              <td>
                <Icon
                  v-if="row.latestSubmission"
                  v-tooltip="'Open Pre-Start'"
                  class="info-icon gap-left"
                  :icon="infoIcon"
                  @click="onOpenViewer(row.latestSubmission)"
                />
              </td>
            </tr>
          </table>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import { TableComponent, TableColumn } from 'vue-table-component';
import Icon from 'hx-layout/Icon.vue';
import hxCard from 'hx-layout/Card.vue';
import PreStartSubmissionModal from '@/components/modals/PreStartSubmissionModal.vue';

import InfoIcon from '@/components/icons/Info.vue';
import AlertIcon from '@/components/icons/Alert.vue';

import { formatDateIn, isSameDownTo } from '@/code/time';
import { attributeFromList } from '@/code/helpers';

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
  name: 'PreStartTableReport',
  components: {
    hxCard,
    Icon,
    TableComponent,
    TableColumn,
  },
  props: {
    reports: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
    shift: { type: Object, default: null },
    useFullTimestamp: { type: Boolean, default: false },
  },
  data: () => {
    return {
      infoIcon: InfoIcon,
      alertIcon: AlertIcon,
    };
  },
  computed: {
    assetLatestPreStartsReports() {
      const latestSubmissionItems = this.reports.map(report => {
        const submissionItems = this.submissionItems(report.submissions);
        return {
          assetName: report.asset.name,
          latestSubmission: submissionItems[this.submissionItems.length - 1].submission,
          icon: this.icons[report.asset.type],
        };
      });
      return latestSubmissionItems.sort(
        (a, b) => b.latestSubmission.timestamp.getTime() - a.latestSubmission.timestamp.getTime(),
      );
    },
    closedTicketStatusId() {
      return attributeFromList(
        this.$store.state.constants.preStartTicketStatusTypes,
        'name',
        'closed',
        'id',
      );
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
  methods: {
    submissionItems(submissions) {
      const subs = submissions && submissions.slice();
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
    onOpenViewer(submission) {
      this.$modal.create(PreStartSubmissionModal, { submission }).onClose(resp => {
        if (resp === 'refresh') {
          this.$emit('refresh');
        }
      });
    },
    formatHeadingTime(date) {
      const now = new Date();
      const tz = this.$timely.current.timezone;

      if (!this.useFullTimestamp) {
        return formatDateIn(date, tz, { format: 'HH:mm' });
      }

      const isSameYear = isSameDownTo(date, now, tz, 'year');
      if (isSameYear) {
        return formatDateIn(date, tz, { format: 'LLL-dd HH:mm' });
      }

      return formatDateIn(date, tz, { format: 'yyyy LLL-dd HH:mm' });
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
/* asset-table & status-table */
.pre-start-report-table .asset-table,
.pre-start-report-table .status-table {
  margin-left: auto;
  margin-right: auto;
}

.pre-start-report-table .asset-table td,
.pre-start-report-table .status-table td {
  border: none;
}

/* status indicator */
.pre-start-report .status {
  width: 10rem;
  text-align: center;
}

.pre-start-report-table .status .failure {
  color: red;
}

.pre-start-report-table .status .open {
  color: orange;
}

.pre-start-report-table .status .closed {
  color: green;
}

.pre-start-report-table .status .pass {
  color: green;
}

.pre-start-report-table .gap-left {
  margin-left: 1rem;
}

/* orphaned tickets */
.pre-start-report-table .orphaned-tickets-alert {
  stroke: orange;
}

.pre-start-report-table .orphaned-tickets-alert svg {
  stroke-width: 1.2;
}

.pre-start-report-table .submission-time {
  min-width: 13rem;
}
</style>
