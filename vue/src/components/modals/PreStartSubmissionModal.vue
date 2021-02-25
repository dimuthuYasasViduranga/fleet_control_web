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
          v-for="(control, cIndex) in section.controls"
          :key="cIndex"
          :class="{ fail: control.answer === false, na: control.answer === null }"
        >
          <div class="outline">
            <div class="label">{{ control.label }}</div>
            <div class="answer">
              <div v-if="control.answer === true" class="green-text">Pass</div>
              <div v-else-if="control.answer === false" class="red-text">Fail</div>
              <div v-else>N/A</div>
            </div>
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

import { attributeFromList } from '@/code/helpers';
import { formatTodayRelative } from '@/code/time';

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
  props: {
    submission: { type: Object, required: true },
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
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
      return formatTodayRelative(date, 'yyyy-mm-dd HH:MM:SS');
    },
  },
};
</script>

<style>
@import '../../assets/textColors.css';
.pre-start-submission-modal-wrapper .modal-container {
  max-width: 60rem;
}
</style>

<style scoped>
.identity {
  width: 100%;
  display: flex;
  justify-content: space-around;
  background-color: #314452;
  padding: 0.5rem;
}

.identity .employee-id-only {
  background-color: darkred;
  padding: 0 2rem;
}

/* section */
.section {
  margin-top: 1.5rem;
}

.section .section-header {
  padding: 0.25rem;
  background-color: #425866;
}

.section .section-header .title {
  font-size: 1.5rem;
}

/* control */
.control {
  min-height: 2.5rem;
  line-height: 2.5rem;
  border-bottom: 1px solid #677e8c;
}

.control .outline {
  display: grid;
  grid-template-columns: auto 3rem;
  color: #b6c3cc;
}

.control.fail {
  background-color: rgba(139, 0, 0, 0.281);
}

.control.na .outline {
  font-style: italic;
  color: grey;
}

.control .answer {
  font-weight: bold;
  font-size: 1.25rem;
}

.control .comment {
  margin-left: 2rem;
}

/* submission comments */
.submission-comment .title {
  background-color: #425866;
  padding: 0.25rem;
  margin-top: 1.5rem;
  font-size: 1.5rem;
}

.submission-comment .comment {
  margin-top: 0.5rem;
}
</style>