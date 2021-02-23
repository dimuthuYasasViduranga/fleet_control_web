<template>
  <Page class="page debug-client" :actionBarHidden="true">
    <GridLayout rows="* * * * * *" columns="* * * *">
      <CenteredLabel row="0" colSpan="4" text="Debug Client" />

      <!-- logged in status -->
      <CenteredLabel row="1" col="0" colSpan="2" text="Logged In" />
      <CenteredLabel row="1" col="2" colSpan="2" :text="isLoggedIn" />

      <!-- connection status -->
      <CenteredLabel row="2" col="0" colSpan="2" text="Connected" />
      <CenteredLabel row="2" col="2" colSpan="2" :text="isConnected" />

      <!-- operator -->
      <CenteredLabel row="3" col="0" colSpan="2" text="Operator" />
      <CenteredLabel row="3" col="2" colSpan="2" :text="(operator || {}).name" />

      <!-- asset -->
      <CenteredLabel row="4" col="0" colSpan="2" text="Asset" />
      <CenteredLabel row="4" col="2" colSpan="2" :text="(asset || {}).name" />

      <Button row="5" col="0" text="Clear Data" @tap="onClearData()" />
      <Button row="5" col="1" text="Login" @tap="onLogin()" />
      <Button row="5" col="2" text="Logout" @tap="onLogout()" />
    </GridLayout>
  </Page>
</template>

<script>
import CenteredLabel from '../common/CenteredLabel.vue';

export default {
  name: 'DebugClient',
  components: {
    CenteredLabel,
  },
  props: {
    isLoggedIn: { type: Boolean, default: false },
    isConnected: { type: Boolean, default: false },
    operator: { type: Object, default: null },
    asset: { type: Object, default: null },
  },
  methods: {
    onLogin() {
      this.$emit('login');
    },
    onLogout() {
      this.$emit('logout');
    },
  },
};
</script>

<style>
.debug-client .centered-label {
  font-size: 34;
}
</style>