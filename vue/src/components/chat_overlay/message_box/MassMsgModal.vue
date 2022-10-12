<template>
  <div>
    <div class="title">Mass Message</div>
    <AssetSelector v-model="selectedAssetIds" :assets="selectableAssets" />

    <div class="text-box-wrapper">
      <input
        class="message-box-input"
        type="text"
        v-model="text"
        :placeholder="messagePlaceholder"
        :maxLength="maxLength"
        @keydown="sendOnEnter"
      />
      <input
        v-if="showAnswers"
        class="message-box-input message-box-answer"
        type="text"
        v-model="answers.a"
        placeholder="Answer A"
        :maxLength="maxAnswerLength"
        @keydown="sendOnEnter"
      />

      <input
        v-if="showAnswers"
        class="message-box-input message-box-answer"
        type="text"
        v-model="answers.b"
        placeholder="Answer B"
        :maxLength="maxAnswerLength"
        @keydown="sendOnEnter"
      />
      <div class="button-wrapper">
        <Icon
          v-if="filteredQuickMessages.length"
          v-tooltip="'Quick Message'"
          class="quick-message"
          :icon="tagIcon"
          @click="onOpenQuickMessages()"
        />
        <button class="hx-btn button-send" @click="onSendMsg" :disabled="!canSend">Send</button>
        <button class="hx-btn button-clear" @click="onClearMsg">Clear</button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import TagIcon from '@/components/icons/Tag.vue';

import AssetSelector from './AssetSelector.vue';
import QuickSelectModal from '@/components/modals/QuickSelectModal.vue';

const ENTER = 13;

function validateMessage(selectedAssetIds, message, answers = [], maxLength) {
  const length = message.length;

  if (length === 0) {
    return 'Empty message not allowed';
  }

  if (length > maxLength) {
    return `Message must be less than ${this.maxLength} characters`;
  }

  if (selectedAssetIds.length === 0) {
    return 'Assets not selected';
  }

  if (message.includes('?') && answers.length !== 2) {
    return 'Question must have 2 answers';
  }

  if (!message.includes('?') && answers.length !== 0) {
    return 'Message contains answers but no question';
  }

  return '';
}

export default {
  name: 'MassMsgModal',
  wrapperClass: 'mass-msg-modal',
  components: {
    Icon,
    AssetSelector,
  },
  props: {
    assets: { type: Array, default: () => [] },
    maxLength: { type: Number, default: 40 },
    maxAnswerLength: { type: Number, default: 15 },
    quickMessages: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      tagIcon: TagIcon,
      selectedAssetIds: [],
      text: '',
      answers: {
        a: '',
        b: '',
      },
    };
  },
  computed: {
    ...mapState('constants', {
      selectableAssets: state => state.assets,
    }),
    messagePlaceholder() {
      return `Enter message here (${this.maxLength}) characters max`;
    },
    canSend() {
      return this.selectedAssetIds.length !== 0 && this.text;
    },
    showAnswers() {
      return this.text.includes('?');
    },
    filteredQuickMessages() {
      return this.quickMessages.filter(m => {
        const validAnswers = (m.answers || []).filter(a => a.length < this.maxAnswerLength);
        return m.message.length < this.maxLength && (validAnswers.length === 2 || !m.answers);
      });
    },
  },
  watch: {
    showAnswers: {
      immediate: true,
      handler(bool) {
        if (bool === false) {
          this.answers.a = '';
          this.answers.b = '';
        } else {
          this.answers.a = 'Yes';
          this.answers.b = 'No';
        }
      },
    },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    sendOnEnter(event) {
      if (event.keyCode === ENTER) {
        this.onSendMsg();
      }
    },
    onClearMsg() {
      this.text = '';
    },
    onOpenQuickMessages() {
      const items = this.filteredQuickMessages.map(m => {
        const label =
          (m.answers || []).length === 2 ? `${m.message} [${m.answers.join('|')}]` : m.message;
        return {
          label,
          message: m.message,
          answers: m.answers,
        };
      });

      const opts = { title: 'Quick Message', items, label: 'label' };
      this.$modal.create(QuickSelectModal, opts).onClose(resp => {
        if (!resp) {
          return;
        }

        this.text = resp.message;

        if ((resp.answers || []).length === 2) {
          this.answers.a = resp.answers[0];
          this.answers.b = resp.answers[1];
        }
      });
    },
    onSendMsg() {
      const message = this.text;
      const answers = Object.values(this.answers).filter(ans => ans);
      const error = validateMessage(this.selectedAssetIds, message, answers, this.maxLength);
      if (error) {
        this.$toaster.error(error);
        return;
      }

      if (this.selectedAssetIds.length === 1) {
        this.sendSingleMsg(this.selectedAssetIds[0], message, answers);
      } else {
        this.sendMassMsg(this.selectedAssetIds, message, answers);
      }
    },
    sendSingleMsg(assetId, message, answers = []) {
      const validAnswers = answers.length === 0 ? null : answers.map(a => a.toLowerCase());
      const payload = {
        message,
        asset_id: assetId,
        answers: validAnswers,
        timestamp: Date.now(),
      };

      this.$channel
        .push('dispatcher-message:add', payload)
        .receive('ok', () => this.close())
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to send message'));
    },
    sendMassMsg(assetIds, message, answers = []) {
      const validAnswers = answers.length === 0 ? null : answers.map(a => a.toLowerCase());
      const payload = {
        message,
        asset_ids: assetIds,
        answers: validAnswers,
        timestamp: Date.now(),
      };

      this.$channel
        .push('dispatcher-message:mass-add', payload)
        .receive('ok', () => this.close())
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to send message'));
    },
  },
};
</script>

<style>
.mass-msg-modal .modal-container {
  max-width: 70rem;
}
</style>

<style scoped>
@import '../../../assets/hxInput.css';

.title {
  font-size: 2rem;
  text-align: center;
  margin-bottom: 0.25rem;
}


.text-box-wrapper {
  padding-top: 2rem;
  width: 100%;
  display: flex;
}

.text-box-wrapper .message-box-input {
  margin-right: 0.5rem;
  flex: 1 1 auto;
  height: 2rem;
  border: none;
  border-radius: 0;
  border-bottom: 1px solid #677e8c;
  padding: 0 0.33rem;
  color: #b6c3cc;
  background-color: transparent;
  transition: background 0.4s, border-color 0.4s, color 0.4s;
}

.text-box-wrapper .message-box-input:focus {
  background-color: white;
  outline: none;
  color: #0c1419;
}

.text-box-wrapper .message-box-input::placeholder {
  color: #757575;
}

.text-box-wrapper .message-box-input:disabled {
  background-color: #293238;
  border-color: transparent;
  color: #0c1419;
}

.text-box-wrapper .message-box-answer {
  margin-right: 0.5rem;
  width: 4rem;
}

.text-box-wrapper .hx-btn:disabled {
  background-color: #333b41;
  color: #757575;
  cursor: default;
}

.text-box-wrapper .button-wrapper {
  display: flex;
}

.text-box-wrapper .button-wrapper .quick-message {
  padding-top: 0.5rem;
  cursor: pointer;
}

.text-box-wrapper .button-wrapper .button-send {
  margin-right: 0.1rem;
}
</style>