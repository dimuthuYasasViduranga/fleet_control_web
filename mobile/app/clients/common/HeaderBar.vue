<template>
  <ActionBar class="action-bar">
    <GridLayout rows="* *">
      <FlexboxLayout row="0" width="100%" flexDirection="row">
        <Button class="clock" width="100" :text="clockTime" @tap="onClockInfo" />

        <Button
          flexGrow="1"
          v-for="(info, index) in primary"
          :key="index"
          :id="`${info.id}-btn`"
          :class="`button ${info.id}-button`"
          :text="info.text"
          :col="index"
          textTransform="capitalize"
          :isEnabled="view !== info.id"
          @tap="onChangeView(info.id)"
        />

        <Image
          class="button icon-button"
          stretch="aspectFit"
          horizontalAlignment="right"
          tintColor="black"
          v-for="icon in filteredIconButtons"
          :key="icon.name"
          :width="iconWidth"
          :src="icon.src"
          @tap="icon.onTap"
        />

        <Button
          id="more"
          :width="iconWidth"
          class="button more-button"
          :class="{ highlight: isMoreViewSelected }"
          :text="ellipses"
          @tap="onShowMoreRoutes"
        />

        <Image
          id="logout"
          :width="iconWidth"
          class="button icon-button"
          src="~/assets/images/logout.png"
          stretch="aspectFit"
          horizontalAlignment="right"
          @tap="onConfirmLogout"
        />
      </FlexboxLayout>

      <AllocationBanner
        row="1"
        :asset="asset"
        :operator="operator"
        :allocation="allocation"
        :fullTimeCodes="fullTimeCodes"
        :initialExceptionGroup="initialExceptionGroup"
      />
    </GridLayout>
  </ActionBar>
</template>

<script>
import { mapState } from 'vuex';

import MoreRoutesModal from '../common/modals/MoreRoutesModal.vue';
import ClockInfoModal from '../common/modals/ClockInfoModal.vue';
import EngineHoursModal from '../common/modals/EngineHoursModal.vue';
import AssetRadioModal from '../common/modals/AssetRadioModal.vue';
import PreStartModal from '../common/modals/PreStartModal.vue';

import NestedDropdown from '../common/NestedDropdown.vue';
import AllocationBanner from '../common/allocations/AllocationBanner';

import CenteredLabel from '../common/CenteredLabel.vue';
import { attributeFromList, formatDate } from '../code/helper';
import MessagingModal from './modals/MessagingModal.vue';

const CLOCK_PERIOD = 2 * 1000;

function parseView(view) {
  if (typeof view === 'string') {
    return { id: view, text: view };
  }
  return view;
}

function getReadyTimeCodeElements(timeCodes, timeCodeGroups, elements) {
  if (timeCodes.length === 0 || elements.length === 0) {
    return [];
  }

  // get the id for the ready group set
  const readyGroupId = timeCodeGroups.find(tcg => tcg.name === 'Ready').id;

  const readyTreeRootId = elements.find(e => !e.parentId && e.timeCodeGroupId === readyGroupId).id;

  const readyElements = [];
  elements.forEach(e => {
    if (e.parentId && e.timeCodeGroupId === readyGroupId) {
      const parentId = e.parentId === readyTreeRootId ? null : e.parentId;
      const timeCodeName = attributeFromList(timeCodes, 'id', e.timeCodeId, 'name');
      const nodeName = e.name;
      readyElements.push({
        id: e.id,
        assetTypeId: e.assetTypeId,
        timeCodeId: e.timeCodeId,
        value: timeCodeName || nodeName,
        parentId,
        timeCodeGroupId: e.timeCodeGroupId,
        timeCodeName,
        nodeName,
      });
    }
  });

  return readyElements;
}

