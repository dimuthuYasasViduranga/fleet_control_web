<template>
  <div class="time-span-editor-modal">
    <TimeSpanEditor
      :asset="asset"
      :timeAllocations="allocations"
      :deviceAssignments="deviceAssignments"
      :timeusage="timeusage"
      :cycles="cycles"
      :devices="devices"
      :operators="operators"
      :timeCodes="timeCodes"
      :timeCodeGroups="timeCodeGroups"
      :allowedTimeCodeIds="allowedTimeCodeIds"
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
import TimeSpanEditor from '@/components/pages/time_allocation/TimeSpanEditor.vue';

export default {
  name: 'TimeSpanEditorModal',
  components: {
    TimeSpanEditor,
  },
  props: {
    asset: { type: Object, required: true },
    allocations: { type: Array, default: () => [] },
    deviceAssignments: { type: Array, default: () => [] },
    timeusage: { type: Array, default: () => [] },
    cycles: { type: Array, default: () => [] },
    devices: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    allowedTimeCodeIds: { type: Array, default: () => [] },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
    shifts: { type: Array, default: () => [] },
    shiftTypes: { type: Array, default: () => [] },
    shiftId: { type: Number, default: null },
  },
  computed: {
    ...mapState('constants', {
      canEdit: state => state.permissions.can_edit_time_allocations,
      canLock: state => state.permissions.can_lock_time_allocations,
    }),
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
  },
};
</script>