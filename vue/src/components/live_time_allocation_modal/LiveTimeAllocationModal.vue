<template>
  <modal
    class="live-time-allocation-modal"
    :show="show"
    @close="close()"
    @tran-close-end="setSelectedAssetId(null)"
  >
    <TimeSpanEditor
      v-if="asset"
      :asset="asset"
      :timeAllocations="allocations"
      :digUnitActivities="digUnitActivities"
      :deviceAssignments="deviceAssignments"
      :timeusage="timeusage"
      :cycles="cycles"
      :devices="devices"
      :operators="operators"
      :timeCodes="timeCodes"
      :timeCodeGroups="timeCodeGroups"
      :allowedTimeCodeIds="allowedTimeCodeIds"
      :materialTypes="materialTypes"
      :minDatetime="minDatetime"
      :maxDatetime="maxDatetime"
      :timezone="timezone"
      :shifts="shifts"
      :shiftTypes="shiftTypes"
      @submit="close('submit')"
      @cancel="close('cancel')"
      @update="close('update')"
      @lock="close('lock')"
      @unlock="close('unlock')"
    />
  </modal>
</template>

<script>
import { mapState } from 'vuex';
import TimeSpanEditor from '@/components/pages/time_allocation/TimeSpanEditor.vue';
import Modal from '@/components/modals/Modal.vue';
import { attributeFromList } from '@/code/helpers';

const WINDOW_WIDTH_MS = 12 * 3600 * 1000;

export default {
  name: 'LiveTimeAllocationModal',
  components: {
    Modal,
    TimeSpanEditor,
  },
  data: () => {
    return {
      show: false,
      selectedAssetId: null,
      minDatetime: null,
      maxDatetime: null,
    };
  },
  computed: {
    ...mapState({
      allTimeAllocations: state =>
        state.historicTimeAllocations.concat(state.activeTimeAllocations),
      allTimeusage: state => state.fleetOps.timeusage,
      allCycles: state => state.fleetOps.cycles,
      devices: state => state.deviceStore.devices,
    }),
    ...mapState('digUnit', {
      liveActivities: state => state.liveActivities,
    }),
    ...mapState('deviceStore', {
      devices: state => state.devices,
      allDeviceAssignments: state =>
        state.historicDeviceAssignments.concat(state.currentDeviceAssignments),
    }),
    ...mapState('constants', {
      assets: state => state.assets,
      operators: state => state.operators,
      timeCodes: state => state.timeCodes,
      timeCodeGroups: state => state.timeCodeGroups,
      shifts: state => state.shifts,
      shiftTypes: state => state.shiftTypes,
      materialTypes: state => state.materialTypes,
    }),
    timezone() {
      return this.$timely.current.timestamp;
    },
    asset() {
      return attributeFromList(this.assets, 'id', this.selectedAssetId);
    },
    allocations() {
      const minEpoch = this.minDatetime ? this.minDatetime.getTime() : 0;
      return this.allTimeAllocations.filter(
        ta =>
          ta.assetId === this.selectedAssetId && (!ta.endTime || ta.endTime.getTime() > minEpoch),
      );
    },
    digUnitActivities() {
      return this.liveActivities.filter(dua => dua.assetId === this.selectedAssetId);
    },
    deviceAssignments() {
      return this.allDeviceAssignments.filter(da => da.assetId === this.selectedAssetId);
    },
    timeusage() {
      return this.allTimeusage.filter(tu => tu.assetId === this.selectedAssetId);
    },
    cycles() {
      return this.allCycles.filter(c => c.assetId === this.selectedAssetId);
    },
    allowedTimeCodeIds() {
      const assetTypeId = this.asset.typeId;
      return this.$store.getters['constants/fullTimeCodes']
        .filter(tc => tc.assetTypeIds.includes(assetTypeId))
        .map(tc => tc.id);
    },
  },
  created() {
    this.$eventBus.$on('live-time-allocation-open', this.open);
  },
  mounted() {
    this.$store.dispatch('updateFleetOpsData', this.$hostname);
  },
  methods: {
    close() {
      this.show = false;
    },
    open(assetId) {
      const asset = attributeFromList(this.assets, 'id', assetId);

      if (!asset) {
        console.error(`[Live TA] No asset matching id ${assetId}`);
        this.selectedAssetId(null);
        return;
      }

      this.setSelectedAssetId(assetId);
      this.maxDatetime = new Date();
      this.minDatetime = new Date(this.maxDatetime.getTime() - WINDOW_WIDTH_MS);
      this.show = true;
    },
    setSelectedAssetId(assetId) {
      this.selectedAssetId = assetId;
    },
  },
};
</script>
