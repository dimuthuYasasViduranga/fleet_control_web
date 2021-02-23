<template>
  <hxCard class="pre-start-report" :icon="submission.icon" :class="cardClass">
    <div class="title-post" slot="title-post">
      <div class="submission-time">
        {{ submission.assetName }} - {{ formatTime(submission.timestamp) }} |
      </div>
      <div class="value tick" :class="{ dim: tickCount === 0 }">
        <span style="color: green">✔</span>: {{ tickCount }}
      </div>
      <div class="value cross" :class="{ dim: crossCount === 0 }">❌: {{ crossCount }}</div>
      <div class="value na" :class="{ dim: naCount === 0 }">N/A: {{ naCount }}</div>
      <Icon
        class="chevron-icon gap-left"
        :icon="chevronIcon"
        :rotation="show ? 270 : 90"
        @click="toggleShow"
      />
    </div>
    <PreStartSubmissionViewer v-if="show" :submission="submission" />
  </hxCard>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import PreStartSubmissionViewer from './PreStartSubmissionViewer.vue';

import ChevronIcon from '@/components/icons/ChevronRight.vue';
import { todayRelativeFormat } from '@/code/time';

const MAX_SUBMISSION_TIME = 12 * 3600 * 1000;

export default {
  name: 'PreStartReport',
  components: {
    hxCard,
    Icon,
    PreStartSubmissionViewer,
  },
  props: {
    submission: { type: Object, required: true },
  },
  data: () => {
    return {
      chevronIcon: ChevronIcon,
      show: false,
    };
  },
  computed: {
    controls() {
      return this.submission.form.sections.map(s => s.controls).flat();
    },
    tickCount() {
      return this.controls.filter(c => c.answer === true).length;
    },
    crossCount() {
      return this.controls.filter(c => c.answer === false).length;
    },
    naCount() {
      return this.controls.filter(c => c.answer === null).length;
    },
    isOldSubmission() {
      return Date.now() - this.submission.timestamp.getTime() > MAX_SUBMISSION_TIME;
    },
    cardClass() {
      const classes = [];

      if (this.show) {
        classes.push('open');
      }

      if (this.crossCount > 0) {
        classes.push('errors');
      }

      if (this.isOldSubmission) {
        classes.push('old');
      }

      return classes;
    },
  },
  methods: {
    toggleShow() {
      this.show = !this.show;
    },
    formatTime(date) {
      return todayRelativeFormat(date);
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

.pre-start-report.hxCard.open {
  border: 2px solid #364c59;
}

/* icon coloring */
.pre-start-report .hxCardIcon {
  stroke: green;
  height: 2.5rem;
}

.pre-start-report.old .hxCardIcon {
  stroke: orange;
}

.pre-start-report.errors .hxCardIcon {
  stroke: red;
}

/* title text */
.pre-start-report .hxCardHeaderWrapper {
  font-size: 1.5rem;
}

.pre-start-report .title-post {
  text-transform: capitalize;
  display: flex;
  flex-direction: row;
  margin-left: 1rem;
}

.pre-start-report .title-post .value {
  line-height: 1.5rem;
  margin-left: 1rem;
}

.pre-start-report .gap-left {
  margin-left: 1rem;
}

/* criteria effects */
.pre-start-report .dim {
  opacity: 0.5;
}

.pre-start-report.old .submission-time {
  color: orange;
}

/* open/close chevron */
.pre-start-report .chevron-icon,
.pre-start-report .edit-icon {
  margin-right: 0.25rem;
  height: 1.25rem;
  width: 1.25rem;
  cursor: pointer;
}

.pre-start-report .pre-start-viewer {
  margin: auto;
  max-width: 60rem;
  margin-bottom: 2rem;
}
</style>