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
      <div class="timestamp">{{ formatTime(submission.timestamp) }}</div>
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
          :class="{ fail: control.answer === false, na: control.answer === null }"
        >
          <div class="outline">
            <div class="label">{{ control.label }}</div>
            <div class="answer">
              <div v-if="control.answer === true" class="green-text">Pass</div>
              <div v-else-if="control.answer === false && !control.ticketId" class="fail-answer">
                <span class="red-text">Fail</span>
                <Icon
                  class="raise-ticket-icon"
                  v-tooltip="'Riase Ticket'"
                  :icon="tagIcon"
                  @click="onRaiseTicket(control)"
                />
              </div>
              <div v-else-if="control.answer === false && control.ticketId" class="ticket-answer">
                Has Ticket
              </div>
              <div v-else>N/A</div>
            </div>
            <div class="status"></div>
          </div>
          <div v-if="control.comment" class="comment">• {{ control.comment }}</div>
        </div>
      </div>
    </div>
    <div v-if="submission.comment" class="submission-comment">
      <div class="title">Comments</div>
      <div class="comment">{{ submission.comment }}</div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';

import TagIcon from '@/components/icons/Tag.vue';
import EditIcon from '@/components/icons/Edit.vue';

import { attributeFromList } from '@/code/helpers';
import { formatDateIn } from '@/code/time';
import PreStartCreateTicketModal from './PreStartCreateTicketModal.vue';

function getOperator(operators, operatorId, employeeId) {
  return (
    attributeFromList(operators, 'id', operatorId) ||
    attributeFromList(operators, 'employeeId', employeeId) ||
    {}
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
    };
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
      ticketStatusTypes: state => state.preStartTicketStatusTypes,
    }),
    asset() {
      return attributeFromList(this.assets, 'id', this.submission.assetId) || {};
    },
    operator() {
      return getOperator(this.operators, this.submission.operatorId, this.submission.employeeId);
    },
  },
  methods: {
    formatTime(date) {
      const tz = this.$timely.current.timezone;
      return formatDateIn(date, tz, { format: '(yyyy-MM-dd) HH:mm:ss' });
    },
    controlsWithResponses(controls, responses) {
      return controls.map(c => {
        const r = attributeFromList(responses, 'controlId', c.id) || {};
        return {
          id: c.id,
          sectionId: c.id,
          order: c.order,
          label: c.label,
          answer: r.answer,
          comment: r.comment,
          ticketId: r.ticketId,
          ticket: r.ticket,
        };
      });
    },
    onRaiseTicket(control) {
      console.dir('--- raising ticket');
      console.dir(control);
      const opts = {
        controlText: control.label,
        controlComment: control.comment,
      };

      this.$modal.create(PreStartCreateTicketModal, opts).onClose(resp => {
        console.dir(resp);
      });
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
}

.pre-start-submission-modal .identity .employee-id-only {
  background-color: darkred;
  padding: 0 2rem;
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
  grid-template-columns: auto 4rem;
  color: #b6c3cc;
}

.pre-start-submission-modal .control.fail {
  background-color: rgba(139, 0, 0, 0.281);
}

.pre-start-submission-modal .control .fail-answer {
  display: flex;
}

.pre-start-submission-modal .control.na .outline {
  font-style: italic;
  color: grey;
}

.pre-start-submission-modal .control .answer {
  font-weight: bold;
  font-size: 1.25rem;
}

.pre-start-submission-modal .control .comment {
  margin-left: 2rem;
}

.pre-start-submission-modal .control .raise-ticket-icon {
  cursor: pointer;
  height: 2.5rem;
  padding-left: 10px;
}

.pre-start-submission-modal .control .raise-ticket-icon svg {
  stroke-width: 2;
}

.pre-start-submission-modal .control .raise-ticket-icon:hover {
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