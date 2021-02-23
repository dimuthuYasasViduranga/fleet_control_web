<template>
  <GridLayout class="clock-info-modal" rows="* * * *" columns="* 8*">
    <!-- clock -->
    <Image
      row="0"
      col="0"
      src="~/assets/images/clock.png"
      stretch="aspectFit"
      horizontalAlignment="center"
    />
    <CenteredLabel row="0" col="1" :text="clockTime" />

    <!-- asset -->
    <Image row="1" col="0" :src="assetIcon" stretch="aspectFit" horizontalAlignment="center" />
    <CenteredLabel row="1" col="1" :text="assetName || 'Unknown Asset'" />

    <!-- operator -->
    <Image
      row="2"
      col="0"
      src="~/assets/images/user.png"
      stretch="aspectFit"
      horizontalAlignment="center"
    />
    <CenteredLabel row="2" col="1" :text="operatorName || 'Unknown Operator'" />

    <!-- radio -->
    <Image
      row="3"
      col="0"
      src="~/assets/images/phone.png"
      stretch="aspectFit"
      horizontalAlignment="center"
    />
    <CenteredLabel row="3" col="1" :text="`Radio Number: ${radioNumber}`" />
  </GridLayout>
</template>

<script>
import { attributeFromList, formatDate } from '../../code/helper';
import CenteredLabel from '../CenteredLabel.vue';

const CLOCK_PERIOD = 1000;

const TYPE_IMAGES = {
  Dozer: 'dozerSideOn.png',
  'Haul Truck': 'haulTruckSideOn.png',
  Watercart: 'waterCartSideOn.png',
  Excavator: 'excavatorSideOn.png',
  Loader: 'loaderSideOn.png',
  Scraper: 'scraperSideOn.png',
  Grader: 'graderSideOn.png',
  Drill: 'drillSideOn.png',
  'Light Vehicle': 'lightVehicleSideOn.png',
};

export default {
  name: 'ClockInfoModal',
  components: {
    CenteredLabel,
  },
  props: {
    asset: { type: Object, default: () => null },
    operator: { type: Object, default: () => null },
  },
  data: () => {
    return {
      clock: new Date(),
      clockInterval: null,
    };
  },
  computed: {
    clockTime() {
      if (!this.clock) {
        return '';
      }

      return formatDate(this.clock);
    },
    assetName() {
      const asset = this.asset || {};
      return asset.type ? `${asset.name} (${asset.type})` : asset.name;
    },
    operatorName() {
      return (this.operator || {}).fullname;
    },
    radioNumber() {
      const assetId = (this.asset || {}).id;
      const radioNumbers = this.$store.state.constants.assetRadios;
      return attributeFromList(radioNumbers, 'assetId', assetId, 'radioNumber') || '--';
    },
    assetIcon() {
      const imagePath = TYPE_IMAGES[this.asset.type];
      return `~/assets/images/asset-types/${imagePath || 'tablet.png'}`;
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
  },
};
</script>

<style>
.clock-info-modal {
  background-color: white;
  width: 500;
  height: 300;
  padding: 25 50;
}

.clock-info-modal .centered-label {
  font-size: 26;
  color: black;
}
</style>