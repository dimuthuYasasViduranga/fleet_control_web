<template>
  <GridLayout class="tally-table" rows="* 7*">
    <GridLayout row="0" class="header" columns="2* 2* 3* 2* 3* *">
      <CenteredLabel col="0" class="value" text="Start" />
      <CenteredLabel col="1" class="value" text="End" />
      <CenteredLabel col="2" class="value" text="Load Unit" />
      <CenteredLabel col="3" class="value" text="Material" />
      <CenteredLabel col="4" class="value" text="Dump" />
      <Button col="5" class="button add-new-btn" text="+" @tap="onAddNew" />
    </GridLayout>
    <ListView height="100%" row="1" ref="scrollable" class="tally-table-list" for="item in cycles">
      <v-template>
        <TallyTableRow
          :cycle="item"
          :assets="loadUnits"
          :locations="locations"
          :materialTypes="materialTypes"
          :relativeLevels="relativeLevels"
          :shots="shots"
          @more="onEditCycle(item)"
        />
      </v-template>
    </ListView>
  </GridLayout>
</template>

<script>
import { mapState } from 'vuex';
import CenteredLabel from '../../../common/CenteredLabel.vue';
import TallyTableRow from './TallyTableRow.vue';

import TallyEditModal from '../../modals/TallyEditModal.vue';
import { uniq } from '../../../code/helper';

const LOAD_UNIT_TYPES = ['Excavator', 'Loader', 'Scratchy'];

export default {
  name: 'TallyTable',
  components: {
    CenteredLabel,
    TallyTableRow,
  },
  props: {
    asset: { type: Object, required: true },
    operator: { type: Object, required: true },
  },
  computed: {
    ...mapState('constants', {
      loadUnits: state => state.assets.filter(a => LOAD_UNIT_TYPES.includes(a.type)),
      locations: state => state.locations,
      materialTypes: state => state.materialTypes,
    }),
    cycles() {
      return this.$store.state.haulTruck.manualCycles;
    },
    relativeLevels() {
      return uniq(this.cycles.map(c => c.relativeLevel).filter(r => r));
    },
    shots() {
      return uniq(this.cycles.map(c => c.shot).filter(s => s));
    },
  },
  methods: {
    onAddNew() {
      const now = Date.now();
      const opts = {
        cycle: {
          assetId: this.asset.id,
          operatorId: this.operator.id,
          startTime: new Date(now),
          endTime: new Date(now),
        },
        loadUnits: this.loadUnits,
        locations: this.locations,
        materialTypes: this.materialTypes,
        relativeLevels: this.relativeLevels,
        shots: this.shots,
      };
      this.$modalBus.open(TallyEditModal, opts).onClose(newCycle => {
        if (newCycle) {
          newCycle.timestamp = new Date();
          this.$store.dispatch('haulTruck/submitManualCycle', {
            cycle: newCycle,
            channel: this.$channel,
          });
        }
      });
    },
    onEditCycle(cycle) {
      const opts = {
        cycle,
        loadUnits: this.loadUnits,
        locations: this.locations,
        materialTypes: this.materialTypes,
        relativeLevels: this.relativeLevels,
        shots: this.shots,
      };

      this.$modalBus.open(TallyEditModal, opts).onClose(newCycle => {
        if (newCycle) {
          newCycle.timestamp = new Date();
          this.$store.dispatch('haulTruck/submitManualCycle', {
            cycle: newCycle,
            channel: this.$channel,
          });
        }
      });
    },
  },
};
</script>

<style>
.tally-table {
  height: 100%;
  width: 100%;
}

.tally-table .header {
  background-color: rgba(255, 255, 255, 0.1);
}

.tally-table .add-new-btn {
  font-size: 30;
  padding: 0;
}

.tally-table .tally-table-row {
  height: 120;
  border-width: 0.5;
  border-top-color: gray;
  border-bottom-color: gray;
  border-left-color: transparent;
  border-right-color: transparent;
}

.tally-table .header .value {
  font-size: 26;
}

.tally-table .tally-table-row .value {
  font-size: 22;
}
</style>