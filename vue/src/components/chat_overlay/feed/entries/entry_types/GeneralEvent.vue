<template>
  <div class="general-event">
    {{ message }}
  </div>
</template>

<script>
export default {
  name: 'GeneralEvent',
  props: {
    message: { type: String, default: 'No Message Given' },
  },
};
</script>

<style>
.general-event {
  text-align: center;
  border: 1px solid grey;
  margin: 1rem;
  padding: 0.25rem;
  background-color: rgba(128, 128, 128, 0.377);
}
</style>