<template>
  <GridLayout class="watercart-route-modal" rows="80 *">
    <CenteredLabel class="route-name" row="0" :text="name" />
    <ScrollView row="1">
      <StackLayout>
        <FlexboxLayout
          row="1"
          width="100%"
          height="100%"
          flexDirection="row"
          flexWrap="wrap"
          justifyContent="center"
        >
          <CenteredLabel
            height="65"
            width="auto"
            class="asset"
            v-for="(asset, index) in assets"
            :key="index"
            :text="asset.name"
          />
        </FlexboxLayout>
      </StackLayout>
    </ScrollView>
  </GridLayout>
</template>

<script>
import CenteredLabel from '../../common/CenteredLabel.vue';
export default {
  name: 'WaterCartRouteModal',
  components: {
    CenteredLabel,
  },
  props: {
    name: { type: String, default: '' },
    assets: { type: Array, default: () => [] },
  },
};
</script>

<style scoped>
.watercart-route-modal {
  height: 70%;
  width: 70%;
  background-color: white;
}

.watercart-route-modal .route-name {
  color: black;
  border-bottom-width: 2;
  border-bottom-color: black;
}

.watercart-route-modal .asset {
  color: rgb(70, 70, 70);
}

.route-name {
  font-size: 34;
}

.asset {
  font-size: 40;
  margin-left: 10;
  margin-right: 10;
}
</style>