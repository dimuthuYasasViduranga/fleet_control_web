<template>
  <hxCard class="pre-start-concern" :icon="icon">
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

        <div v-if="submission.comments" class="overall-comments">
          {{ submission.comments }}
        </div>

        <div
          class="control"
          v-for="(control, cIndex) in submission.controls"
          :key="cIndex"
          :class="control.status"
        >
          <div class="outline">
            <div class="label">{{ control.label }}</div>
            <div class="answer">
              <div v-if="control.status === 'pass'" class="pass-answer">Pass</div>
              <div v-else-if="control.status === 'na'" class="na-answer">N/A</div>
              <div v-else-if="control.status === 'fail'" class="fail-answer">Fail</div>
              <div v-else class="ticket-status" :class="control.status">{{ control.status }}</div>
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

import { formatDateIn, isSameDownTo } from '@/code/time';

import ChevronIcon from '@/components/icons/ChevronRight.vue';
import InfoIcon from '@/components/icons/Info.vue';

function breakdownText(counts) {
  const order = ['pass', 'na', 'fail', 'closed', 'pending-verification', 'planned', 'raised'];

  return order
    .reduce((acc, key) => {
      if (counts[key]) {
        acc.push(`${key}: ${counts[key]}`);
      }

      return acc;
    }, [])
    .join(' | ');
}

export default {
  name: 'PreStartConcern',
  components: {
    hxCard,
    Icon,
  },
  props: {
    assetName: { type: String, required: true },
    icon: { type: Object, default: null },
    submissions: { type: Array, default: () => [] },
    useFullTimestamp: { type: Boolean, default: false },
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
        .map(s => s.controls)
        .flat()
        .reduce((acc, c) => {
          acc[c.status] = (acc[c.status] || 0) + 1;
          return acc;
        }, {});
      return breakdownText(counts);
    },
  },
  methods: {
    toggleShow() {
      this.show = !this.show;
    },
    formatTime(date) {
      const now = new Date();
      const tz = this.$timely.current.timezone;
      const isToday = isSameDownTo(date, now, tz, 'day');
      if (isToday || !this.useFullTimestamp) {
        return formatDateIn(date, tz, { format: 'HH:mm' });
      }

      const isSameYear = isSameDownTo(date, now, tz, 'year');
      if (isSameYear) {
        return formatDateIn(date, tz, { format: 'LLL-dd HH:mm' });
      }

      return formatDateIn(date, tz, { format: 'yyyy LLL-dd HH:mm' });
    },
    onOpenViewer(submission) {
      this.$modal.create(PreStartSubmissionModal, { submission }).onClose(resp => {
        if (resp === 'refresh') {
          this.$emit('refresh');
        }
      });
    },
  },
};
</script>

<style>
/* hxCard styling */
.pre-start-concern.hxCardIcon {
  height: 2.5rem;
}

.pre-start-concern.hxCard {
  border-left: 2px solid transparent;
}

.pre-start-concern .hxCardIcon {
  height: 2.5rem;
}

.pre-start-concern .hxCardHeaderWrapper {
  font-size: 1.5rem;
}

.pre-start-concern .title-post {
  text-transform: capitalize;
  display: flex;
  margin-left: 1rem;
  height: 2rem;
  line-height: 2rem;
}

.pre-start-concern .title-post .chevron-icon {
  margin-left: 1rem;
  margin-top: 0.25rem;
  height: 1.5rem;
  width: 1.5rem;
  padding: 0.1rem;
  cursor: pointer;
}

/* submissions */
.pre-start-concern .submission {
  margin-bottom: 0.75rem;
}

.pre-start-concern .submission .identifier {
  display: flex;
  justify-content: space-around;
  padding: 0.25rem;
  font-size: 1.25rem;
  background-color: #425866;
  color: #c4d1da;
}

.pre-start-concern .submission .identifier .info-icon {
  height: 1.25rem;
  cursor: pointer;
}

.pre-start-concern .submission .identifier .info-icon:hover {
  opacity: 0.5;
}

.pre-start-concern .submission .overall-comments {
  border-top: 1px solid #364c59;
  background-color: #344652;
  line-height: 1.5rem;
  padding-left: 2rem;
}

/* controls */
.pre-start-concern .submission .control {
  padding-left: 0.5rem;
  min-height: 2.5rem;
  line-height: 2.5rem;
  border-bottom: 1px solid #677e8c;
  background-color: #16232b;
}

.pre-start-concern .control.fail {
  background-color: rgba(139, 0, 0, 0.281);
}

.pre-start-concern .control.closed {
  background-color: rgba(88, 88, 88, 0.281);
}

.pre-start-concern .control.raised,
.pre-start-concern .control.planned,
.pre-start-concern .control.pending {
  background-color: rgba(139, 67, 0, 0.281);
}

.pre-start-concern .submission .control .outline {
  display: grid;
  grid-template-columns: auto auto;
}

.pre-start-concern .submission .control .comment {
  margin-left: 2rem;
}

.pre-start-concern .submission .control .answer {
  font-weight: bold;
  font-size: 1.25rem;
  justify-self: right;
  padding-right: 1rem;
  text-transform: capitalize;
}

.pre-start-concern .submission .control .answer .fail-answer {
  color: red;
}

.pre-start-concern .submission .control .answer .pass-answer {
  color: green;
}

.pre-start-concern .submission .control .answer .na-answer {
  color: #737171;
}
</style>