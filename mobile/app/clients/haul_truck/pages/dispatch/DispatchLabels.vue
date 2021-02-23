<template>
  <GridLayout class="dispatch-labels" width="100%" columns="2*, 5*" rows="*, *, *">
    <!-- dig unit -->
    <Label id="dig_unit_label" class="label" text="Unit" row="0" col="0" />
    <Label
      id="dig_unit_value"
      class="value"
      :class="highlightClass('digUnit')"
      :textWrap="true"
      :text="digUnit"
      row="0"
      col="1"
    />

    <!-- load location -->
    <Label id="load_location_label" class="label" text="Load" row="1" col="0" />
    <Label
      id="load_location_value"
      class="value"
      :class="highlightClass('digUnit')"
      :textWrap="true"
      :text="loadLocation"
      row="1"
      col="1"
    />

    <!-- dump location -->
    <Label id="dump_location_label" class="label" text="Dump" row="2" col="0" />
    <Label
      id="dump_location_value"
      class="value"
      :class="highlightClass('dump')"
      :textWrap="true"
      :text="dumpLocation"
      row="2"
      col="1"
    />
  </GridLayout>
</template>

<script>
import { attributeFromList } from '../../../code/helper';

export default {
  name: 'DispatchLabels',
  props: {
    dispatch: { type: Object, required: true },
    locations: { type: Array, default: () => [] },
    digUnitActivities: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
  },
  data: () => {
    return {};
  },
  computed: {
    digUnit() {
      return attributeFromList(this.assets, 'id', this.dispatch.digUnitId, 'name') || '--';
    },
    loadLocation() {
      const locationId = attributeFromList(
        this.digUnitActivities,
        'assetId',
        this.dispatch.digUnitId,
        'locationId',
      );
      return this.getLocation(locationId);
    },
    dumpLocation() {
      return this.getLocation(this.dispatch.dumpId);
    },
  },
  methods: {
    highlightClass(key) {
      if (this.dispatch[`${key}IdChanged`]) {
        return 'changed';
      }
      return '';
    },
    getLocation(id) {
      return attributeFromList(this.locations, 'id', id, 'name') || '--';
    },
  },
};
</script>

<style>
.dispatch-labels .label {
  text-align: center;
  vertical-align: center;
  font-size: 45;
}

.dispatch-labels .value {
  text-align: left;
  vertical-align: center;
  font-size: 60;
}

.dispatch-labels .label.changed,
.dispatch-labels .value.changed {
  color: yellow;
}
</style>