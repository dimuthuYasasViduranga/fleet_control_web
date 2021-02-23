<template>
  <div class="pre-start-viewer">
    <div class="submission">
      <div class="operator">{{ submission.operatorName }}</div>
      <div
        v-if="!submission.operatorId && submission.employeeId"
        v-tooltip="employeeIdWarning"
        class="employee-id"
      >
        <div class="text">Employee ID: {{ submission.employeeId }}</div>
      </div>

      <div class="asset">{{ submission.assetName }} ({{ submission.assetType }})</div>
      <div class="timestamp">{{ formatTime(submission.timestamp) }}</div>
    </div>
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
        <div class="top">
          <div class="label">{{ control.label }}</div>
          <div class="answer">{{ getAnswerIcon(control.answer) }}</div>
        </div>

        <div v-if="control.comment" class="comment">- {{ control.comment }}</div>
      </div>
      <div class="section-comment">{{ section.comment }}</div>
    </div>
  </div>
</template>

<script>
import { formatTodayRelative } from '@/code/time';
export default {
  name: 'PreStartViewer',
  props: {
    submission: { type: Object, required: true },
  },
  computed: {
    employeeIdWarning() {
      return `Submitted under Employee ID '${this.submission.employeeId}' but no operator found`;
    },
  },
  methods: {
    getAnswerIcon(answer) {
      switch (answer) {
        case true:
          return '✔';
        case false:
          return '❌';
        case null:
          return 'N/A';
        default:
          return '';
      }
    },
    formatTime(date) {
      return formatTodayRelative(date, 'yyyy-mm-dd HH:MM:SS');
    },
  },
};
</script>

<style>
/* submission details */
.pre-start-viewer .submission {
  width: 100%;
  display: inline-flex;
  justify-content: space-around;
  background-color: #314452;
  padding: 0.5rem;
}

.pre-start-viewer .submission .employee-id .text {
  padding: 0.05rem 1rem;
  background-color: darkred;
}

/* section */

.pre-start-viewer .section {
  margin-top: 0.5rem;
}

.pre-start-viewer .section-header {
  padding: 0.25rem;
  background-color: #23343f;
}

.pre-start-viewer .section-header .title {
  font-size: 1.5rem;
}

/* controls */
.pre-start-viewer .control {
  min-height: 2.5rem;
  line-height: 2.5rem;
  border-bottom: 1px solid #677e8c;
}

.pre-start-viewer .control .top {
  display: grid;
  grid-template-columns: auto 2rem;
  color: #b6c3cc;
}

.pre-start-viewer .control.fail .top {
  background-color: rgba(139, 0, 0, 0.281);
}

.pre-start-viewer .control .comment {
  margin-left: 2rem;
}

.pre-start-viewer .control.na .top {
  font-style: italic;
  color: grey;
}
</style>