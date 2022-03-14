<template>
  <div id="unknown-error-app">
    <p>An error has occured</p>
    <p>{{ error }}</p>
    {{ statusText || '' }} - {{ message }}
  </div>
</template>

<script>
export default {
  name: 'UnkownErrorApp',
  props: {
    error: { type: Error },
  },
  computed: {
    statusText() {
      return this.error?.response?.statusText;
    },
    message() {
      const message = this.error?.response?.data || '';
      if (typeof message !== 'string' || message.includes('DOCTYPE')) {
        return 'No reason given';
      } else {
        return message;
      }
    },
  },
};
</script>

<style>
#unknown-error-app {
  position: fixed;
  top: 0;
  left: 0;
  height: 100%;
  width: 100%;
  text-align: center;
  color: white;
  background-color: #121f26;
  font-size: 1.5rem;
  font-family: 'GE Inspira Sans', sans-serif;
  z-index: 1000;
}
</style>