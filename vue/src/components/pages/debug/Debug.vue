<template>
  <div class="debug-page">
    <hxCard title="Modals" :icon="bugIcon">
      <div class="modal-list">
        <button class="hx-btn" @click="onOpenModal">Open Modal</button>
        <button class="hx-btn" @click="onChainModals">Chain Modal</button>
        <button class="hx-btn" @click="onNestedModals">Nested Modals</button>
        <button class="hx-btn" @click="onCreateLoadingModal">Loading Modal</button>
      </div>
    </hxCard>
    <hxCard title="Title" :icon="bugIcon">
      <div>
        <input class="typeable" v-model="pendingTitleName" />
        <button class="hx-btn" @click="setTitle(pendingTitleName)">Set</button>
        <button class="hx-btn" @click="resetTitle(pendingTitleName)">Reset</button>
      </div>
      <button class="hx-btn" @click="playSound()">Play Sound</button>
    </hxCard>
    <hxCard title="Context Menu" :icon="bugIcon">
      <button class="hx-btn" @click="onOpenContext">Click to open context</button>
    </hxCard>
    <hxCard title="Toasted" :icon="bugIcon">
      <div class="toast toast-info">
        <div>Info:</div>
        <input class="typeable" v-model="toasts.info" />
        <button class="hx-btn" @click="onCreateInfoToast(toasts.info, { duration: 1500 })">
          Create
        </button>
      </div>
      <div class="toast toast-error">
        <div>Error:</div>
        <input class="typeable" v-model="toasts.error" />
        <button class="hx-btn" @click="onCreateErrorToast(toasts.error)">Create</button>
      </div>
      <div class="toast toast-no-comms">
        <div>No Comms:</div>
        <input class="typeable" v-model="toasts.noComms" />
        <button class="hx-btn" @click="onCreateNoCommsToast(toasts.noComms)">Create</button>
      </div>
      <div class="toast only-1">
        <div>Only one at a time:</div>
        <button class="hx-btn" @click="onCreateInfoToast('Only one', { onlyOne: true })">
          Create
        </button>
      </div>
      <div class="toast replace">
        <div>Replace same message:</div>
        <button class="hx-btn" @click="onCreateInfoToast('Replace', { replace: true })">
          Create
        </button>
      </div>
      <div class="toast update-text">
        <div>Changing toast:</div>
        <button
          class="hx-btn"
          @click="onCreateChangingToast('Loading ...', 'Loading Complete', 1500)"
        >
          Create
        </button>
      </div>
    </hxCard>
    <hxCard class="datetime-selector" title="Datetime Input">
      <hxCard
        class="datetime-input-example"
        v-for="(params, index) in datetimeParams"
        :key="index"
        :title="params.name"
      >
        <table class="value-table">
          <tr>
            <th>Min</th>
            <td>{{ params.min || '--' }}</td>
          </tr>
          <tr>
            <th>Max</th>
            <td>{{ params.max || '--' }}</td>
          </tr>
          <tr>
            <th>Timezone</th>
            <td>{{ params.timezone || '--' }}</td>
          </tr>
          <tr>
            <th>Value</th>
            <td>{{ formatDateString(params.value) }}</td>
          </tr>
        </table>

        <Dately
          v-model="params.value"
          :minDatetime="params.min"
          :maxDatetime="params.max"
          :timezone="params.timezone"
        />
      </hxCard>

      <hxCard class="datetime-input-example" title="Shared Dately (both should update)">
        <table class="value-table">
          <tr>
            <th>Min</th>
            <td>{{ sharedDately.min || '--' }}</td>
          </tr>
          <tr>
            <th>Max</th>
            <td>{{ sharedDately.max || '--' }}</td>
          </tr>
          <tr>
            <th>Timezone</th>
            <td>{{ sharedDately.timezone || '--' }}</td>
          </tr>
          <tr>
            <th>Value</th>
            <td>{{ formatDateString(sharedDately.value) }}</td>
          </tr>
        </table>

        <Dately
          v-model="sharedDately.value"
          :minDatetime="sharedDately.min"
          :maxDatetime="sharedDately.max"
          :timezone="sharedDately.timezone"
        />
        <Dately
          v-model="sharedDately.value"
          :minDatetime="sharedDately.min"
          :maxDatetime="sharedDately.max"
          :timezone="sharedDately.timezone"
        />
        <button class="hx-btn" style="margin-left: 1rem" @click="sharedDately.value = null">
          Clear Value
        </button>
      </hxCard>
    </hxCard>
    <hxCard style="width: auto" title="Channel Info" :icon="bugIcon">
      <table>
        <tr>
          <td>Updated At</td>
          <td>{{ formatDate(lastUpdatedAt) }}</td>
        </tr>
        <tr>
          <td>Mode</td>
          <td>{{ mode }}</td>
        </tr>
        <tr>
          <td>Is Alive?</td>
          <td>{{ isAlive }}</td>
        </tr>
        <tr>
          <td>Is Connected?</td>
          <td>{{ isConnected }}</td>
        </tr>
        <tr>
          <td>Last Connected</td>
          <td>{{ formatDate(lastConnectedAt) }}</td>
        </tr>
        <tr>
          <td>Last Disconnected</td>
          <td>{{ formatDate(lastDisconnectedAt) }}</td>
        </tr>
        <tr>
          <td>Status</td>
          <td>{{ status || 'unknown' }}</td>
        </tr>
      </table>

      <button class="hx-btn" @click="onDisconnectChannel()">Disconnect</button>
      <button class="hx-btn" @click="onErrorChannel()">Trigger error</button>

      <div class="message-log">
        Message Log:
        <pre>{{ messageLog }}</pre>
      </div>
    </hxCard>
    <hxCard title="Icons" :icon="bugIcon">
      <div class="small-icons">
        <icon
          v-for="(assetIcon, index) in assetIcons"
          :key="index"
          :icon="assetIcon"
          @click="setIcon(assetIcon)"
        />
      </div>

      <div class="showcase-icons">
        <icon :icon="selectedIcon" />
        <icon :icon="selectedIcon" :rotation="45" />
        <icon :icon="selectedIcon" :scale="{ x: -1 }" />
        <icon :icon="selectedIcon" :scale="{ y: -1 }" />

        <icon style="height: 12rem; width: 6rem" :icon="selectedIcon" />
        <icon style="height: 6rem; width: 12rem" :icon="selectedIcon" />
      </div>
    </hxCard>
    <hxCard class="nested-icons" title="Nested Icons" :icon="bugIcon">
      <NIcon :icon="bugIcon" :secondaryIcon="tabletIcon" />
      <NIcon style="width: 2rem" :icon="excavatorIcon" :secondaryIcon="tabletIcon" />
      <NIcon style="width: 4rem" :icon="excavatorIcon" :secondaryIcon="tabletIcon" />
      <NIcon style="width: 8rem" :icon="excavatorIcon" :secondaryIcon="tabletIcon" />
      <NIcon style="width: 8rem" :icon="excavatorIcon" />
    </hxCard>
    <hxCard title="Auto Size TextArea" :icon="bugIcon">
      Input Text: {{ textAreaText }}
      <AutoSizeTextArea style="width: 6rem" v-model="textAreaText" placeholder="Enter text" />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import icon from 'hx-layout/Icon.vue';

