<template>
  <v-popover
    v-if="asset"
    class="asset-tile"
    :class="tileClasses"
    :disabled="disablePopover"
    :open.sync="showPopover"
    trigger="hover"
    placement="top"
    :delay="{ show: 400, hide: 0 }"
    @mouseover.native="hovering = true"
    @mouseleave.native="hovering = false"
  >
    <!-- Assignment Icon (overlayed) -->
    <div v-show="hovering" class="assignment-bubble" @click="onOpenAssignment">
      <Icon :icon="listIcon" />
    </div>

    <!-- message bubble (overlayed) -->
    <Bubble
      v-show="hasDevice && (hovering || nUnreadMsgs || nUnreadDispatcherMsgs)"
      class="message-bubble"
      :class="unreadDispatcherMessageClass"
      :color="bubbleColor"
      @click="onOpenMessages"
    >
      {{ nUnreadMsgs }}
    </Bubble>

    <div class="asset-icon-wrapper" :class="assetIconClass">
      <NIcon class="asset-icon" :icon="icon" :secondaryIcon="secondaryIcon" />
    </div>

    <!-- location if available -->
    <div class="icon-bar location-name">
      <!-- The empty space is to make sure the div maintains height -->
      {{ locationName || '\u200B' }}
    </div>

    <!-- Operator name -->
    <div class="icon-bar">
      <!-- The empty space is to make sure the div maintains height -->
      {{ asset.operator.shortname || '\u200B' }}
    </div>

    <!-- Asset name -->
    <div class="icon-bar" :class="assetBarClass">
      {{ asset.name || '--' }}
    </div>

    <!-- tooltip area -->
    <div class="__asset-tile-popover" slot="popover" @mouseenter="showPopover = false">
      <AssetTilePopover :asset="asset" :track="track" :showAlert="showAlert" />
    </div>
  </v-popover>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import NIcon from '@/components/NIcon.vue';
import Bubble from '@/components/Bubble.vue';
import AssetTilePopover from './AssetTilePopover.vue';
import { attributeFromList } from '@/code/helpers';
import { isMissingException } from '@/store/modules/haul_truck';

import ListIcon from '@/components/icons/List.vue';
import AlertIcon from '@/components/icons/Alert.vue';
import TabletIcon from '@/components/icons/Tablet.vue';

const FLASH_DURATION = 10;

function getAndResolveExternalUpdateClass(asset) {
  if (asset.updatedExternally === true) {
    // this is to make the element flash a colour
    setTimeout(() => (asset.updatedExternally = false), FLASH_DURATION);
    return 'tile-updated';
  }
  return '';
}

function getDesyncedClass(asset) {
  return asset.synced === false ? 'tile-desynced' : '';
}

export default {
  name: 'AssetTile',
  components: {
    Icon,
    NIcon,
    Bubble,
    AssetTilePopover,
  },
  props: {
    asset: { type: Object, required: true },
    disablePopover: { type: Boolean, default: false },
  },
  data: () => {
    return {
      listIcon: ListIcon,
      showPopover: false,
      hovering: false,
    };
  },
  computed: {
    hasDevice() {
      return !!this.asset.deviceId;
    },
    secondaryIcon() {
      if (!this.hasDevice) {
        return TabletIcon;
      }

      if (this.showAlert) {
        return AlertIcon;
      }
    },
    icon() {
      return this.$store.state.constants.icons[this.asset.type];
    },
    locations() {
      return this.$store.state.constants.locations;
    },
    nUnreadMsgs() {
      return this.$store.state.operatorMessages.filter(
        m => !m.acknowledged && m.assetId === this.asset.id,
      ).length;
    },
    nUnreadDispatcherMsgs() {
      return this.$store.getters.unreadDispatcherMessages.filter(m => m.assetId === this.asset.id)
        .length;
    },
    track() {
      const tracks = this.$store.state.trackStore.tracks;
      return attributeFromList(tracks, 'assetId', this.asset.id);
    },
    assetBarClass() {
      const asset = this.asset;
      if (asset.type === 'Haul Truck' && asset.operator.id) {
        return asset.dispatch.acknowledged ? 'asset-bar-green' : 'asset-bar-orange';
      }

      return '';
    },
    bubbleColor() {
      return this.nUnreadMsgs ? 'yellow' : 'grey';
    },
    unreadDispatcherMessageClass() {
      return this.nUnreadDispatcherMsgs > 0 ? 'yellow-border' : '';
    },
    tileClasses() {
      return [getDesyncedClass(this.asset), getAndResolveExternalUpdateClass(this.asset)];
    },
    assetIconClass() {
      const asset = this.asset;
      const alloc = asset.activeTimeAllocation || {};
      if (alloc.id && !alloc.isReady) {
        return 'exception-icon';
      }

      if (asset.present) {
        return 'ok-icon';
      }

      return 'offline-icon';
    },
    locationName() {
      const activity = this.asset.activity || {};
      return attributeFromList(this.locations, 'id', activity.locationId, 'name');
    },
    showAlert() {
      const hasAsset = this.asset && this.asset.id;
      const hasTrack = this.track && this.track.assetId;
      return (
        hasAsset &&
        hasTrack &&
        this.asset.type === 'Haul Truck' &&
        isMissingException(
          this.asset.activeTimeAllocation,
          (this.track.location || {}).type,
          this.track.timestamp,
        )
      );
    },
  },
  methods: {
    onOpenMessages() {
      const opts = {
        scroll: 'bottom',
        assetId: this.asset.id,
      };

      this.$eventBus.$emit('chat-open', opts);
    },
    onOpenAssignment() {
      this.$eventBus.$emit('asset-assignment-open', this.asset.id);
    },
  },
};
</script>

<style>
.asset-tile {
  min-height: 7rem;
  width: 7rem;
  background-color: #111c22;
  user-select: none;
  transition: background-color 1.5s ease-in-out;
  position: relative;
}

.asset-tile > .trigger {
  height: 100%;
  width: 100%;
}

/* --- tile colors ---- */
.asset-tile.tile-desynced {
  background-color: #64646480 !important;
}

.asset-tile.tile-updated {
  background-color: #184ba280 !important;
}

/* --- asset icon --- */
.asset-tile .asset-icon {
  padding-top: 0.75rem;
  height: 4.75rem;
  width: 100%;
}

.asset-tile .asset-icon .asset-icon-svg {
  stroke-width: 1;
}

.asset-tile .asset-icon .secondary-icon #alert_icon {
  stroke-width: 2;
  stroke: orange;
}

.asset-tile .asset-icon .secondary-icon #tablet_icon {
  stroke-width: 0.5;
  stroke: orange;
  stroke-dasharray: 1;
}

/* -- operator/asset names */
.asset-tile .icon-bar {
  text-align: center;
}

.asset-tile .icon-bar.asset-bar-orange {
  background-color: #ffa50085;
}

.asset-tile .icon-bar.asset-bar-green {
  background-color: #0080006e;
}

.asset-tile .location-name {
  font-size: 0.75rem;
  overflow: hidden;
}

/* ---- assignment bubble ----- */
.asset-tile .assignment-bubble {
  position: absolute;
  z-index: 5;
  top: 0px;
  left: 2px;
  cursor: pointer;
  padding: 0.25rem;
}

.asset-tile .assignment-bubble .hx-icon {
  width: 1.5rem;
  height: 1.5rem;
}

/* ---- message bubble ---- */
.asset-tile .message-bubble {
  position: absolute;
  z-index: 5;
  top: 5px;
  right: 5px;
  cursor: pointer;
}

.asset-tile .message-bubble.yellow-border .bubble {
  border: 2px solid yellow;
}
</style>