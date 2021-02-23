<template>
  <hxCard class="pre-start-report" :icon="icon">
    <div class="title-post" slot="title-post">
      <div class="submission-time">{{ asset.name }} ({{ formatTime(submission.timestamp) }})</div>
      <div class="status gap-left">
        <div v-if="crossCount > 0" class="red-text">Fail</div>
        <div v-else class="green-text">Pass</div>
      </div>
      <Icon
        v-tooltip="'Open Pre-Start'"
        class="info-icon gap-left"
        :icon="infoIcon"
        @click="onShowViewer()"
      />
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
import { todayRelativeFormat } from '@/code/time';
import { attributeFromList } from '@/code/helpers';

export default {
  name: 'PreStartReport',
  components: {
    hxCard,
    Icon,
  },
  props: {
    submission: { type: Object, required: true },
    assets: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
  },
  data: () => {
    return {
      infoIcon: InfoIcon,
      crossIcon: CrossIcon,
      tickIcon: TickIcon,
      show: false,
    };
  },
  computed: {
    asset() {
      return attributeFromList(this.assets, 'id', this.submission.assetId) || {};
    },
    icon() {
      return this.icons[this.asset.type];
    },
    controls() {
      return this.submission.form.sections.map(s => s.controls).flat();
    },
    crossCount() {
      return this.controls.filter(c => c.answer === false).length;
    },
  },
  methods: {
    onShowViewer() {
      this.$modal.create(PreStartSubmissionModal, { submission: this.submission });
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

/* icon coloring */
.pre-start-report .hxCardIcon {
  height: 2.5rem;
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

.pre-start-report .info-icon:hover {
  opacity: 0.5;
}
</style>