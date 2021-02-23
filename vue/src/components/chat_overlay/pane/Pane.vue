<template>
  <div class="pane">
    <div class="contact-filter-wrapper">
      <ContactHeader
        :highlightLiveFeed="selectedAsset === null"
        @live-feed="onLiveFeed"
        @search-change="onSearchChange"
      />
    </div>
    <div class="contact-list-wrapper">
      <ContactList
        :assets="filteredAssets"
        :selectedAsset="selectedAsset"
        @select="onContactSelect"
      />
    </div>
  </div>
</template>

<script>
import ContactHeader from './header/ContactHeader.vue';
import ContactList from './contacts/ContactList.vue';
import { firstBy } from 'thenby';
import { isInText } from '../../../code/helpers';

function filterBySearch(assets, text) {
  if (text === '') {
    return assets;
  }

  return assets.filter(a => {
    const present = a.present ? 'online' : 'offline';

    return (
      isInText(a.name, text) ||
      isInText(a.operator.fullname || 'No Operator', text) ||
      isInText(present, text)
    );
  });
}

function getPriorityNumber(asset) {
  // this determines the order that assets are displayed in the contact list
  if (asset.unreadMessages > 0) {
    return 0;
  }
  if (asset.present === true) {
    return 1;
  }

  if (asset.activeTimeAllocation.isReady === false) {
    return 2;
  }

  return 3;
}

function getNUnreadMsgs(device) {
  return device.operatorMessages.filter(m => !m.acknowledge_id).length;
}

export default {
  name: 'Pane',
  components: {
    ContactHeader,
    ContactList,
  },
  props: {
    assets: { type: Array, default: () => [] },
    selectedAsset: { type: Object, default: () => null },
  },
  data: () => {
    return {
      search: '',
      filters: [{ unread: 'asc' }, { status: '' }],
    };
  },
  computed: {
    filteredAssets() {
      const assets = filterBySearch(this.assets, this.search);
      assets.sort(firstBy(a => getPriorityNumber(a)).thenBy('name'));
      return assets;
    },
  },
  methods: {
    setAction(action, callback) {
      this.$eventBus.$on(action, callback);
    },
    onContactSelect(asset) {
      this.$emit('contact-select', asset);
    },
    onLiveFeed() {
      this.$emit('all-assets');
    },
    onSearchChange(text) {
      this.search = text;
    },
  },
};
</script>

<style>
.pane {
  display: flex;
  flex-flow: column;
  height: 100%;
}

.pane .contact-filter-wrapper {
  flex: 0 1 auto;
  padding-bottom: 0.6rem;
}

.pane .contact-list-wrapper {
  min-height: 0;
  flex: 1 1 auto;
  height: 100%;
  background-color: #1b2a33;
}
</style>