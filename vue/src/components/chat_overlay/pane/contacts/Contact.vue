<template>
  <div class="contact" :class="highlightClass" @click="emitSelect">
    <table class="contact-layout">
      <tr class="first-row">
        <td class="icon-wrapper">
          <NIcon
            class="asset-icon"
            :class="asset.status"
            :icon="icon"
            :secondaryIcon="secondaryIcon"
          />
        </td>
        <td class="asset-name">
          {{ asset.name }}
        </td>
        <td class="message-count">
          <Bubble v-if="nUnreadMsgs !== 0">{{ nUnreadMsgs }}</Bubble>
        </td>
      </tr>
      <tr class="operator-row">
        <td colspan="3" class="operator-name" :class="{ 'has-operator': asset.operator.shortname }">
          {{ asset.operator.shortname || '\u200B' }}
        </td>
      </tr>
      <tr class="allocation-row">
        <td colspan="3" class="active-allocation">
          {{ activeTimeCodeName || '--' }}
        </td>
      </tr>
    </table>
  </div>
</template>

<script>
import NIcon from '@/components/NIcon.vue';
import Bubble from '@/components/Bubble.vue';

import { getAssetTileSecondaryIcon } from '@/code/common';

export default {
  name: 'Contact',
  components: {
    NIcon,
    Bubble,
  },
  props: {
    asset: { type: Object, required: true },
    highlight: { type: Boolean, default: false },
  },
  computed: {
    icon() {
      return this.$store.state.constants.icons[this.asset.type];
    },
    activeTimeAllocation() {
      return this.asset.activeTimeAllocation || {};
    },
    nUnreadMsgs() {
      return this.asset.unreadMessages;
    },
    activeTimeCodeName() {
      return this.activeTimeAllocation.name;
    },
    secondaryIcon() {
      return getAssetTileSecondaryIcon(this.asset);
    },
    truckColor() {
      const asset = this.asset;
      if (asset.activeTimeAllocation.id && !asset.activeTimeAllocation.isReady) {
        return 'exception-icon';
      }
      if (asset.present) {
        return 'green-icon';
      }
      return 'grey-icon';
    },
    highlightClass() {
      if (this.highlight === true) {
        return 'highlight';
      }
      return '';
    },
  },
  methods: {
    emitSelect() {
      this.$emit('select', this.asset);
    },
  },
};
</script>

<style>
@import '../../../../assets/iconColors.css';

.contact {
  border: #425866 solid 2px;
  background-color: #121f26;
  color: #b6c3cc;
  cursor: pointer;
  user-select: none;
}

.contact.highlight {
  border-color: #b6c3cc;
  background-color: #2c404c;
}

.contact:hover {
  transition: background 0.4s, border-color 0.4s, color 0.4s;
  background-color: #2c404c;
}

.contact .contact-layout {
  width: 100%;
  height: 100%;
  table-layout: fixed;
}

.contact .asset-name,
.contact .operator-name,
.contact .active-allocation {
  text-align: center;
}

.contact .operator-name.has-operator {
  background-color: #0080006e;
}

.contact .asset-icon {
  height: 3rem;
  width: auto;
  padding: 0.5rem;
}

.contact .asset-icon .custom-icon {
  stroke-width: 1.5;
}

.contact .bubble-wrapper {
  height: 1.5rem;
  width: 1.5rem;
}
</style>