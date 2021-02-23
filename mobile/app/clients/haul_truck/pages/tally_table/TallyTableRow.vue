<template>
  <GridLayout class="tally-table-row" columns="2* 2* 3* 2* 3* *">
    <CenteredLabel col="0" class="value" :text="startTime" :textWrap="true" />
    <CenteredLabel col="1" class="value" :text="endTime" :textWrap="true" />
    <CenteredLabel col="2" class="value" :text="loadUnit" />
    <CenteredLabel col="3" class="value" :text="materialType" />
    <CenteredLabel col="4" class="value" :text="dumpLocation" />
    <Button col="5" class="button" :text="ellipses" @tap="onMore" />
  </GridLayout>
</template>

<script>
import CenteredLabel from '../../../common/CenteredLabel.vue';
import { formatDate, isSameDay, attributeFromList } from '../../../code/helper';

export default {
  name: 'TallyTableRow',
  components: {
    CenteredLabel,
  },
  props: {
    cycle: { type: Object, required: true },
    assets: { type: Array, default: () => [] },
    locations: { type: Array, default: () => [] },
    materialTypes: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      ellipses: `\u2219\u2219\u2219`,
    };
  },
  computed: {
    loadUnit() {
      return attributeFromList(this.assets, 'id', this.cycle.loadUnitId, 'name');
    },
    materialType() {
      return attributeFromList(this.materialTypes, 'id', this.cycle.materialTypeId, 'commonName');
    },
    loadLocation() {
      return attributeFromList(this.locations, 'id', this.cycle.loadLocationId, 'name');
    },
    dumpLocation() {
      return attributeFromList(this.locations, 'id', this.cycle.dumpLocationId, 'name');
    },
    startTime() {
      const now = new Date();
      const time = this.cycle.startTime;
      if (isSameDay(time, now)) {
        return formatDate(time, '%HH:%MM:%SS');
      }
      return formatDate(time, '%Y-%m-%d\n%HH:%MM:%SS');
    },
    endTime() {
      const now = new Date();
      const time = this.cycle.endTime;
      if (isSameDay(time, now)) {
        return formatDate(time, '%HH:%MM:%SS');
      }
      return formatDate(time);
    },
  },
  methods: {
    onMore() {
      this.$emit('more', this.cycle);
    },
  },
};
</script>

<style>
.tally-table-row {
  height: 60;
  width: 100%;
  border-width: 0.5;
  border-color: orange;
}
</style>