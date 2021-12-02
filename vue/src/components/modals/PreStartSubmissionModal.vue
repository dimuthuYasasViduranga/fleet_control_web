<template>
  <div class="pre-start-submission-modal">
    <div class="identity">
      <div class="asset">{{ asset.name }} ({{ asset.type }})</div>
      <div v-if="operator.id" class="operator">{{ operator.fullname || 'Unknown Operator' }}</div>
      <div
        v-else
        v-tooltip="'No operator found for the given employee ID'"
        class="employee-id-only"
      >
        Employee ID: {{ submission.employeeId }}
      </div>
      <div class="timestamp">
        <span>
          {{ formatTime(submission.timestamp) }}
        </span>
        <Icon
          v-tooltip="'Download PDF'"
          class="pdf-download"
          :icon="pdfIcon"
          @click="onDownloadPdf()"
        />
      </div>
    </div>
    <div v-if="submission.comment" class="submission-comment">
      <div class="title">Comments</div>
      <div class="comment">{{ submission.comment }}</div>
    </div>
    <div class="sections">
      <div class="section" v-for="(section, sIndex) in submission.form.sections" :key="sIndex">
        <div class="section-header">
          <div class="title">{{ section.title }}</div>
          <div class="details">{{ section.details }}</div>
        </div>
        <div
          class="control"
          v-for="(control, cIndex) in controlsWithResponses(section.controls, submission.responses)"
          :key="cIndex"
          :class="{
            fail: control.answer === false,
            'has-ticket': control.ticketId,
            closed: control.ticketId && control.ticket.activeStatus.statusTypeId === closedStatusId,
            na: control.answer === null,
          }"
        >
          <div class="outline">
            <div class="label">{{ control.label }}</div>
            <div class="answer">
              <div v-if="control.answer === true" class="green-text">Pass</div>
              <div v-else-if="control.answer === false && !control.ticketId" class="fail-answer">
                <span class="red-text">Fail</span>
                <Icon
                  class="raise-ticket-icon"
                  v-tooltip="'Raise Ticket'"
                  :icon="tagIcon"
                  @click="onRaiseTicket(control)"
                />
              </div>
              <div v-else-if="control.answer === false && control.ticketId" class="ticket-status">
                <div class="status" style="text-transform: capitalize">
                  {{ getTicketStatus(control.ticket.activeStatus.statusTypeId) }}
                </div>
                <Icon
                  class="edit-ticket-status-icon"
                  v-tooltip="'Edit Ticket Status'"
                  :icon="editIcon"
                  @click="onUpdateTicketStatus(control, control.ticket.activeStatus)"
                />
              </div>
              <div v-else>N/A</div>
            </div>
            <div class="status"></div>
          </div>
          <div v-if="control.comment" class="comment">• {{ control.comment }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';

import TagIcon from '@/components/icons/Tag.vue';
import EditIcon from '@/components/icons/Edit.vue';
import PdfIcon from '@/components/icons/Pdf.vue';

import { attributeFromList } from '@/code/helpers';
import { formatDateIn, toUtcDate } from '@/code/time';
import PreStartCreateTicketModal from './PreStartCreateTicketModal.vue';
import { createPDF } from '../pages/pre_start_submissions/pdf';

function getOperator(operators, operatorId, employeeId) {
  return (
    attributeFromList(operators, 'id', operatorId) ||
    attributeFromList(operators, 'employeeId', employeeId) ||
    {}
  );
}

function submissionToPDFFormat(submission, asset, operator, ticketTypes) {
  const assetFullname = asset.type ? `${asset.name} (${asset.type})` : asset.name;
  const operatorName = operator.fullname || submission.employeeId;

  const sections = submission.form.sections.map(s =>
    formatSection(s, submission.responses, ticketTypes),
  );

  return {
    heading: {
      asset: assetFullname,
      operator: operatorName,
      timestamp: submission.timestamp,
    },
    comments: submission.comment.split('\n'),
    sections: sections,
  };
}

function formatSection(section, responses, ticketTypes) {
  return {
    title: section.title,
    details: section.details,
    controls: section.controls.map(c => formatControl(c, responses, ticketTypes)),
  };
}

function formatControl(control, responses, ticketTypes) {
  const resp = attributeFromList(responses, 'controlId', control.id) || {};
  const ticket = resp.ticket || {};
  const activeStatus = ticket.activeStatus || {};
  const ticketStatus = getTicketStatus(ticket, ticketTypes);
  const status = getStatus(resp);
  return {
    label: control.label,
    status,
    comment: resp.comment,
    ticket: {
      status: ticketStatus,
      reference: activeStatus.reference,
      details: activeStatus.details,
      timestamp: ticket.timestamp,
    },
  };
}

function getStatus(resp) {
  switch (resp.answer) {
    case true:
      return 'Pass';
    case false:
      return 'Fail';
    default:
      return 'N/A';
  }
}

function getTicketStatus(ticket, ticketTypes) {
  if (!ticket || !ticket.activeStatus) {
    return;
  }

  const [name, alias] = attributeFromList(ticketTypes, 'id', ticket.activeStatus.statusTypeId, [
    'name',
    'alias',
  ]);
  return alias || name;
}

function statusChanged(a, b) {
  return (
    a.reference !== b.reference || a.details !== b.details || a.statusTypeId !== b.statusTypeId
  );
}

export default {
  name: 'PreStartSubmissionModal',
  wrapperClass: 'pre-start-submission-modal-wrapper',
  components: {
    Icon,
  },
  props: {
    submission: { type: Object, required: true },
  },
  data: () => {
    return {
      tagIcon: TagIcon,
      editIcon: EditIcon,
      pdfIcon: PdfIcon,
      hasMadeChanges: false,
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
      ticketStatusTypes: state => state.preStartTicketStatusTypes,
      categories: state => state.preStartControlCategories,
    }),
    asset() {
      return attributeFromList(this.assets, 'id', this.submission.assetId) || {};
    },
    operator() {
      return getOperator(this.operators, this.submission.operatorId, this.submission.employeeId);
    },
    closedStatusId() {
      return attributeFromList(this.ticketStatusTypes, 'name', 'closed', 'id');
    },
  },
  methods: {
    outerClickIntercept() {
      if (this.hasMadeChanges) {
        return 'refresh';
      }
    },
    formatTime(date) {
      const tz = this.$timely.current.timezone;
      return formatDateIn(date, tz, { format: '(yyyy-MM-dd) HH:mm:ss' });
    },
    getTicketStatus(statusId) {
      return attributeFromList(this.ticketStatusTypes, 'id', statusId, 'name');
    },
    controlsWithResponses(controls, responses) {
      return controls.map(c => {
        const r = attributeFromList(responses, 'controlId', c.id) || {};
        return {
          id: c.id,
          sectionId: c.id,
          responseId: r.id,
          order: c.order,
          label: c.label,
          requiresComment: c.requiresComment,
          categoryId: c.categoryId,
          category: attributeFromList(this.categories, 'id', c.categoryId, 'name'),
          answer: r.answer,
          comment: r.comment,
          ticketId: r.ticketId,
          ticket: r.ticket,
        };
      });
    },
    onRaiseTicket(control) {
      const opts = {
        controlText: control.label,
        controlComment: control.comment,
      };

      this.$modal.create(PreStartCreateTicketModal, opts).onClose(resp => {
        if (!resp) {
          return;
        }

        this.raiseTicket(this.submission.assetId, control, resp);
      });
    },
    raiseTicket(assetId, control, ticketParams) {
      const payload = {
        asset_id: assetId,
        response_id: control.responseId,
        reference: ticketParams.reference,
        details: ticketParams.details,
        status_type_id: ticketParams.statusTypeId,
        timestamp: Date.now(),
      };

      this.$channel
        .push('pre-start:set response ticket', payload)
        .receive('ok', ({ ticket }) => {
          this.hasMadeChanges = true;
          this.$toaster.info('Ticket Created');
          const status = ticket.active_status;

          const resp = this.submission.responses.find(r => r.id === control.responseId);

          resp.ticketId = ticket.id;
          resp.ticket = {
            id: ticket.id,
            assetId: ticket.asset_id,
            createdByDispatcherId: ticket.created_by_dispatcher_id,
            activeStatus: {
              id: status.id,
              ticketId: status.ticket_id,
              reference: status.reference,
              details: status.details,
              createdByDispatcherId: status.created_by_dispatcher_id,
              statusTypeId: status.status_type_id,
              timestamp: toUtcDate(status.timestamp),
              serverTimestamp: toUtcDate(status.server_timestamp),
            },
            timestamp: toUtcDate(ticket.timestamp),
            serverTimestamp: toUtcDate(ticket.serverTimestamp),
          };
        })
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to create ticket'));
    },
    onUpdateTicketStatus(control, status) {
      const opts = {
        title: 'Update Ticket Status',
        controlText: control.label,
        controlComment: control.comment,
        timestamp: status.timestamp,
        reference: status.reference,
        details: status.details,
        statusTypeId: status.statusTypeId,
      };

      this.$modal.create(PreStartCreateTicketModal, opts).onClose(resp => {
        if (!resp) {
          return;
        }

        if (statusChanged(status, resp)) {
          this.updateTicketStatus(status.ticketId, resp, control);
        }
      });
    },
    updateTicketStatus(ticketId, status, control) {
      const payload = {
        ticket_id: ticketId,
        reference: status.reference,
        details: status.details,
        status_type_id: status.statusTypeId,
        timestamp: Date.now(),
      };

      this.$channel
        .push('pre-start:update response ticket status', payload)
        .receive('ok', resp => {
          this.hasMadeChanges = true;
          this.$toaster.info('Ticket Updated');
          const newStatus = resp.status;

          control.ticket.activeStatus = {
            id: newStatus.id,
            ticketId: newStatus.ticket_id,
            reference: newStatus.reference,
            details: newStatus.details,
            createdByDisaptcherId: newStatus.created_by_dispatcher_id,
            statusTypeId: newStatus.status_type_id,
            timestamp: toUtcDate(newStatus.timestamp),
            serverTimestamp: toUtcDate(newStatus.server_timestamp),
          };
        })
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to update ticket'));
    },
    onDownloadPdf() {
      const timeString = formatDateIn(this.submission.timestamp, this.$timely.current.timezone, {
        format: `yyyy-MM-dd_HH-mm-ss`,
      });
      const filename = `${this.asset.name}_${timeString}`;

      const data = submissionToPDFFormat(
        this.submission,
        this.asset,
        this.operator,
        this.ticketStatusTypes,
      );
      createPDF(data, this.$timely.current.timezone, { filename });
    },
  },
};
</script>


