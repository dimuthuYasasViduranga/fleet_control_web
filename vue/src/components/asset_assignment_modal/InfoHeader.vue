<template>
  <table class="info-header">
    <tr class="row asset-name">
      <td class="key">Asset</td>
      <td class="value">{{ asset.name }}</td>
    </tr>
    <tr class="row operator-name">
      <td class="key">Operator</td>
      <td class="value">{{ operatorName }}</td>
    </tr>
  </table>
</template>

<script>
export default {
  name: 'InfoHeader',
  props: {
    asset: { type: Object, default: () => ({}) },
  },
  computed: {
    operatorName() {
      return (this.asset.operator || {}).fullname || '--';
    },
  },
};
</script>

<style>
.info-header {
  width: 100%;
  border-collapse: collapse;
}

.info-header .row {
  height: 3rem;
}

.info-header .row .key {
  font-size: 2rem;
}

.info-header .row .value {
  width: 60%;
  font-size: 1.5rem;
  text-align: center;
}
</style>