<template>
  <div class="haul-truck-mass-dispatch-event">
    <div class="title">
      <div class="star">{{ '\u2b50' }}</div>
      <div class="text">Mass Change | {{ assets }}</div>
    </div>
    <div class="message">
      <span class="new">{{ route }}</span>
    </div>
  </div>
</template>

<script>
import { toRunName } from '../../../../../code/helpers';
export default {
  name: 'HaulTruckMassDispatchEvent',
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
    assets() {
      return this.entry.assetNames;
    },
  },
};
</script>

<style>
.haul-truck-mass-dispatch-event {
  border: 2px dashed grey;
  padding: 0.25rem;
  background-color: #2f3133;
  color: darkgray;
}

.haul-truck-mass-dispatch-event .title {
  display: inline-flex;
  line-height: 1.25rem;
}

.haul-truck-mass-dispatch-event .title .text {
  padding-bottom: 0.25rem;
}

.haul-truck-mass-dispatch-event .message {
  display: flex;
  flex-wrap: wrap;
  padding-left: 1.5rem;
}
</style>