<template>
  <div class="bubble-wrapper" @click="$emit('click')">
    <div class="bubble" :class="color">
      <slot></slot>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Bubble',
  props: {
    color: { type: String, default: 'yellow' },
  },
};
</script>

<style>
.bubble-wrapper {
  width: 1.25rem;
  height: 1.25rem;
  display: table;
  user-select: none;
  margin: auto;
  font-family: 'GE Inspira Sans', sans-serif;
  font-size: 14px;
}

.bubble {
  width: 100%;
  height: 100%;
  border-radius: 50%;

  padding-top: 5%;
  padding-right: 5%;
  display: table-cell;
  text-align: center;
  vertical-align: middle;
  color: black;
  font-weight: bold;
}

.bubble.grey {
  background-color: grey;
}

.bubble.yellow {
  background-color: yellow;
}

.bubble.orange {
  background-color: orange;
}

.bubble.red {
  background-color: red;
}

.bubble.green {
  background-color: green;
}

.bubble.powderblue {
  background-color: powderblue;
}
</style>