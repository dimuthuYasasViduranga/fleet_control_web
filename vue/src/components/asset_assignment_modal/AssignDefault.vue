<template>
  <div class="assign-default">
    <InfoHeader :asset="asset" :crossScale="crossScale" />
    <Separator />
    <AssignTimeAllocation
      v-model="timeCodeId"
      :assetTypeId="asset.typeId"
      :crossScale="crossScale"
    />
    <Separator />
    <ActionButtons
      @submit="emit('submit', timeCodeId)"
      @reset="emit('reset')"
      @cancel="emit('cancel')"
    />
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
    crossScale: { type: Number, default: 1 },
  },
  data: () => {
    return {
      timeCodeId: null,
    };
  },
  watch: {
    asset: {
      immediate: true,
      handler(asset = {}) {
        this.timeCodeId = asset.activeTimeCodeId;
      },
    },
  },
  methods: {
    emit(event, payload) {
      this.$emit(event, payload);
    },
  },
};
</script>
