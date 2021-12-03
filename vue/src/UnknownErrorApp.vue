<template>
  <div id="unknown-error-app">
    <div>An error has occured</div>
    <pre>{{ error }}</pre>
    {{ error.response.statusText || '' }} - {{ error.response.data }}
  </div>
</template>

<script>
export default {
  name: 'UnkownErrorApp',
  props: {
    error: { type: Error },
  },
  mounted() {
    console.dir(this.error);
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