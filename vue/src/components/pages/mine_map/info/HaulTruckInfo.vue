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
        <td class="heading">Load</td>
        <td class="value">{{ loadLocation }}</td>
      </tr>
      <tr>
        <td class="heading">Dump</td>
        <td class="value">{{ dumpLocation }}</td>
      </tr>
    </table>
  </div>
</template>

<script>
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
    locations: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      editIcon: EditIcon,
    };
  },
  computed: {
    loadLocation() {
      return this.getLocation('load') || '--';
    },
    dumpLocation() {
      return this.getLocation('dump') || '--';
    },
  },
  methods: {
    onEdit() {
      this.$eventBus.$emit('asset-assignment-open', this.asset.id);
    },
    getLocation(name) {
      const info = this.asset.track.haulTruckInfo;
      const id = info[`${name}Id`];
      const distance = info[`${name}Distance`];

      if (!id) {
        return null;
      }

      const locationName = attributeFromList(this.locations, 'id', id, 'name');

      if (distance) {
        const km = (distance / 1000).toFixed(1);
        return `${locationName} (${km} km)`;
      }

      return locationName;
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