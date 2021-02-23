<template>
  <GridLayout class="activity-bar" height="60" columns="* *">
    <DropDown
      col="0"
      :value="activity.locationId"
      :options="locationOptions"
      filter="simple"
      label="name"
      @input="onLocationChange"
    />
    <!-- <DropDown
      col="1"
      :value="activity.materialTypeId"
      :options="materialOptions"
      label="commonName"
      @input="onMaterialChange"
    /> -->

    <DropDown
      col="2"
      :value="activity.loadStyleId"
      :options="loadStyleOptions"
      label="style"
      @input="onLoadStyleChange"
    />
  </GridLayout>
</template>

<script>
import { mapState } from 'vuex';
import DropDown from '../../../common/DropDown.vue';
export default {
  name: 'ActivityBar',
  components: {
    DropDown,
  },
  props: {
    asset: { type: Object, default: null },
    activity: { type: Object, default: null },
  },
  computed: {
    ...mapState('constants', {
      locations: state => state.locations,
      materialTypes: state => state.materialTypes,
      loadStyles: state => state.loadStyles,
    }),
    locationOptions() {
      return [{ id: null, name: 'No Location' }].concat(this.locations);
    },
    materialOptions() {
      return [{ id: null, commonName: 'No Material' }].concat(this.materialTypes);
    },
    loadStyleOptions() {
      const styles = this.loadStyles.filter(s => s.assetTypeId === this.asset.typeId);
      return [{ id: null, style: 'No Style' }].concat(styles);
    },
  },
  methods: {
    onLocationChange(id) {
      this.activity.locationId = id;
      this.submitActivity(this.activity);
    },
    onMaterialChange(id) {
      this.activity.materialTypeId = id;
      this.submitActivity(this.activity);
    },
    onLoadStyleChange(id) {
      this.activity.loadStyleId = id;
      this.submitActivity(this.activity);
    },
    submitActivity(activity) {
      if (!this.asset || !this.asset.id) {
        console.error('[ActivityBar] Cannot submit activity, no asset id');
        return;
      }

      if (!this.activity) {
        console.error('[ActivityBar] Cannot submit activity, no given activity');
        return;
      }

      const payload = {
        assetId: this.asset.id,
        locationId: activity.locationId,
        materialTypeId: activity.materialTypeId,
        loadStyleId: activity.loadStyleId,
        timestamp: Date.now(),
      };

      this.$store.dispatch('digUnit/submitActivity', { activity: payload, channel: this.$channel });
    },
  },
};
</script>

<style>
.activity-bar .dropdown-btn,
.activity-bar .dropdown-btn-ellipses {
  font-size: 26;
}
</style>