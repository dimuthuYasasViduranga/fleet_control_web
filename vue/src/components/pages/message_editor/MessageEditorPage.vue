<template>
  <div class="message-editor-page">
    <hxCard style="width: auto" title="Message Editors" :icon="chatIcon">
      <div class="mode-selector">
        <button
          class="hx-btn"
          v-for="(mode, index) in ['messages', 'message tree', 'message tree matrix']"
          :key="index"
          :class="{ selected: mode === selectedMode }"
          @click="setMode(mode)"
        >
          {{ mode }}
        </button>
      </div>
      <MessageEditor
        v-if="selectedMode === 'messages'"
        :messageTypes="messageTypes"
        :readonly="readonly"
      />

      <MessageTreeEditor
        v-else-if="selectedMode === 'message tree'"
        :messageTypes="messageTypes"
        :messageTree="messageTree"
        :assetTypes="assetTypes"
        :readonly="readonly"
      />

      <MessageTreeMatrix
        v-else
        :messageTypes="messageTypes"
        :messageTree="messageTree"
        :assetTypes="assetTypes"
      />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import ChatIcon from '../../icons/Chat.vue';

import MessageEditor from './message/MessageEditor.vue';

import MessageTreeEditor from './message_tree/MessageTreeEditor.vue';
import MessageTreeMatrix from './message_tree/MessageTreeMatrix.vue';

export default {
  name: 'MessageEditorPage',
  components: {
    hxCard,
    MessageEditor,
    MessageTreeEditor,
    MessageTreeMatrix,
  },
  data: () => {
    return {
      chatIcon: ChatIcon,
      selectedMode: 'messages',
    };
  },
  computed: {
    ...mapState('constants', {
      readonly: state => !state.permissions.fleet_control_edit_messages,
      messageTypes: state => state.operatorMessageTypes,
      messageTree: state => state.operatorMessageTypeTree,
      assetTypes: state => state.assetTypes,
    }),
  },
  methods: {
    setMode(mode) {
      this.selectedMode = mode;
    },
  },
};
</script>

<style>
/* -------- mode selector ------- */
.message-editor-page .mode-selector {
  margin-bottom: 1rem;
}

.message-editor-page .mode-selector .hx-btn {
  width: 12rem;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
  text-transform: capitalize;
}

.message-editor-page .mode-selector .hx-btn.selected {
  background-color: #2c404c;
  border: 1px solid #898f94;
}
</style>
