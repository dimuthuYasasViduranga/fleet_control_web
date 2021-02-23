<template>
  <GridLayout width="100%" columns="*" rows="2*, *">
    <GridLayout row="0" rows="*" columns="20*, 3*">
      <DispatchLabels
        col="0"
        :dispatch="haulTruckDispatch"
        :locations="locations"
        :assets="assets"
        :digUnitActivities="digUnitActivities"
      />
      <IconStack col="1" @tap="onIconTap" />
    </GridLayout>

    <!-- acknowledge bar -->
    <StackLayout row="1">
      <Button
        class="button acknowledge-bar"
        :class="{ dim: !acknowledgementRequired }"
        height="100%"
        text="acknowledge"
        textTransform="capitalize"
        @tap="acknowledge()"
      />
    </StackLayout>
  </GridLayout>
</template>

<script>
import { attributeFromList } from '../../../code/helper';
import DispatchLabels from './DispatchLabels.vue';
import IconStack from './IconStack.vue';

const OLD_DISPATCH_INTERVAL = 30 * 1000;

const DISPATCH_CHANGEABLE_KEYS = ['digUnitIdChanged', 'dumpIdChanged'];

function copyDispatch(dispatch) {
  if (!dispatch) {
    return {};
  }
  return JSON.parse(JSON.stringify(dispatch));
}

export default {
  name: 'Dispatch',
  components: {
    DispatchLabels,
    IconStack,
  },
  props: {
    haulTruckDispatch: { type: Object, required: true },
    locations: { type: Array, default: () => [] },
    digUnitActivities: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      alertInterval: null,
      curDispatch: {},
      prevDispatch: {},
    };
  },
  computed: {
    acknowledgementRequired() {
      return DISPATCH_CHANGEABLE_KEYS.map(key => this.haulTruckDispatch[key]).some(p => p === true);
    },
  },
  watch: {
    haulTruckDispatch: {
      immediate: true,
      deep: true,
      handler(newDispatch) {
        if (!newDispatch) {
          return;
        }
        const curDispatch = copyDispatch(newDispatch);
        this.curDispatch = curDispatch;

        // check for changes
        if (DISPATCH_CHANGEABLE_KEYS.some(key => curDispatch[key] === true)) {
          this.$avPlayer.playNotification();
          this.setAlertInterval();
        }
      },
    },
  },
  beforeDestroy() {
    this.clearAlertInterval();
  },
  methods: {
    clearAlertInterval() {
      clearInterval(this.alertInterval);
    },
    setAlertInterval() {
      this.clearAlertInterval();
      this.alertInterval = setInterval(() => {
        this.$avPlayer.playNotification();
      }, OLD_DISPATCH_INTERVAL);
    },
    acknowledge() {
      const dispatch = this.curDispatch;
      this.prevDispatch = copyDispatch(dispatch);

      // clear notification sound
      this.clearAlertInterval();

      // emit that button has been pressed
      this.$emit('acknowledge');

      if (dispatch.id && !dispatch.acknowledgeId) {
        const timestamp = Math.round(Date.now());
        const acknowledgement = {
          id: dispatch.id,
          timestamp,
        };

        this.$store.dispatch('haulTruck/submitAcknowledgement', {
          acknowledgement,
          channel: this.$channel,
        });
      }
    },
    onIconTap(icon) {
      if (icon === 'engineHours') {
        this.$emit('openEngineHours');
      }
    },
  },
};
</script>

<style>
.acknowledge-bar {
  font-size: 30;
}

.acknowledge-bar.dim {
  background-color: dimgray;
  opacity: 0.6;
  border-color: transparent;
  border-width: 1;
}
</style>
