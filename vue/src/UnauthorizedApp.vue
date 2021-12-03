<template>
  <div id="unauthorized">
    <p>Welcome, {{ user.name }}</p>
    <br />
    <p>It appears you do not have the required authorization for this application</p>
    <p>If you were recently given access, please try again in a couple of minutes</p>
    <p>otherwise, please contact support@haultrax.com to have your permissions elevated</p>
  </div>
</template>

<script>
export default {
  name: 'UnauthorizedApp',
  props: {
    user: { type: Object, default: () => ({}) },
  },
};
</script>

<style>
#unauthorized {
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