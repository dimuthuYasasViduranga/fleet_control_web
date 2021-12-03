<template>
  <div id="unauthorized">
    <p>Insufficient permissions to access this application</p>

    <p>If you feel you should have access, please contact support@haultrax.com</p>
  </div>
</template>

<script>
export default {
  name: 'UnauthorizedApp',
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