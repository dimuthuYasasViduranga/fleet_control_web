<template>
  <div class="dig-unit-info">
    <table>
      <tr>
        <th class="title" colspan="5">
          <div class="title-wrapper">
            <div class="name">Activity</div>
            <Icon class="edit-icon" :icon="editIcon" @click="onEdit" />
          </div>
        </th>
      </tr>
      <tr>
        <td class="heading">Dig Location</td>
        <td class="value">{{ digLocation || '--' }}</td>
      </tr>
      <!-- <tr>
        <td class="heading">Material</td>
        <td class="value">{{ materialType || '--' }}</td>
      </tr> -->
      <tr>
        <td class="heading">Load Style</td>
        <td class="value">{{ loadStyle || '--' }}</td>
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
  name: 'DigUnitInfo',
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
      materialTypes: state => state.constants.materialTypes,
      loadStyles: state => state.constants.loadStyles,
      locations: state => state.constants.locations,
      activities: state => state.digUnit.currentActivities,
    }),
    activity() {
      return attributeFromList(this.activities, 'assetId', this.asset.id) || {};
    },
    materialType() {
      return attributeFromList(
        this.materialTypes,
        'id',
        this.activity.materialTypeId,
        'commonName',
      );
    },
    loadStyle() {
      return attributeFromList(this.loadStyles, 'id', this.activity.loadStyleId, 'style');
    },
    digLocation() {
      return attributeFromList(this.locations, 'id', this.activity.locationId, 'name');
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
.dig-unit-info table {
  width: 100%;
}

.dig-unit-info .title {
  border-bottom: solid 1px;
}

.dig-unit-info .title .title-wrapper {
  width: 100%;
  display: flex;
}

.dig-unit-info .title .name {
  width: 95%;
}

.dig-unit-info .title .edit-icon {
  cursor: pointer;
  height: 1rem;
  width: 1rem;
  stroke: black;
}

.dig-unit-info .heading {
  text-align: center;
}

.dig-unit-info .value {
  text-align: center;
}

.dig-unit-info td {
  padding: 0.2rem 0.75rem;
}
</style>