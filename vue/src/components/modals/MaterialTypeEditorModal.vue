<template>
  <div class="time-span-editor-modal">
    <MaterialTypeEditor
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
      :shiftId="shiftId"
      :shifts="shifts"
      :shiftTypes="shiftTypes"
      :canEdit="canEdit"
      :canLock="canLock"
      @submit="close('submit')"
      @cancel="close('cancel')"
      @update="close('update')"
      @lock="close('lock')"
      @unlock="close('unlock')"
    />
  </div>
</template>

<script>
import { mapState } from 'vuex';
import MaterialTypeEditor from '@/components/pages/time_allocation/MaterialTypeEditor.vue';

export default {
  name: 'MaterialTypeEditorModal',
  components: {
    MaterialTypeEditor,
  },
  props: {
    asset: { type: Object, required: true },
    allocations: { type: Array, default: () => [] },
    digUnitActivities: { type: Array, default: () => [] },
    deviceAssignments: { type: Array, default: () => [] },
    timeusage: { type: Array, default: () => [] },
    cycles: { type: Array, default: () => [] },
    devices: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    allowedTimeCodeIds: { type: Array, default: () => [] },
    materialTypes: { type: Array, default: () => [] },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
    shifts: { type: Array, default: () => [] },
    shiftTypes: { type: Array, default: () => [] },
    shiftId: { type: Number, default: null },
  },
  computed: {
    ...mapState('constants', {
      canEdit: state => state.permissions.fleet_control_edit_time_allocations,
      canLock: state => state.permissions.fleet_control_lock_time_allocations,
    }),
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
  },
};
</script>