<style>
@import '../../assets/textColors.css';
.pre-start-submission-modal-wrapper .modal-container {
  max-width: 60rem;
}

.pre-start-submission-modal .identity {
  width: 100%;
  display: flex;
  justify-content: space-around;
  background-color: #314452;
  padding: 0.5rem;
  padding-right: 0;
}

.pre-start-submission-modal .identity {
  line-height: 1.5rem;
}

.pre-start-submission-modal .identity .employee-id-only {
  background-color: darkred;
  padding: 0 2rem;
}

.pre-start-submission-modal .identity .timestamp {
  display: inline-flex;
  margin-right: -2rem;
}

.pre-start-submission-modal .identity .timestamp .pdf-download {
  cursor: pointer;
  margin-left: 2rem;
  height: 1.5rem;
  width: 1.5rem;
}

.pre-start-submission-modal .identity .timestamp .pdf-download:hover {
  opacity: 0.75;
}

/* section */
.pre-start-submission-modal .section {
  margin-top: 1.5rem;
}

.pre-start-submission-modal .section .section-header {
  padding: 0.25rem;
  background-color: #425866;
}

.pre-start-submission-modal .section .section-header .title {
  font-size: 1.5rem;
}

/* control */
.pre-start-submission-modal .control {
  min-height: 2.5rem;
  line-height: 2.5rem;
  border-bottom: 1px solid #677e8c;
}

