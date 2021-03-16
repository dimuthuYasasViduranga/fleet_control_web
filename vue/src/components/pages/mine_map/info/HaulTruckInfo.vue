<template>
  <div class="haul-truck-info">
    <table>
      <tr>
        <th class="title" colspan="5">
          <div class="title-wrapper">
            <div class="name">Assignment</div>
            <Icon class="edit-icon" :icon="editIcon" @click="onEdit" />
          </div>
        </th>
      </tr>
      <tr>
        <td class="heading">Dig Unit</td>
        <td class="value">{{ targetDigUnit }}</td>
      </tr>
      <tr>
        <td class="heading">Dump</td>
        <td class="value">{{ dumpLocation }}</td>
      </tr>
    </table>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import { attributeFromList } from '../../../../code/helpers';
import EditIcon from '../../../icons/Edit.vue';

export default {
  name: 'HaulTruckInfo',
  components: {
    Icon,
  },
  props: {
    asset: { type: Object, required: true },
  },
  data: () => {
    return {
      editIcon: EditIcon,
    };
  },
  computed: {
    ...mapState({
      assets: state => state.constants.assets,
      locations: state => state.constants.locations,
      dispatches: state => state.haulTruck.currentDispatches,
      activities: state => state.digUnit.currentActivities,
    }),
    dispatch() {
      return attributeFromList(this.dispatches, 'assetId', this.asset.id) || {};
    },
    targetDigUnit() {
      const digUnitName = attributeFromList(this.assets, 'id', this.dispatch.digUnitId, 'name');
      const digUnitActivity =
        attributeFromList(this.activities, 'assetId', this.dispatch.digUnitId) || {};
      const digUnitLocation = attributeFromList(
        this.locations,
        'id',
        digUnitActivity.locationId,
        'name',
      );

      return digUnitLocation ? `${digUnitName} (${digUnitLocation})` : digUnitName || '--';
    },
    dumpLocation() {
      return attributeFromList(this.locations, 'id', this.dispatch.dumpId, 'name');
    },
  },
  methods: {
    onEdit() {
      this.$eventBus.$emit('asset-assignment-open', this.asset.id);
    },
  },
};
</script>

<style>
@import '../../../../assets/textColors.css';
.haul-truck-info table {
  width: 100%;
}

.haul-truck-info .title {
  border-bottom: solid 1px;
}

.haul-truck-info .title .title-wrapper {
  width: 100%;
  display: flex;
}

.haul-truck-info .title .name {
  width: 95%;
}

.haul-truck-info .title .edit-icon {
  cursor: pointer;
  height: 1rem;
  width: 1rem;
  stroke: black;
}

.haul-truck-info .heading {
  text-align: center;
}

.haul-truck-info .value {
  text-align: center;
}

.haul-truck-info td {
  padding: 0.2rem 0.75rem;
}
</style>