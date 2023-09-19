<template>
  <div class="error-pane">
    <ErrorTable
      v-if="!timeSpanToFix"
      :isMaterialTimeline="isMaterialTimeline"
      :height="height"
      :maxShow="maxShown"
      :timeSpans="errorTimeSpans"
      :allowedTimeCodeIds="allowedTimeCodeIds"
      :selectedAllocationId="selectedAllocationId"
      :minDatetime="minDatetime"
      :maxDatetime="maxDatetime"
      :timezone="timezone"
      @rowSelect="onRowSelect"
      @change="onRowChange"
      @fix="onFixStart"
    />
    <FixPane
      v-else
      :isMaterialTimeline="isMaterialTimeline"
      :refTimeSpan="timeSpanToFix"
      :timeSpans="timeSpans"
      :minDatetime="minDatetime"
      :maxDatetime="maxDatetime"
      :timezone="timezone"
      @cancel="onFixCancel"
      @changes="onFixChanges"
    />
  </div>
</template>

<script>
import ErrorTable from './ErrorTable.vue';
import FixPane from './FixPane.vue';

export default {
  name: 'ErrorPane',
  components: {
    ErrorTable,
    FixPane,
  },
  props: {
    isMaterialTimeline: { type: Boolean, default: () => false },
    timeSpans: { type: Array, default: () => [] },
    errorTimeSpans: { type: Array, default: () => [] },
    selectedAllocationId: { type: Number, default: null },
    allowedTimeCodeIds: { type: Array, default: () => [] },
    height: { type: Number, default: 250 },
    maxShown: { type: Number, default: 10 },
    minDatetime: { type: Date, default: null },
    maxDatetime: { type: Date, default: null },
    timezone: { type: String, default: 'local' },
  },
  data: () => {
    return {
      timeSpanToFix: null,
    };
  },
  methods: {
    onRowSelect(timeSpan) {
      this.$emit('rowSelect', timeSpan);
    },
    onRowChange(timeSpan) {
      this.$emit('changes', [timeSpan]);
    },
    onFixStart(timeSpan) {
      this.timeSpanToFix = timeSpan;
      this.onRowSelect(timeSpan);
    },
    onFixCancel() {
      this.timeSpanToFix = null;
      this.$emit('cancel');
    },
    onFixChanges(changes) {
      this.timeSpanToFix = null;
      this.$emit('changes', changes);
    },
  },
};
</script>
