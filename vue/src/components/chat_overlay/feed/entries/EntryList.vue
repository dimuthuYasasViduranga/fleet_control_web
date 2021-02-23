<template>
  <div class="entry-list">
    <scrollable ref="scrollable">
      <template v-if="events.length > 0">
        <Entry v-for="(entry, index) in events" :key="index" :entry="entry" />
      </template>
      <GeneralEvent v-else message="No messages in the last 12 hours" />
    </scrollable>
  </div>
</template>

<script>
import Scrollable from './../../../Scrollable.vue';
import Entry from './Entry.vue';
import GeneralEvent from './entry_types/GeneralEvent.vue';

function equalEntry(entry1, entry2) {
  if (!entry1 && !entry2) {
    return true;
  }

  if (!entry1 || !entry2) {
    return false;
  }

  return entry1.id === entry2.id;
}

export default {
  name: 'EntryList',
  components: {
    Scrollable,
    Entry,
    GeneralEvent,
  },
  props: {
    events: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      prevLastEntry: null,
      prevEntryCount: 0,
    };
  },
  watch: {
    events(newEvents, oldEvents) {
      if (newEvents.length > 0 && oldEvents.length === 0) {
        // set the scroll to bottom when going from no data to data
        this.onScrollbar('scrollBottom');
      }
      // this is a fix only, might not work when selecting other assets
      // will eventually want a timeout so that if they are scrolling, dont auto jump down,
      // instead, show a popup that says "new messages, or something like that"
      const entryCount = newEvents.length;
      const lastEntry = newEvents[entryCount - 1];
      if (equalEntry(lastEntry, this.lastEntry) || entryCount !== this.prevEntryCount) {
        this.onScrollbar('scrollBottom');
      }

      this.prevLastEntry = lastEntry;
      this.prevEntryCount = entryCount;
    },
  },
  created() {
    this.setAction('feed-scroll', this.setScroll);
  },
  methods: {
    scrollbar() {
      return this.$refs.scrollable;
    },
    onScrollbar(action, args) {
      const scrollbar = this.scrollbar();
      if (scrollbar) {
        scrollbar[action](args);
      }
    },
    setAction(action, callback) {
      this.$eventBus.$on(action, callback);
    },
    setScroll(level) {
      switch (level) {
        case 'bottom':
          this.onScrollbar('scrollBottom');
          break;
        case 'top':
          this.onScrollbar('scrollTop');
          break;
        default:
          console.error('Scroll of value not implemented');
          break;
      }
    },
  },
};
</script>

<style>
.entry-list .ps {
  height: 100%;
}

.entry-list {
  height: 100%;
}
</style>