<template>
  <div class="haul-truck-dispatch-event">
    <div class="title">{{ entry.assetName || 'Unknown' }} | {{ route }}</div>
  </div>
</template>

<script>
import { toRunName } from '../../../../../code/helpers';
export default {
  name: 'HaulTruckDispatchEvent',
  props: {
    entry: { type: Object, required: true },
  },
  computed: {
    route() {
      const entry = this.entry;
      const load = entry.loadLocation;
      const dump = entry.dumpLocation;

      return toRunName(load, dump);
    },
  },
};
</script>

<style>
.haul-truck-dispatch-event {
  border: 2px dashed grey;
  padding: 0.25rem;
  padding-top: 0.4rem;
  background-color: #383e42;
  color: darkgray;
  display: flex;
  flex-direction: row;
}
</style>