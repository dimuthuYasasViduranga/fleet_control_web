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
    @contextmenu.native.prevent="onOpenContext"
  >
    <!-- Assignment Icon (overlayed) -->
    <div v-show="hovering" class="assignment-bubble" @click="onOpenAssignment()">
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

    <div class="asset-icon-wrapper">
      <NIcon class="asset-icon" :class="asset.status" :icon="icon" :secondaryIcon="secondaryIcon" />
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
      <AssetTilePopover :asset="asset" :track="track" />
    </div>
  </v-popover>
</template>

<script>
import { mapState } from 'vuex';

import Icon from 'hx-layout/Icon.vue';
import NIcon from '@/components/NIcon.vue';
import Bubble from '@/components/Bubble.vue';
import AssetTilePopover from './AssetTilePopover.vue';

import { attributeFromList } from '@/code/helpers';
import { getAssetTileSecondaryIcon } from '@/code/common';

import ListIcon from '@/components/icons/List.vue';

import DeviceLogoutModal from '@/components/modals/DeviceLogoutModal.vue';
import MapModal from '@/components/modals/MapModal.vue';

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
    ...mapState({
      operatorMessages: state => state.operatorMessages,
      tracks: state => state.trackStore.tracks,
    }),
    ...mapState('constants', {
      dimLocations: state => state.dimLocations,
      icons: state => state.icons,
    }),
    fullTimeCodes() {
      return this.$store.getters['constants/fullTimeCodes'];
    },
    hasDevice() {
      if (this.asset.hasDevice !== undefined) {
        return this.asset.hasDevice;
      }

      return !!this.asset.deviceId;
    },
    secondaryIcon() {
      return getAssetTileSecondaryIcon(this.asset);
    },
    icon() {
      return this.icons[this.asset.type] || this.icons.Unknown;
    },
    nUnreadMsgs() {
      return this.operatorMessages.filter(m => !m.acknowledged && m.assetId === this.asset.id)
        .length;
    },
    nUnreadDispatcherMsgs() {
      return this.$store.getters.unreadDispatcherMessages.filter(m => m.assetId === this.asset.id)
        .length;
    },
    track() {
      return attributeFromList(this.tracks, 'assetId', this.asset.id);
    },
    assetBarClass() {
      const asset = this.asset;
      if (asset.type === 'Haul Truck' && asset.operator.id && !asset.dispatch.acknowledged) {
        return 'asset-bar-orange';
      }

      return asset.operator.id ? 'asset-bar-green' : '';
    },
    bubbleColor() {
      return this.nUnreadMsgs ? 'yellow' : 'grey';
    },
    unreadDispatcherMessageClass() {
      return this.nUnreadDispatcherMsgs > 0 ? 'yellow-border' : '';
    },
    tileClasses() {
      const classes = [getDesyncedClass(this.asset), getAndResolveExternalUpdateClass(this.asset)];

      const queueInfo = this.asset.liveQueueInfo;

      if (this.asset.type === 'Haul Truck' && queueInfo) {
        classes.push(queueInfo.status);
      }

      if (this.asset.secondaryType === 'Dig Unit' && queueInfo) {
        if (queueInfo.active.length) {
          classes.push('loading');
        } else if (!queueInfo.queued.length) {
          classes.push('hang');
        }
      }

      return classes;
    },
    locationName() {
      const locationId = this.asset?.activity?.locationId;
      return attributeFromList(this.dimLocations, 'id', locationId, 'name');
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
    onOpenContext(mouseEvent) {
      const items = [
        { id: 'assignment', name: 'Edit Assignment' },
        { id: 'time-allocation', name: 'View Time Allocation' },
        { id: 'locate', name: 'Locate' },
      ];

      if (this.hasDevice) {
        items.splice(1, 0, { id: 'chat', name: 'View Chat Log' });
      }

      if (this.asset.operator && this.asset.operator.id && this.asset.deviceId) {
        items.push({ id: 'logout', name: 'Force Logout' });
      }

      this.$contextMenu.create('asset-tile', mouseEvent, items, { toggle: true }).then(resp => {
        if (!resp) {
          return;
        }

        switch (resp.id) {
          case 'assignment':
            this.onOpenAssignment();
            break;

          case 'chat':
            this.onOpenMessages();
            break;

          case 'time-allocation':
            this.$eventBus.$emit('live-time-allocation-open', this.asset.id);
            break;

          case 'logout':
            this.promptLogout();
            break;

          case 'locate':
            this.openMap();
            break;
        }
      });
    },
    promptLogout() {
      const asset = this.asset;

      if (!asset) {
        this.$toaster.error('Unable to logout asset at this time');
        return;
      }

      const allowedTimeCodeIds = this.fullTimeCodes
        .filter(tc => !tc.isReady && tc.assetTypeIds.includes(asset.typeId))
        .map(tc => tc.id);

      const activeTimeCodeId = (this.asset.activeTimeAllocation || {}).timeCodeId;

      this.$modal
        .create(DeviceLogoutModal, { timeCodeId: activeTimeCodeId, allowedTimeCodeIds })
        .onClose(answer => {
          if (answer && answer.timeCodeId) {
            this.logout(asset.deviceId, answer.timeCodeId);
          }
        });
    },
    logout(deviceId, timeCodeId) {
      const payload = {
        device_id: deviceId,
        time_code_id: timeCodeId,
      };

      this.$channel.push('device:force-logout', payload);
    },
    openMap() {
      const opts = {
        assetId: this.asset.id,
      };

      this.$modal.create(MapModal, opts);
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
.asset-tile.loading {
  background-color: #00800015 !important;
}

.asset-tile.queued {
  background-color: #ffa6000a !important;
}

.asset-tile.hang {
  background-color: #ffa6000a !important;
}

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
