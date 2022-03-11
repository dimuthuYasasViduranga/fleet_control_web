<template>
  <modal class="chat-overlay" :show="show" @close="close()">
    <div class="chat-overlay-layout">
      <div class="left-pane">
        <Pane
          :selectedAsset="selectedAsset"
          :assets="fullAssets"
          @contact-select="onContactSelect"
          @all-assets="onAllAssetsSelect"
        />
      </div>
      <div class="right-pane">
        <div class="feed-wrapper">
          <Feed
            :selectedAsset="selectedAsset"
            :events="filteredEvents"
            :preStartSubmissions="preStartSubmissions"
          />
        </div>
        <div class="message-wrapper" :class="msgBoxSizeClass">
          <MessageBox :selectedAsset="selectedAsset" :assets="fullAssets" />
        </div>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from '../modals/Modal.vue';
import MessageBox from './message_box/MessageBox.vue';
import Pane from './pane/Pane.vue';
import Feed from './feed/Feed.vue';
import { chunkEvery } from '@/code/helpers';
import { copyDate } from '@/code/time';

function filterOnAsset(events, asset) {
  if (!asset) {
    return events;
  }
  return events.filter(e => e.assetId === asset.id || (e.assetIds || []).includes(asset.id));
}

function filterOnEventToggle(events, { messages, haulDispatches, logins, timeAllocations }) {
  let filterOut = [];
  filterOut.push(getFilterType('messages', messages));
  filterOut.push(getFilterType('haul-dispatches', haulDispatches));
  filterOut.push(getFilterType('logins', logins));
  filterOut.push(getFilterType('time-allocations', timeAllocations));
  filterOut = filterOut.flat();

  const filteredEvents = events.filter(e => !filterOut.includes(e.eventType));
  return removeAdjacentDateSeparators(filteredEvents);
}

function removeAdjacentDateSeparators(events) {
  return chunkEvery(events, 2, 1, [null])
    .map(([prev, cur]) => {
      if (cur && prev.eventType === 'date-separator' && cur.eventType === 'date-separator') {
        return null;
      }

      return prev;
    })
    .filter(e => e);
}

function getFilterType(filter, bool) {
  switch (filter) {
    case 'messages':
      return boolToValue(bool, null, [
        'operator-message',
        'dispatcher-message',
        'dispatcher-mass-message',
      ]);
    case 'time-allocations':
      return boolToValue(bool, null, 'time-allocation');
    case 'haul-dispatches':
      return boolToValue(bool, null, ['haul-truck-dispatch', 'haul-truck-mass-dispatch']);
    case 'logins':
      return boolToValue(bool, null, ['login', 'logout', 'device-assigned', 'device-unassigned']);
    default:
      return null;
  }
}

function boolToValue(bool, onTrue, onFalse = null) {
  if (bool === true) {
    return onTrue;
  }
  return onFalse;
}

function copyFullAsset(asset) {
  const copy = JSON.parse(JSON.stringify(asset));
  copy.activeTimeAllocation.startTime = copyDate(asset.activeTimeAllocation.startTime);
  copy.activeTimeAllocation.endTime = copyDate(asset.activeTimeAllocation.endTime);
  copy.deviceAssignedAt = copyDate(asset.deviceAssignedAt);
  return copy;
}

