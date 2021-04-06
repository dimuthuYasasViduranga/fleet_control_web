<template>
  <hxCard class="other-assets" :icon="locationIcon">
    <template slot="title-post">
      <span class="title">{{ title }}</span>
      <span class="hide-caret-wrapper" @click="toggleShow()">
        <span :class="caretClass"></span>
      </span>
    </template>
    <div v-show="show" class="assets">
      <AssetTile v-for="asset in assets" :asset="asset" :key="asset.id" />
    </div>
  </hxCard>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import AssetTile from '../asset_tile/AssetTile.vue';

import LocationIcon from '@/components/icons/Location.vue';

export default {
  name: 'OtherAssets',
  components: {
    hxCard,
    AssetTile,
  },
  props: {
    title: { type: String, default: 'Other Assets' },
    assets: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      locationIcon: LocationIcon,
      show: true,
    };
  },
  computed: {
    caretClass() {
      return this.show ? 'caret-down' : 'caret-right';
    },
  },
  methods: {
    toggleShow() {
      this.show = !this.show;
    },
  },
};
</script>

<style>
.other-assets .hxCardHeader {
  padding-bottom: 0.5rem;
}

.other-assets.hxCard {
  padding: 0;
  padding-bottom: 0.75rem;
  border-top: none;
  border-bottom: 1px solid #364c59;
}

.other-assets .assets {
  display: flex;
  flex-wrap: wrap;
}

.other-assets .assets .asset-tile {
  background-color: transparent;
}

/* ---- caret toggle ----- */
.other-assets .hide-caret-wrapper {
  display: flex;
  padding: 7px;
  width: 2rem;
  cursor: pointer;
}

.other-assets .hide-caret-wrapper .caret-down {
  margin-top: 3px;
  width: 0;
  height: 0;
  border-left: 6px solid transparent;
  border-right: 6px solid transparent;

  border-top: 6px solid grey;
}

.other-assets .hide-caret-wrapper .caret-right {
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;

  border-left: 6px solid grey;
}
</style>