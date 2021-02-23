<template>
  <ListView class="asset-radio-modal" for="asset in formattedAssets" rowHeight="60">
    <v-template>
      <GridLayout columns="* * *">
        <CenteredLabel col="0" :text="asset.name" />
        <CenteredLabel col="1" :text="asset.type" />
        <CenteredLabel col="2" :text="asset.number || '--'" />
      </GridLayout>
    </v-template>
  </ListView>
</template>

<script>
import { mapState } from 'vuex';
import { attributeFromList } from '../../code/helper';
import CenteredLabel from '../CenteredLabel.vue';

export default {
  name: 'AssetRadios',
  components: {
    CenteredLabel,
  },
  computed: {
    ...mapState('constants', {
      assets: state => state.assets,
      assetRadios: state => state.assetRadios,
    }),
    formattedAssets() {
      const assets = this.assets.map(a => {
        const number = attributeFromList(this.assetRadios, 'assetId', a.id, 'radioNumber');
        return {
          id: a.id,
          name: a.name,
          type: a.type,
          number,
        };
      });

      assets.sort((a, b) => a.name.localeCompare(b.name));
      return assets;
    },
  },
};
</script>

<style>
.asset-radio-modal {
  height: 90%;
  width: 500;
  background-color: white;
}

.asset-radio-modal .centered-label {
  color: black;
  font-size: 26;
}
</style>