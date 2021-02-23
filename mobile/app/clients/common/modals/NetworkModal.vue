<template>
  <GridLayout class="network-modal" columns="* *" rows="60 60 60">
    <CenteredLabel row="0" col="0" class="info-key" text="Network" />
    <CenteredLabel row="0" col="1" class="info-value" :text="type || 'None'" />

    <CenteredLabel row="1" col="0" class="info-key" text="Last Updated" />
    <CenteredLabel row="1" col="1" class="info-value" :text="age" />

    <Button row="2" colSpan="2" text="Check Internet Connection" @tap="onCheckInternet" />
  </GridLayout>
</template>

<script>
import { mapState } from 'vuex';
import axios from 'axios';
import CenteredLabel from '../CenteredLabel.vue';
import { formatDate, formatSeconds } from '../../code/helper';

const INTERNET_CHECK_ENDPOINT = 'https://api.myip.com';

export default {
  name: 'NetworkModal',
  components: {
    CenteredLabel,
  },
  data: () => {
    return {
      interval: null,
      ago: null,
    };
  },
  computed: {
    ...mapState('network', {
      updatedAt: state => state.updatedAt,
      type: state => state.type,
    }),
    age() {
      const totalSeconds = this.ago;
      if (totalSeconds == null) {
        return '';
      }

      return formatSeconds(totalSeconds, '%R');
    },
  },
  mounted() {
    this.updateAgo();

    this.interval = setInterval(() => this.updateAgo(), 1000);
  },
  beforeDestroy() {
    clearInterval(this.interval);
  },
  methods: {
    updateAgo() {
      if (this.updatedAt != null) {
        this.ago = Math.trunc((Date.now() - this.updatedAt.getTime()) / 1000);
      }
    },
    onCheckInternet() {
      axios
        .get(INTERNET_CHECK_ENDPOINT)
        .then(resp => this.showHasInternetToast(resp.status === 200))
        .catch(() => this.showHasInternetToast(false));
    },
    showHasInternetToast(hasInternet) {
      if (hasInternet) {
        this.$toaster.green('Internet Connectivity Present').show();
      } else {
        this.$toaster.red('No Internet Connectivity Present').show();
      }
    },
  },
};
</script>

<style>
.network-modal {
  background-color: white;
  width: 450;
  padding: 25 25;
}

.network-modal .centered-label {
  color: black;
}

.network-modal .info-key {
  font-weight: 500;
  font-size: 25;
}

.network-modal .info-value {
  font-size: 20;
}
</style>