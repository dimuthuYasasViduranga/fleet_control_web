<template>
  <div class="single-msg">
    <div class="to-field">
      To: {{ toRecipient }}
      <span class="error">{{ error }}</span>
    </div>
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
        <button class="hx-btn button-send" @click="onSendMsg">Send</button>
        <button class="hx-btn button-clear" @click="clearMsg">Clear</button>
      </div>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import TagIcon from '@/components/icons/Tag.vue';
import QuickSelectModal from '@/components/modals/QuickSelectModal.vue';
const ENTER = 13;

export default {
  name: 'SingleMsg',
  components: {
    Icon,
  },
  props: {
    asset: { type: Object, default: () => null },
    maxLength: { type: Number, default: 40 },
    maxAnswerLength: { type: Number, default: 10 },
    quickMessages: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      tagIcon: TagIcon,
      text: '',
      error: '',
      answers: {
        a: '',
        b: '',
      },
    };
  },
  computed: {
    toRecipient() {
      if (this.asset) {
        let radioInfo = '';
        if (this.asset.radioNumber) {
          radioInfo = `(Radio: ${this.asset.radioNumber || '--'})`;
        }
        return `${this.asset.name} ${radioInfo}`;
      }
      return 'Not implemented for this asset';
    },
    messagePlaceholder() {
      return `Enter message here (${this.maxLength}) characters max`;
    },
    filteredQuickMessages() {
      return this.quickMessages.filter(m => {
        const validAnswers = (m.answers || []).filter(a => a.length < this.maxAnswerLength);
        return m.message.length < this.maxLength && (validAnswers.length === 2 || !m.answers);
      });
    },
    showAnswers() {
      return this.text.includes('?');
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
    sendOnEnter(event) {
      if (event.keyCode === ENTER) {
        this.onSendMsg();
      }
    },
    onSendMsg() {
      const message = this.text;
      const answers = Object.values(this.answers).filter(ans => ans);

      this.validateMessage(message, answers);

      if (this.error === '') {
        this.sendMsgToAsset(this.asset, message, answers);
      }
    },
    validateMessage(message, answers = []) {
      const length = message.length;

      if (length === 0) {
        this.error = 'Empty message not allowed';
        return;
      }

      if (length > this.maxLength) {
        this.error = `Message must be less than ${this.maxLength} characters`;
        return;
      }

      if (this.asset === null || !this.asset.id) {
        this.error = 'Asset(s) not selected';
        return;
      }

      if (message.includes('?') && answers.length !== 2) {
        this.error = 'Message contains question but does not give 2 answers';
        return;
      }

      if (!message.includes('?') && answers.length !== 0) {
        this.error = 'Message contains answers but no question';
        return;
      }

      this.error = '';
    },
    clearMsg() {
      this.error = '';
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
    sendMsgToAsset(asset, message, answers = []) {
      const validAnswers = answers.length === 0 ? null : answers.map(a => a.toLowerCase());
      const body = {
        message,
        asset_id: asset.id,
        answers: validAnswers,
        timestamp: Date.now(),
      };
      this.$channel.push('dispatcher-message:add', body);
      this.clearMsg();
    },
  },
};
</script>

<style>
@import '../../../assets/styles/hxInput.css';
.single-msg .button-send {
  max-height: 2rem;
  margin-left: 0.5rem;
}

.single-msg .button-clear {
  max-height: 2rem;
  margin-left: 0.5rem;
}

.single-msg .message-box-input {
  font: inherit;
  height: 2em;
  border: none;
  border-radius: 0;
  border-bottom: 1px solid #677e8c;
  padding: 0 0.33333rem;
  color: #b6c3cc;
  background-color: transparent;
  transition: background 0.4s, border-color 0.4s, color 0.4s;
}

.message-box-input:focus {
  background-color: white;
  outline: none;
  color: #0c1419;
}

.message-box-input::placeholder {
  color: #757575;
}

.message-box-input:disabled {
  background-color: #293238;
  border-color: transparent;
  color: #0c1419;
}

.single-msg .text-box-wrapper {
  display: flex;
  flex-direction: row;
  width: 100%;
}

.single-msg .text-box-wrapper .message-box-answer {
  margin-left: 0.5rem;
  width: 3rem;
}

.single-msg .text-box-wrapper .message-box-input {
  flex: 1 1 auto;
}

.single-msg .text-box-wrapper .button-wrapper {
  display: flex;
  flex: 0 0 auto;
}

.single-msg .text-box-wrapper .button-wrapper .hx-btn:disabled {
  background-color: #293238;
  color: #757575;
  cursor: default;
}

.single-msg .text-box-wrapper .button-wrapper .quick-message {
  padding-top: 0.5rem;
  cursor: pointer;
}

.single-msg .to-field {
  margin-bottom: 0.5rem;
  color: #b6c3cc;
}

.single-msg .error {
  padding-left: 3rem;
  color: red;
}
</style>