<template>
  <div class="feed-filter">
    <div class="toggles">
      <div
        class="toggle-btn"
        v-for="{ name, icon, tooltip } in filters"
        :key="name"
        v-tooltip="{ content: tooltip }"
        :class="disabledClass(name)"
        @click="toggle(name)"
      >
        <Icon :icon="icon" />
      </div>
    </div>
    <div class="search-wrapper">
      <SearchBar placeholder="Search Feed" v-model="search" :showClear="false" />
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import SearchBar from './../../../SearchBar.vue';

import HaulTruckIcon from '../../../icons/asset_icons/HaulTruck.vue';
import TimeIcon from '../../../icons/Time.vue';
import ChatIcon from '../../../icons/Chat.vue';
import TabletIcon from '../../../icons/Tablet.vue';

export default {
  name: 'FeedFilter',
  components: {
    Icon,
    SearchBar,
  },
  data: () => {
    return {
      search: '',
      show: {
        messages: true,
        haulDispatches: true,
        logins: true,
        timeAllocations: true,
      },
      filters: [
        { name: 'messages', icon: ChatIcon, tooltip: 'Messages' },
        { name: 'haulDispatches', icon: HaulTruckIcon, tooltip: 'Haul Dispatches' },
        { name: 'logins', icon: TabletIcon, tooltip: 'Logins/Device Assignments' },
        { name: 'timeAllocations', icon: TimeIcon, tooltip: 'Time Allocations' },
      ],
    };
  },
  watch: {
    search(newText) {
      this.$emit('search-change', newText);
    },
  },
  created() {
    this.$eventBus.$on('set-feed-filter', this.setFeedFilter);
  },
  methods: {
    setFeedFilter({ filter, state }) {
      this.show[filter] = state;
      this.sendFilter(filter);
    },
    disabledClass(name) {
      if (this.show[name] === false) {
        return 'disabled';
      }
      return '';
    },
    toggle(name) {
      this.show[name] = !this.show[name];
      this.sendFilter(name);
    },
    sendFilter(name) {
      const state = this.show[name];
      this.$eventBus.$emit('feed-filter-changed', { filter: name, state });
    },
  },
};
</script>

<style>
@import '../../../../assets/hxInput.css';

.feed-filter {
  height: 100%;
  display: flex;
  flex-direction: row;
  border-bottom: 3px solid #1b2a33;
}

.feed-filter .toggles {
  flex: 1 0 auto;
  display: flex;
  flex-direction: row;
  justify-content: space-around;
}

.feed-filter .toggles .toggle-btn {
  cursor: pointer;
  width: 100%;
  background-color: #425866;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
}

.feed-filter .toggles .toggle-btn:hover {
  opacity: 0.75;
}

.feed-filter .toggles .toggle-btn .hx-icon {
  padding: 0.2rem;
  margin: auto;
}

.feed-filter .toggles .toggle-btn.disabled {
  opacity: 0.5;
}

.feed-filter .search-wrapper {
  flex: 1 1 auto;
  max-width: 15rem;
  padding: 0.1rem 0.25rem;
}

.feed-filter .hx-btn {
  height: 100%;
  padding: 0rem;
  margin-right: 0.4rem;
  border-bottom: none;
  width: 100%;
}

.search-wrapper .search-bar {
  margin: 0;
}

.toggles .hx-btn.disabled {
  opacity: 0.5;
}

@media screen and (max-width: 600px) {
  .search-wrapper {
    display: none;
  }

  .feed-filter .toggles {
    font-size: 0.75rem;
  }
}
</style>