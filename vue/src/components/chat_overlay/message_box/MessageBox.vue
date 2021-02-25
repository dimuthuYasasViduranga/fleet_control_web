<template>
  <div class="message-box">
    <SingleMsg
      v-if="selectedAsset"
      :asset="selectedAsset"
      :maxLength="maxMsgLen"
      :maxAnswerLength="maxAnsLen"
      :quickMessages="quickMessages"
    />

    <button v-else class="hx-btn mass-msg-btn" @click="onOpenMassMsg">Open Mass Messaging</button>
  </div>
</template>

<script>
import { attributeFromList } from '../../../code/helpers.js';
import SingleMsg from './SingleMsg.vue';
import MassMsgModal from './MassMsgModal';

export default {
  name: 'MessageBox',
  components: {
    SingleMsg,
  },
  props: {
    assets: { type: Array, default: () => [] },
    selectedAsset: { type: Object, default: () => null },
  },
  data: () => {
    return {
      text: '',
      error: '',
      maxMsgLen: 60,
      maxAnsLen: 10,
    };
  },
  computed: {
    quickMessages() {
      return this.$store.state.constants.quickMessages;
    },
  },
  methods: {
    onOpenMassMsg() {
      this.$modal.create(MassMsgModal, { assets: this.assets });
    },
  },
};
</script>

<style>
@import '../../../assets/hxInput.css';

.message-box {
  height: 100%;
  padding: 10px;
}

.message-box .mass-msg-btn {
  width: 100%;
}
</style>