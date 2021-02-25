<template>
  <hxCard class="pre-start-report" :icon="icon">
    <div class="title-post" slot="title-post">
      <div class="submission-time">
        {{ asset.name }} ({{ formatTime(latestSubmission.timestamp) }})
      </div>
      <div class="status gap-left">
        <div v-if="failCount > 0" class="red-text">Fail</div>
        <div v-else class="green-text">Pass</div>
      </div>
      <Icon
        v-if="latestSubmission"
        v-tooltip="'Open Pre-Start'"
        class="info-icon gap-left"
        :icon="infoIcon"
        @click="onOpenViewer(latestSubmission)"
      />
      <Icon
        v-if="submissions.length > 1"
        v-tooltip="showSubmissions ? 'Show Less' : 'Show More'"
        class="chevron-icon gap-left"
        :icon="chevronIcon"
        :rotation="showSubmissions ? 270 : 90"
        @click="toggleShowSubmissions"
      />
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

function getFailCount(form) {
  return form.sections
    .map(s => s.controls)
    .flat()
    .filter(c => c.answer === false).length;
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
    failCount() {
      return getFailCount(this.latestSubmission.form);
    },
    allSubmissions() {
      const subs = this.submissions.slice();

      subs.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());

      return subs.map(s => {
        const isFail = getFailCount(s.form);
        return {
          class: isFail ? 'fail' : '',
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
      this.$modal.create(PreStartSubmissionModal, { submission });
    },
    formatTime(date) {
      return formatDateIn(date, { format: 'HH:mm' });
    },
  },
};
</script>

<style>
@import '../../../assets/textColors.css';

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
  width: 3rem;
  text-align: center;
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

.pre-start-report .info-icon:hover {
  opacity: 0.5;
}

/* other submissions */
.pre-start-report .all-submissions {
  margin-bottom: 1rem;
}

.pre-start-report .all-submissions .hx-btn {
  width: 6rem;
  margin: 0 0.1rem;
}

.pre-start-report .all-submissions .fail {
  background-color: rgba(139, 0, 0, 0.644);
}
</style>