<template>
  <div class="asset-assignment">
    <hxCard style="width: auto" title="Haul Trucks" :icon="truckIcon">
      <loaded>
        <HaulTruckTable :readonly="readonly" />
      </loaded>
    </hxCard>

    <hxCard style="width: auto" title="Dig Units" :icon="excavatorIcon">
      <loaded>
        <DigUnitTable :readonly="readonly" />
      </loaded>
    </hxCard>

    <hxCard style="width: auto" title="Other Assets" :icon="tabletIcon">
      <loaded>
        <GeneralAssetTable />
      </loaded>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';

import Loaded from '../../Loaded.vue';

import HaulTruckTable from './HaulTruckTable.vue';
import DigUnitTable from './DigUnitTable.vue';
import GeneralAssetTable from './GeneralAssetTable.vue';

import TruckIcon from '../../icons/asset_icons/HaulTruck.vue';
import ExcavatorIcon from '../../icons/asset_icons/Excavator.vue';
import TabletIcon from '../../icons/Tablet.vue';

export default {
  name: 'AssetAssignment',
  components: {
    hxCard,
    Loaded,
    HaulTruckTable,
    DigUnitTable,
    GeneralAssetTable,
  },
  data: () => {
    return {
      truckIcon: TruckIcon,
      excavatorIcon: ExcavatorIcon,
      tabletIcon: TabletIcon,
    };
  },
  computed: {
    ...mapState('constants', {
      readonly: state => !state.permissions.can_dispatch,
    }),
  },
};
</script>

<style>
@import '../../../assets/table.css';
@import '../../../assets/hxInput.css';
@import '../../../assets/iconColors.css';
@import '../../../assets/textColors.css';
</style>
