<template>
  <div class="feed">
    <div class="feed-top-row">
      <FeedHeader :selectedAsset="selectedAsset" @search-change="onSearchChange" />
    </div>
    <div class="feed-bottom-row">
      <EntryList :events="filteredEvents" />
    </div>
    <div v-if="selectedAsset" class="info-bar">
      <div class="time-info">
        <div v-if="activeAllocation" class="active-time-allocation" :class="timeAllocClass">
          <div class="time-code">
            {{ activeAllocation.groupName }} | {{ activeAllocation.name }}
          </div>
          <div class="duration">{{ duration }}</div>
        </div>
      </div>
      <div class="actions">
        <icon v-tooltip="'Edit Allocation'" :icon="editIcon" @click="onEdit" />
        <icon
          v-if="preStartSubmission"
          v-tooltip="'Pre-Start'"
          :icon="reportIcon"
          @click="onOpenPreStart"
        />
      </div>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import FeedHeader from './header/FeedHeader.vue';
import EntryList from './entries/EntryList.vue';

import PreStartSubmissionModal from '@/components/modals/PreStartSubmissionModal.vue';

import { attributeFromList, isInText } from '../../../code/helpers';
import { formatSeconds, divMod } from '../../../code/time';

import EditIcon from '../../icons/Edit.vue';
import ReportIcon from '../../icons/Report.vue';

const SECONDS_IN_DAY = 3600 * 24;

function filterEventsByText(events, text) {
  return events.filter(e => {
    if (e.eventType === 'date-separator') {
      return true;
    }
    if (!e.searchable) {
      return false;
    }
    return e.searchable.some(field => isInText(e[field], text));
  });
}

export default {
  name: 'Feed',
  components: {
    Icon,
    FeedHeader,
    EntryList,
  },
  props: {
    selectedAsset: { type: Object, default: null },
    events: { type: Array, default: () => [] },
    preStartSubmissions: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      editIcon: EditIcon,
      reportIcon: ReportIcon,
      search: '',
      now: new Date(),
      nowInterval: null,
    };
  },
  mounted() {
    this.nowInterval = setInterval(() => {
      this.now = new Date();
    }, 1000);
  },
  beforeDestroy() {
    clearInterval(this.nowInterval);
  },
  computed: {
    filteredEvents() {
      if (this.search === '') {
        return this.events;
      }
      return filterEventsByText(this.events, this.search);
    },
    activeAllocation() {
      const alloc = (this.selectedAsset || {}).activeTimeAllocation;
      if (!alloc || !alloc.id) {
        return null;
      }

      return alloc;
    },
    timeAllocClass() {
      return (this.activeAllocation || {}).groupName === 'Ready' ? 'ready' : 'exception';
    },
    duration() {
      if (!this.activeAllocation) {
        return null;
      }
      const seconds = Math.abs(Math.trunc((this.now - this.activeAllocation.startTime) / 1000));

      const [days, remainder] = divMod(seconds, SECONDS_IN_DAY);

      let daysStr = '';
      if (days > 0) {
        daysStr = days === 1 ? '1 day ' : `${days} days `;
      }
      return `${daysStr}${formatSeconds(remainder)}`;
    },
    preStartSubmission() {
      if (!this.selectedAsset) {
        return null;
      }
      return attributeFromList(this.preStartSubmissions, 'assetId', this.selectedAsset.id);
    },
  },
  methods: {
    onSearchChange(text) {
      this.search = text;
    },
    onEdit() {
      this.$eventBus.$emit('asset-assignment-open', this.selectedAsset.id);
    },
    onOpenPreStart() {
      this.$modal.create(PreStartSubmissionModal, { submission: this.preStartSubmission });
    },
  },
};
</script>

<style>
/* ---- confirm modal container ---- */
.feed .confirm-modal .modal-container-wrapper {
  padding: 4% 10%;
  height: auto;
}

.feed .confirm-modal .modal-container {
  padding: 2rem;
  background: #23343f;
}

/* ---- other ---- */
.feed {
  display: flex;
  flex-flow: column;
  height: 100%;
  color: #b6c3cc;
}

.feed-top-row {
  flex: 0 1 auto;
}

.feed-bottom-row {
  flex: 1 1 auto;
  min-height: 0;
}

.feed .info-bar {
  display: flex;
  width: 100%;
  height: 2rem;
}

.feed .info-bar .actions {
  display: flex;
}

.feed .info-bar .actions .hx-icon {
  margin: 0 0.25rem;
  cursor: pointer;
  width: 1.5rem;
}

.feed .info-bar .time-info {
  width: calc(100% - 2rem);
}

.feed .info-bar .active-time-allocation {
  display: flex;
  width: 100%;
  line-height: 2rem;
  justify-content: space-between;
}

.feed .info-bar .active-time-allocation .time-code {
  margin-left: 1rem;
}

.feed .info-bar .active-time-allocation .duration {
  margin-right: 1rem;
}

.feed .info-bar .ready {
  background-color: rgba(0, 128, 0, 0.158);
}

.feed .info-bar .exception {
  background-color: rgba(150, 85, 0, 0.233);
}
</style>