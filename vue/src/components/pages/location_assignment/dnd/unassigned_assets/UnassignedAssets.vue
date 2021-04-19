<template>
  <hxCard class="unassigned-assets" :icon="locationIcon">
    <template slot="title-post">
      <span class="title">Unassigned</span>
      <span class="hide-caret-wrapper" @click="toggleShow()">
        <span :class="caretClass"></span>
      </span>
    </template>
    <Container
      v-if="show"
      orientation="horizontal"
      group-name="draggable"
      :drop-placeholder="dropPlaceholderOptions"
      :get-child-payload="index => getChildPayload(index)"
      @drop="onDrop"
      @drag-end="onDragEnd()"
    >
      <Draggable v-for="asset in assets" :key="asset.name">
        <AssetTile :asset="asset" />
      </Draggable>
    </Container>
  </hxCard>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import { Container, Draggable } from 'vue-smooth-dnd';
import AssetTile from '../asset_tile/AssetTile.vue';
import LocationIcon from '@/components/icons/Location.vue';

export default {
  name: 'UnassignedAssets',
  components: {
    hxCard,
    Container,
    Draggable,
    AssetTile,
  },
  props: {
    assets: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      locationIcon: LocationIcon,
      show: true,
      dropPlaceholderOptions: {
        className: 'tile-drop-preview',
        animationDuration: '150',
        showOnTop: true,
      },
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
    getChildPayload(index) {
      const asset = this.assets[index];
      this.$emit('drag-start', asset);
      return asset;
    },
    onDragEnd() {
      this.$emit('drag-end');
    },
    onDrop({ addedIndex, removedIndex, payload }) {
      // is added
      if (addedIndex !== null && removedIndex === null) {
        this.$emit('add', { asset: payload });
      }
    },
  },
};
</script>

<style>
/* --- drop placeholder --- */
.unassigned-assets .smooth-dnd-container .tile-drop-preview {
  border: 1px dashed grey;
  height: 7rem;
  background-color: rgba(150, 150, 200, 0.1);
}

.unassigned-assets .smooth-dnd-container .smooth-dnd-drop-preview-constant-class {
  top: 0;
}

.unassigned-assets .hxCardHeader {
  padding-bottom: 0.5rem;
}
</style>

<style scoped>
.hxCard {
  padding: 0;
  padding-bottom: 0.75rem;
  border-top: none;
  border-bottom: 1px solid #364c59;
}

/* --- container --- */
.smooth-dnd-container {
  display: flex;
  flex-wrap: wrap;
  flex-direction: row;
  width: 100%;
  min-height: 7rem;
  /* overflow: hidden canot be used here as it will break the tooltip container */
}

.smooth-dnd-draggable-wrapper {
  cursor: move;
}

/* ---- caret toggle ----- */
.hide-caret-wrapper {
  display: flex;
  padding: 7px;
  width: 2rem;
  cursor: pointer;
}

.hide-caret-wrapper .caret-down {
  margin-top: 3px;
  width: 0;
  height: 0;
  border-left: 6px solid transparent;
  border-right: 6px solid transparent;

  border-top: 6px solid grey;
}

.hide-caret-wrapper .caret-right {
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;

  border-left: 6px solid grey;
}
</style>