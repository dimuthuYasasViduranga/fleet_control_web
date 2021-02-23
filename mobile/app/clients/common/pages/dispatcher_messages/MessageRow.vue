<template>
  <GridLayout width="100%" class="message-row" columns="*, 4*" @tap="onClick">
    <CenteredLabel class="timestamp" col="0" :text="formattedTime" />
    <CenteredLabel class="text" col="1" :text="text" :textWrap="true" />
  </GridLayout>
</template>

<script>
import { todayRelativeFormat } from '../../../code/helper';
import CenteredLabel from '../../CenteredLabel.vue';
export default {
  name: 'MessageRow',
  components: {
    CenteredLabel,
  },
  props: {
    timestamp: { type: Date, default: null },
    text: { type: String, default: '' },
  },
  computed: {
    formattedTime() {
      return todayRelativeFormat(this.timestamp);
    },
    bool() {
      return this.acknowledged ? 'True' : 'False';
    },
  },
  methods: {
    onClick(event) {
      this.$emit('click', event);
    },
  },
};
</script>

<style>
.message-row {
  font-size: 22;
  height: 65;
}
</style>