.pre-start-submission-modal .control .outline {
  display: grid;
  grid-template-columns: auto auto;
  color: #b6c3cc;
}

.pre-start-submission-modal .control.fail {
  background-color: rgba(139, 0, 0, 0.281);
}

.pre-start-submission-modal .control.has-ticket {
  background-color: rgba(139, 67, 0, 0.281);
}

.pre-start-submission-modal .control.closed {
  background-color: rgba(88, 88, 88, 0.281);
}

.pre-start-submission-modal .control .fail-answer,
.pre-start-submission-modal .control .ticket-status {
  display: flex;
}

.pre-start-submission-modal .control.na .outline {
  font-style: italic;
  color: grey;
}

.pre-start-submission-modal .control .answer {
  font-weight: bold;
  font-size: 1.25rem;
  justify-self: right;
}

.pre-start-submission-modal .control .comment {
  margin-left: 2rem;
}

.pre-start-submission-modal .control .raise-ticket-icon,
.pre-start-submission-modal .control .edit-ticket-status-icon {
  cursor: pointer;
  height: 2.5rem;
  padding-left: 10px;
}

.pre-start-submission-modal .control .raise-ticket-icon svg,
.pre-start-submission-modal .control .edit-ticket-status-icon svg {
  stroke-width: 1;
}

.pre-start-submission-modal .control .raise-ticket-icon:hover,
.pre-start-submission-modal .control .edit-ticket-status-icon:hover {
  stroke: orange;
}

/* submission comments */
.pre-start-submission-modal .submission-comment .title {
  background-color: #425866;
  padding: 0.25rem;
  margin-top: 1.5rem;
  font-size: 1.5rem;
}

.pre-start-submission-modal .submission-comment .comment {
  margin-top: 0.5rem;
}
</style>