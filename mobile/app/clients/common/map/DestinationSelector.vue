<template>
  <GridLayout class="destination-selector" columns="3*, *" @tap="onOpenSelector">
    <CenteredLabel class="text" col="0" :text="locationName" textAlignment="left" />
    <CenteredLabel class="text" col="1" :text="formattedDistance" />
  </GridLayout>
</template>

<script>
import CenteredLabel from '../CenteredLabel.vue';
import SearchModal from '../modals/SearchModal.vue';
import { attributeFromList } from '../../code/helper';

function getHaulTruckOptions(dispatch, locations) {
  if (!dispatch) {
    return [];
  }

  const options = [];

  ['load', 'dump', 'next'].forEach(type => {
    const id = dispatch[`${type}Id`];
    const name = attributeFromList(locations, 'id', id, 'name');
    if (name) {
      options.push({ id, value: `[${type}] ${name}` });
    }
  });

  return options;
}

export default {
  name: 'DestinationSelector',
  components: {
    CenteredLabel,
  },
  props: {
    value: { type: Number, default: null },
    distance: { type: Number, default: null },
    locations: { type: Array, default: () => [] },
    haulTruckDispatch: { type: Object, default: () => ({}) },
  },
  computed: {
    locationName() {
      return attributeFromList(this.locations, 'id', this.value, 'name') || 'Select Destination';
    },
    formattedDistance() {
      const distance = this.distance;
      if (!distance || !this.value) {
        return '';
      }

      if (distance > 1000) {
        return `${(distance / 1000).toFixed(1)} km`;
      }
      return `~${distance.toFixed(0)} m`;
    },
    options() {
      const haulTruckOptions = getHaulTruckOptions(this.haulTruckDispatch, this.locations);
      const standardOptions = this.locations.map(l => ({ id: l.id, value: l.name }));

      return haulTruckOptions.concat(standardOptions);
    },
  },
  methods: {
    onOpenSelector() {
      const opts = {
        value: this.value,
        options: this.options,
        nullName: 'No Location',
      };
      this.$modalBus.open(SearchModal, opts).onClose(option => {
        if (!option) {
          return;
        }

        this.$emit('input', option.id);

        if (option.id !== this.value) {
          this.$emit('change', option.id);
        }
      });
    },
  },
};
</script>

<style>
.destination-selector {
  background-color: rgba(222, 228, 228, 0.75);
  padding: 0;
  margin: 5;
}

.destination-selector .text {
  font-size: 26;
  color: #0c1419;
}
</style>