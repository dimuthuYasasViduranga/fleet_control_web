<template>
  <div class="assign-default">
    <InfoHeader :asset="asset" :crossScale="crossScale" />
    <Separator />
    <AssignTimeAllocation :asset="asset" :crossScale="crossScale"/>
    <Separator />
    <ActionButtons @submit="emit('submit')" @reset="emit('reset')" @cancel="emit('cancel')" />
  </div>
</template>

<script>
import InfoHeader from './InfoHeader.vue';
import AssignTimeAllocation from './AssignTimeAllocation.vue';
import Separator from './Separator.vue';
import ActionButtons from './ActionButtons.vue';

export default {
  name: 'AssignDefault',
  components: {
    Separator,
    InfoHeader,
    AssignTimeAllocation,
    ActionButtons,
  },
  props: {
    asset: { type: Object, default: () => ({}) },
    crossScale: {type: Number, default: 1},
  },
  methods: {
    emit(event) {
      this.$emit(event);
    },
  },
};
</script>
