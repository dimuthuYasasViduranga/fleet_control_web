<template>
  <ScrollView class="confirm-modal" :class="classes">
    <StackLayout class="confirm-content">
      <Label class="message" :text="message" :textWrap="true" />
      <Label class="message" text="" />
      <GridLayout width="100%" columns="*, *">
        <Button class="button" col="0" :text="confirmName" @tap="onConfirm" />
        <Button class="button" col="1" :text="rejectName" @tap="onReject" />
      </GridLayout>
    </StackLayout>
  </ScrollView>
</template>

<script>
export default {
  name: 'ConfirmModal',
  props: {
    message: { type: String, default: '' },
    confirmName: { type: String, default: 'yes' },
    rejectName: { type: String, default: 'no' },
    classes: { type: [Array, String], default: '' },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onConfirm() {
      this.close(this.confirmName);
    },
    onReject() {
      this.close(this.rejectName);
    },
  },
};
</script>

<style>
.confirm-modal {
  background-color: white;
  width: 500;
}

.confirm-modal .confirm-content {
  padding: 25 50;
}

.confirm-modal .message {
  font-size: 35;
}

.confirm-modal .button {
  font-size: 25;
  height: 80;
}
</style>