export default {
  name: 'HeaderBar',
  components: {
    NestedDropdown,
    CenteredLabel,
    AllocationBanner,
  },
  props: {
    view: { type: String, required: true },
    primaryViews: { type: Array, default: () => [] },
    secondaryViews: { type: Array, default: () => [] },
    disabledIcons: { type: Array, default: () => [] },
    disabledRoutes: { type: Array, default: () => [] },
    initialExceptionGroup: String,
  },
  data: () => {
    return {
      ellipses: `\u2219\u2219\u2219`,
      clock: new Date(),
      clockInterval: null,
      iconWidth: 120,
    };
  },
  computed: {
    ...mapState('constants', {
      timeCodes: state => state.timeCodes,
      timeCodeGroups: state => state.timeCodeGroups,
      timeCodeTreeElements: state => state.timeCodeTreeElements,
      preStarts: state => state.preStarts,
    }),
    ...mapState({
      asset: state => state.asset,
      operator: state => state.operator,
      deviceId: state => state.deviceId,
      allocation: state => state.allocation,
    }),
    filteredIconButtons() {
      const buttons = [
        { name: 'messages', src: '~/assets/images/message.png', onTap: this.onMessages },
        { name: 'engine hours', src: '~/assets/images/odometer.png', onTap: this.onEngineHours },
        { name: 'pre-start', src: '~/assets/images/clipboard.png', onTap: this.onPreStart },
      ];

      return buttons.filter(icon => !this.disabledIcons.includes(icon.name));
    },
    fullTimeCodes() {
      return this.$store.getters['constants/fullTimeCodes'];
    },
    timeCodeInfo() {
      const timeCodeId = (this.allocation || {}).timeCodeId;
      return attributeFromList(this.fullTimeCodes, 'id', timeCodeId);
    },
    primaryButtonWidth() {
      return `${(100 / this.primaryViews.length + 1).toFixed(3)}%`;
    },
    primary() {
      return this.primaryViews.map(parseView);
    },
    secondary() {
      return this.secondaryViews.map(parseView);
    },
    isMoreViewSelected() {
      const ids = this.secondary.map(v => v.id);
      return ids.includes(this.view);
    },
    operatorName() {
      if (!this.operator) {
        return null;
      }
      return this.operator.shortname;
    },
    assetName() {
      return (this.asset || {}).name;
    },
    assetLabelClass() {
      return {
        missing: !this.operator || !this.asset,
      };
    },
    assetLabelText() {
      const operatorName = this.operatorName || '--';
      const assetName = this.assetName || '--';

      return `${assetName} | ${operatorName}`;
    },
    readyOptionsFlat() {
      return getReadyTimeCodeElements(
        this.timeCodes,
        this.timeCodeGroups,
        this.timeCodeTreeElements,
      );
    },
    clockTime() {
      if (!this.clock) {
        return '';
      }
      return formatDate(this.clock, '%HH:%MM');
    },
  },
  mounted() {
    this.startClock();
  },
  beforeDestroy() {
    clearInterval(this.clockInterval);
  },
  methods: {
    startClock() {
      clearInterval(this.clockInterval);
      this.clockInterval = setInterval(() => (this.clock = new Date()), CLOCK_PERIOD);
    },
    onChangeView(view) {
      this.$emit('changeView', view);
    },
    onShowMoreRoutes() {
      const opts = {
        views: this.secondary,
        disabled: this.disabledRoutes,
        selectedView: this.view,
      };

      this.$modalBus.open(MoreRoutesModal, opts).onClose(view => {
        if (view !== undefined) {
          if (view === 'radio numbers') {
            this.$modalBus.open(AssetRadioModal);
            return;
          }
          this.onChangeView(view);
        }
      });
    },
    onClockInfo() {
      const opts = {
        asset: this.asset,
        operator: this.operator,
      };

      this.$modalBus.open(ClockInfoModal, opts);
    },
    onConfirmLogout() {
      this.$emit('confirmLogout');
    },
    onEngineHours() {
      const opts = {
        asset: this.asset,
        operator: this.operator,
      };

      this.$modalBus.open(EngineHoursModal, opts);
    },
    onMessages() {
      const opts = {
        asset: this.asset,
        operator: this.operator,
        deviceId: this.deviceId,
      };
      this.$modalBus.open(MessagingModal, opts);
    },
    onPreStart() {
      const opts = {
        asset: this.asset,
        operator: this.operator,
        preStarts: this.preStarts,
      };

      this.$modalBus.open(PreStartModal, opts);
    },
  },
};
</script>

<style>
.action-bar {
  height: 130;
  padding-right: 15%;
}

.action-bar .button.highlight,
.action-bar .button:disabled {
  background-color: lightslategray;
  color: white;
}

.action-bar .button {
  padding: 0;
  margin: 0;
}

.action-bar .button {
  font-size: 22;
}

.action-bar .more-button {
  font-size: 30;
}

.action-bar .icon-button {
  margin: 5 2;
  background-color: #d6d7d7;
  border-color: #d6d7d7;
  border-radius: 4;
  border-width: 4;
}

.action-bar .asset-label {
  font-size: 30;
}

.action-bar .asset-label.missing {
  color: red;
}

.action-bar .clock {
  font-size: 26;
  color: black;
}
</style>