import BugIcon from '@/components/icons/Bug.vue';
import TabletIcon from '@/components/icons/Tablet.vue';

import DozerIcon from '@/components/icons/asset_icons/Dozer.vue';
import HaulTruckIcon from '@/components/icons/asset_icons/HaulTruck.vue';
import WaterTruckIcon from '@/components/icons/asset_icons/WaterTruck.vue';
import ExcavatorIcon from '@/components/icons/asset_icons/Excavator.vue';
import LoaderIcon from '@/components/icons/asset_icons/Loader.vue';
import ScraperIcon from '@/components/icons/asset_icons/Scraper.vue';
import GraderIcon from '@/components/icons/asset_icons/Grader.vue';
import DrillIcon from '@/components/icons/asset_icons/Drill.vue';
import LVIcon from '@/components/icons/asset_icons/LightVehicle.vue';

import AutoSizeTextArea from '@/components/AutoSizeTextArea.vue';
import NIcon from '@/components/NIcon.vue';
import ConfirmModal from '@/components/modals/ConfirmModal.vue';
import LoadingModal from '@/components/modals/LoadingModal.vue';
import NestedModal from './NestedModal.vue';

import Dately from '@/components/dately/Dately.vue';

import { formatDateIn } from '@/code/time.js';
import { Titler } from '@/code/titler.js';

const chime = new Audio( require('@/assets/audio/chime.mp3'));

const ASSET_ICONS = [
  DozerIcon,
  HaulTruckIcon,
  WaterTruckIcon,
  ExcavatorIcon,
  LoaderIcon,
  ScraperIcon,
  GraderIcon,
  DrillIcon,
  LVIcon,
  undefined,
];

