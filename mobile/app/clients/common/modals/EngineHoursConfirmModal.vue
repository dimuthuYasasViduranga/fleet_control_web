<template>
  <ScrollView class="engine-hours-confirm-modal" orientation="vertical">
    <StackLayout class="engine-hours-content">
      <Label class="message" :text="message" :textWrap="true" />
      <Label class="message message-dark" :text="promptMessage" :textWrap="true" />

      <TextField
        class="text-field"
        keyboardType="number"
        v-model="matchValue"
        returnKeyType="done"
      />
      <GridLayout width="100%" columns="*, *">
        <Button
          class="button"
          :class="{ disabled: !canAccept }"
          col="0"
          :text="confirmName"
          @tap="onConfirm"
        />
        <Button class="button" col="1" :text="rejectName" @tap="onReject" />
      </GridLayout>
    </StackLayout>
  </ScrollView>
</template>

<script>
export default {
  name: 'EngineHoursConfirmModal',
  props: {
    message: { type: String, default: '' },
    hours: { type: Number, default: null },
  },
  data: () => {
    return {
      matchValue: '',
      confirmName: 'accept',
      rejectName: 'cancel',
    };
  },
  computed: {
    promptMessage() {
      return `\nEnter '${this.hours}' to confirm`;
    },
    canAccept() {
      return this.hours && `${this.hours}` === `${this.matchValue}`;
    },
  },
  methods: {
    close(answer) {
      this.$emit('close', answer);
    },
    onConfirm() {
      if (!this.canAccept) {
        return;
      }
      this.close(this.confirmName);
    },
    onReject() {
      this.close(this.rejectName);
    },
  },
};
</script>

<style>
.engine-hours-confirm-modal {
  background-color: white;
  width: 70%;
}

.engine-hours-content {
  padding: 25 50;
}

.engine-hours-confirm-modal .message {
  font-size: 35;
}

.engine-hours-confirm-modal .message-dark {
  color: dimgray;
}

.engine-hours-confirm-modal .button {
  font-size: 25;
  height: 80;
}

.engine-hours-confirm-modal .button.disabled {
  background-color: dimgray;
  opacity: 0.6;
}

.engine-hours-confirm-modal .text-field {
  font-size: 40;
}

.engine-hours-confirm-modal .hidden-text-field {
  height: 0;
}
</style>