export default {
  name: 'ChatOverlay',
  components: {
    Modal,
    MessageBox,
    Pane,
    Feed,
  },
  data: () => {
    return {
      show: false,
      selectedAsset: null,
      showEvents: {
        messages: true,
        haulDispatches: true,
        timeAllocations: false,
        logins: false,
      },
    };
  },
  computed: {
    operatorMessages() {
      return this.$store.getters.operatorMessages;
    },
    fullAssets() {
      return this.$store.getters.fullAssets
        .filter(fa => fa.deviceId)
        .map(fa => {
          const asset = copyFullAsset(fa);
          const nUnread = this.operatorMessages.filter(
            o => o.assetId === fa.id && !o.acknowledged,
          ).length;
          asset.unreadMessages = nUnread;
          return asset;
        });
    },
    events() {
      const tz = this.$timely.current.timezone;
      return this.$store.getters.events(tz);
    },
    filteredEvents() {
      let events = this.events;
      events = filterOnAsset(events, this.selectedAsset);
      events = filterOnEventToggle(events, this.showEvents);
      return events;
    },
    msgBoxSizeClass() {
      return this.selectedAsset ? '' : 'reduced';
    },
    preStartSubmissions() {
      return this.$store.state.currentPreStartSubmissions;
    },
  },
  watch: {
    fullAssets(newAssets) {
      // on devices updating, set selected device
      if (!this.selectedAsset || !newAssets) {
        return;
      }
      const newSelected = newAssets.find(na => na.id === this.selectedAsset.id);
      this.selectedAsset = newSelected;
    },
  },
  created() {
    this.setAction('chat-open', this.open);
    this.setAction('feed-filter-changed', this.onSetFeedFilter);
  },
  mounted() {
    const filters = this.showEvents;
    ['messages', 'timeAllocations', 'haulDispatches', 'logins'].forEach(name => {
      this.alongEventBus('set-feed-filter', { filter: name, state: filters[name] });
    });
  },
  methods: {
    setAction(action, callback) {
      this.$eventBus.$on(action, callback);
    },
    alongEventBus(action, event) {
      this.$eventBus.$emit(action, event);
    },
    getAsset(assetId) {
      return this.fullAssets.find(a => a.id === assetId);
    },
    open(opts) {
      this.$store.commit('setOverlayOpen', true);
      this.show = true;
      setTimeout(() => this.enactOptions(opts));
    },
    close() {
      this.$store.commit('setOverlayOpen', false);
      this.show = false;
    },
    onContactSelect(asset) {
      this.selectedAsset = asset;
      this.alongEventBus('feed-scroll', 'bottom');
    },
    onAllAssetsSelect() {
      this.selectedAsset = null;
      this.alongEventBus('feed-scroll', 'bottom');
    },
    onSetFeedFilter({ filter, state }) {
      this.showEvents[filter] = state;
    },
    enactOptions(opts) {
      if (!opts) {
        return;
      }

      if (opts.scroll) {
        this.alongEventBus('feed-scroll', opts.scroll);
      }

      if (opts.assetId === 'all' || !opts.assetId) {
        this.selectedAsset = null;
      } else if (opts.assetId) {
        this.selectedAsset = this.getAsset(opts.assetId);
      }
    },
  },
};
</script>

<style>
.chat-overlay {
  margin: auto;
  font-family: 'GE Inspira Sans', sans-serif;
}

/* --------- modal patches ------------- */
.chat-overlay .modal-container-wrapper {
  height: 100%;
  padding: 2rem 3rem;
}

.chat-overlay .modal-container {
  padding: 0.5rem;
  background-color: #121f26;
}

/* ----------- layout ---------------- */
.chat-overlay .chat-overlay-layout {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: row;
}

.chat-overlay .left-pane {
  min-width: 120px;
  width: 200px;
  height: 100%;
}

.chat-overlay .right-pane {
  width: 100%;
  display: flex;
  flex-flow: column;
}

.chat-overlay .right-pane .feed-wrapper {
  flex: 1 1 auto;
  min-height: 0;
}

.chat-overlay .right-pane .message-wrapper {
  flex: 0 0 5rem;
  border-top: 2px solid #425866;
}

.chat-overlay .right-pane .message-wrapper.reduced {
  flex: none;
}

@media screen and (max-width: 625px) {
  .message-box .single-msg .button-clear {
    display: none;
  }

  .contact .circle {
    height: 1rem;
    width: 1rem;
    font-size: 0.75rem;
  }
}

@media screen and (max-width: 525px) {
  .message-box .button-send {
    display: none;
  }
}
</style>