export default {
  name: 'DebugPage',
  components: {
    hxCard,
    icon,
    NIcon,
    Dately,
    AutoSizeTextArea,
  },
  data: () => {
    return {
      bugIcon: BugIcon,
      excavatorIcon: ExcavatorIcon,
      tabletIcon: TabletIcon,
      selectedIcon: ASSET_ICONS[0],
      assetIcons: ASSET_ICONS,
      pendingTitleName: 'Some Title',
      toasts: {
        info: 'Info',
        error: 'Error',
        noComms: 'No Comms',
      },
      datetimeParams: [
        {
          name: 'No min/max, no initial value. Local timezone',
          value: null,
          timezone: 'local',
        },
        {
          name: 'Min, no initial value. Local timezone',
          value: null,
          min: '2020-12-16T10:30:00Z',
          timezone: 'local',
        },
        {
          name: 'Max, no initial value. Local timezone',
          value: null,
          max: '2020-12-16T10:30:00Z',
          timezone: 'local',
        },
        {
          name: 'Min/Max, no initial value. Local timezone',
          value: null,
          min: '2020-12-16T10:30:00Z',
          max: '2020-12-17T10:30:00Z',
          timezone: 'local',
        },
        {
          name: 'Min/Max, no initial value. Local timezone. Really old',
          value: null,
          min: '2019-10-10T10:30:00Z',
          max: '2019-10-20T10:30:00Z',
          timezone: 'local',
        },
        {
          name: 'Day light savings (starts at 3 am on the 4th)',
          value: null,
          min: '2020-10-04T00:00:00+10:00',
          max: '2020-10-04T23:59:59+11:00',
          timezone: 'Australia/Sydney',
        },
        {
          name: 'Day light savings (ends at 3 am on the 4th)',
          value: null,
          min: '2021-04-04T00:00:00+11:00',
          max: '2021-04-04T23:59:59+10:00',
          timezone: 'Australia/Sydney',
        },
      ],
      sharedDately: {
        name: 'Min/Max, no initial value. Local timezone. Really old',
        value: null,
        min: '2019-10-10T10:30:00Z',
        max: '2019-10-20T10:30:00Z',
        timezone: 'local',
      },
      textAreaText: '',
    };
  },
  computed: {
    ...mapState('connection', {
      mode: state => state.mode,
      isAlive: state => state.isAlive,
      isConnected: state => state.isConnected,
      lastConnectedAt: state => state.lastConnectedAt,
      lastDisconnectedAt: state => state.lastDisconnectedAt,
      lastUpdatedAt: state => state.updatedAt,
      messageLog: state => state.messageLog,
      status: state => state.status,
    }),
  },
  beforeDestroy() {
    Titler.reset();
  },
  methods: {
    formatDate(date) {
      const tz = this.$timely.current.timezone;
      return formatDateIn(date, tz, { format: 'yyyy-MM-dd HH:mm:ss' });
    },
    setIcon(assetIcon) {
      this.selectedIcon = assetIcon;
    },
    setTitle(title) {
      Titler.change(title);
    },
    resetTitle() {
      Titler.reset();
    },
    playSound() {
      chime.play();
    },
    onOpenContext(event) {
      const items = [
        { name: 'Apple' },
        { name: 'Banana' },
        { name: 'Cappaberra' },
        { name: 'Apple' },
        { name: 'Banana' },
        { name: 'Cappaberra' },
      ];

      this.$contextMenu.create('debug-context', event, items, { toggle: true });
    },
    onCreateInfoToast(msg, opts) {
      this.$toaster.info(msg, opts);
    },
    onCreateErrorToast(msg, opts) {
      this.$toaster.error(msg, opts);
    },
    onCreateNoCommsToast(msg, opts) {
      this.$toaster.noComms(msg, opts);
    },
    onCreateChangingToast(initial, after, timeout) {
      const toast = this.$toaster.error(initial);
      setTimeout(() => {
        toast.text = after;
      }, timeout);
    },
    onOpenModal() {
      this.$modal.create(ConfirmModal, { title: 'Some text', body: 'even more text' });
    },
    onChainModals() {
      this.$modal
        .create(ConfirmModal, { title: 'Modal 1', body: 'Ok will open another modal' })
        .onClose(answer => {
          if (answer === 'ok') {
            this.$modal.create(ConfirmModal, { title: 'Modal 2', body: 'No more after this' });
          }
        });
    },
    onNestedModals() {
      this.$modal.create(NestedModal);
    },
    onCreateLoadingModal() {
      const modal = this.$modal.create(
        LoadingModal,
        { message: 'Closing in 4 seconds' },
        { clickOutsideClose: false },
      );
      setTimeout(() => modal.close(), 4000);
    },
    onDisconnectChannel() {
      this.$channel.destroy();
    },
    onErrorChannel() {
      this.$channel.push('completely does not exist');
    },
    formatDateString(date) {
      if (!date) {
        return '--';
      }
      const ISO = date.toISOString();

      return `${ISO.slice(0, 10)}\n${ISO.slice(11, 19)}Z`;
    },
  },
};
</script>

<style>
.debug-page .hxCard {
  padding-bottom: 2rem;
}

.debug-page .toast {
  display: flex;
}

.debug-page .toast div {
  width: 8rem;
}

.debug-page .small-icons {
  display: flex;
}

.debug-page .small-icons .hx-icon {
  border: 1px solid green;
  width: 12rem;
  height: 12rem;
}

.debug-page .showcase-icons {
  display: flex;
  align-items: center;
}

.debug-page .showcase-icons .hx-icon {
  border: 1px solid orange;
  width: 8rem;
  height: 8rem;
}

.debug-page .message-log pre {
  margin: 0;
}

.debug-page .modal-list .hx-btn {
  margin-right: 0.1rem;
}

.debug-page .datetime-selector .value-table {
  table-layout: fixed;
  border: 1px solid gray;
  border-collapse: collapse;
}

.debug-page .datetime-selector .value-table tr {
  border-bottom: 1px solid gray;
}

.debug-page .datetime-selector .value-table th {
  width: 6rem;
  border-right: 1px solid gray;
}

.debug-page .datetime-selector .value-table td {
  width: 6rem;
  text-align: center;
}

.debug-page .nested-icons .secondary-icon {
  stroke: orange;
}
</style>