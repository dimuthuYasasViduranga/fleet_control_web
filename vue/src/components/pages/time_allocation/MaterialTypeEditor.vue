<template>
  <div class="time-span-editor-modal">
    <hxCard :title="title" :icon="timeIcon">
      <div class="chart-area">
        <TimeSpanChart
          :name="`${this.asset.name}-editor`"
          :timeSpans="timeSpans.flat()"
          :layout="chartLayout"
          :margins="margins"
          :contextHeight="contextHeight"
          :colors="timeSpanColors"
          :styler="timeSpanStyler"
          :minDatetime="localMinDatetime"
          :maxDatetime="localMaxDatetime"
          @select="onRowSelect"
        >
          <template slot-scope="timeSpan">
            <div class="__tooltip-boundary">
              <AllocationTooltip v-if="timeSpan.group === 'allocation'" :timeSpan="timeSpan" />
              <MaterialTypeToolTip
                v-else-if="timeSpan.group === 'dig-unit-activity'"
                :timeSpan="timeSpan"
              />
              <LoginTooltip
                v-else-if="timeSpan.group === 'device-assignment'"
                :timeSpan="timeSpan"
              />
              <EventTooltip v-else-if="timeSpan.group === 'event'" :timeSpan="timeSpan" />
              <ShiftTooltip v-else-if="timeSpan.group === 'shift'" :timeSpan="timeSpan" />
              <DefaultTooltip v-else :timeSpan="timeSpan" />
            </div>
          </template>
        </TimeSpanChart>
      </div>
    </hxCard>
    <hxCard class="pane-card" :hideTitle="true">
      <div class="pane-wrapper">
        <div class="pane-selector">
          <button
            class="hx-btn timeline"
            :class="{ selected: pane === 'timeline' }"
            @click="setPane('timeline')"
          >
            Timeline
          </button>
          <button
            v-if="canEdit"
            class="hx-btn errors"
            :class="{ selected: pane === 'errors' }"
            :disabled="errorCount === 0"
            @click="setPane('errors')"
          >
            Errors ({{ errorCount }})
          </button>
          <button
            v-if="canEdit"
            class="hx-btn errors"
            :class="{ selected: pane === 'new' }"
            @click="setPane('new')"
          >
            Create New
          </button>
        </div>

        <div class="pane">
          <ErrorPane
            v-if="pane === 'errors'"
            :height="paneHeight"
            :maxShown="paneMaxItems"
            :isMaterialTimeline="isMaterialTimeline"
            :timeSpans="nonDeletedActivityTimeSpans"
            :errorTimeSpans="errorAllocationTimeSpans"
            :selectedAllocationId="selectedActivityId"
            :allowedTimeCodeIds="allowedTimeCodeIds"
            :minDatetime="minDatetime"
            :maxDatetime="maxDatetime"
            :timezone="timezone"
            @rowSelect="onRowSelect"
            @changes="onRowChanges"
            @cancel="setSelect(null)"
          />

          <NewPane
            v-else-if="pane === 'new'"
            v-model="newDigUnitActivity"
            :isMaterialTimeline="isMaterialTimeline"
            :allowedTimeCodeIds="allowedTimeCodeIds"
            :minDatetime="minDatetime"
            :maxDatetime="maxDatetime"
            :timezone="timezone"
            @create="onNewDigActivity"
            @override="onNewDigActivityOverride"
          />

          <TimelinePane
            v-else
            :readonly="!canEdit"
            :isMaterialTimeline="isMaterialTimeline"
            :height="paneHeight"
            :maxShown="paneMaxItems"
            :timeSpans="level0AllocationTimeSpans"
            :timeCodes="timeCodes"
            :allowedTimeCodeIds="allowedTimeCodeIds"
            :selectedAllocationId="selectedActivityId"
            :minDatetime="localMinDatetime"
            :maxDatetime="localMaxDatetime"
            :timezone="timezone"
            @rowSelect="onRowSelect"
            @changes="onRowChanges"
            @end="onTimeSpanEnd"
          />
        </div>
        <div class="gap"></div>
        <div v-if="canEdit || canLock" class="buttons">
          <button class="hx-btn update" @click="onUpdate">Submit Changes</button>
          <button class="hx-btn cancel" @click="onCancel">Cancel</button>
          <button class="hx-btn reset" @click="onReset">Reset</button>
        </div>
      </div>
    </hxCard>
  </div>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import LoadingModal from '@/components/modals/LoadingModal.vue';

import TimeSpanChart from './chart/TimeSpanChart.vue';

import DefaultTooltip from './tooltips/DefaultTimeSpanTooltip.vue';
import AllocationTooltip from './tooltips/AllocationTimeSpanTooltip.vue';
import MaterialTypeToolTip from './tooltips/MaterialTypeToolTip.vue';
import LoginTooltip from './tooltips/LoginTimeSpanTooltip.vue';
import EventTooltip from './tooltips/EventTimeSpanTooltip.vue';
import ShiftTooltip from './tooltips/ShiftTimeSpanTooltip.vue';

import TimelinePane from './editor_panes/timeline/TimelineTable.vue';
import ErrorPane from './editor_panes/error/ErrorPane.vue';
import NewPane from './editor_panes/new/NewPane.vue';

import TimeIcon from '../../icons/Time.vue';
import AddIcon from '../../icons/Add.vue';

import { copyDate, toEpoch } from '@/code/time';
import {
  toAllocationTimeSpans,
  allocationStyle,
  allocationColors,
} from './timespan_formatters/timeAllocationTimeSpans';
import { toDigUnitActivitySpans, materialStyle } from './timespan_formatters/digUnitActivitySpans';
import {
  toDeviceAssignmentSpans,
  loginStyle,
} from './timespan_formatters/deviceAssignmentTimeSpans';
import { shiftStyle } from './timespan_formatters/shiftTimeSpans';
import { toEventTimeSpans, eventStyle } from './timespan_formatters/eventTimeSpans';
import { addDynamicLevels, overrideAll, findOverlapping, copyTimeSpan } from './timeSpan';
import * as ActivityEdit from './MaterialTypeEditor';

export default {
  name: 'TimeSpanEditor',
  components: {
    hxCard,
    TimeSpanChart,
    DefaultTooltip,
    AllocationTooltip,
    LoginTooltip,
    EventTooltip,
    ShiftTooltip,
    MaterialTypeToolTip,
    TimelinePane,
    ErrorPane,
    NewPane,
  },
  props: {
    show: { type: Boolean, default: false },
    asset: { type: Object, required: true },
    timeAllocations: { type: Array, default: () => [] },
    digUnitActivities: { type: Array, default: () => [] },
    deviceAssignments: { type: Array, default: () => [] },
    activeEndTime: { type: Date, default: () => new Date() },
    operators: { type: Array, default: () => [] },
    devices: { type: Array, default: () => [] },
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
    canEdit: Boolean,
    canLock: Boolean,
  },
  data: () => {
    return {
      updateInTransit: false,
      timeIcon: TimeIcon,
      addIcon: AddIcon,
      pane: 'timeline',
      isMaterialTimeline: true,
      selectedActivityId: null,
      localTimeAllocations: [],
      localDigUnitActivities: [],
      localMinDatetime: null,
      localMaxDatetime: null,
      contextHeight: 80,
      paneHeight: 250,
      paneMaxItems: 5,
      margins: {
        focus: {
          top: 0,
          left: 25,
          right: 5,
          bottom: 30,
        },
        context: {
          top: 15,
          left: 25,
          right: 5,
          bottom: 30,
        },
      },
      newDigUnitActivity: ActivityEdit.defaultNewDigUnitActivity(),
      errorCount: 0,
      events: null,
      reportInTransit: false,
    };
  },
  computed: {
    title() {
      return `Material Time Span Editor - ${this.asset.name}`;
    },
    timeSpanColors() {
      return allocationColors();
    },
    timeSpans() {
      const activeEndTime = this.activeEndTime;

      const timeAllocations = this.timeAllocations.filter(lta => lta.deleted !== true);
      const TASpans = toAllocationTimeSpans(
        timeAllocations,
        this.timeCodes,
        this.timeCodeGroups,
      ).map(ts => ActivityEdit.addActiveEndTime(ts, activeEndTime));

      const digUnitActivities = this.localDigUnitActivities.filter(lda => lda.deleted !== true);
      const transientActivity = this.newDigUnitActivity;

      if (transientActivity.startTime && transientActivity.endTime) {
        digUnitActivities.push(transientActivity);
      }

      const DUASpans = toDigUnitActivitySpans(digUnitActivities, this.materialTypes).map(ts =>
        ActivityEdit.addActiveEndTime(ts, activeEndTime),
      );

      const DASpans = toDeviceAssignmentSpans(
        this.deviceAssignments,
        this.devices,
        this.operators,
      ).map(ts => ActivityEdit.addActiveEndTime(ts, activeEndTime));

      const eventSpans = toEventTimeSpans(this.events || []).map(ts =>
        ActivityEdit.addActiveEndTime(ts, activeEndTime),
      );

      const ShiftSpans = ActivityEdit.toShiftSpans(this.shifts, this.shiftTypes, [
        this.minDatetime,
        this.maxDatetime,
      ]);

      const [validEventSpans] = addDynamicLevels(eventSpans);

      return [TASpans, DUASpans, DASpans, validEventSpans, ShiftSpans];
    },
    chartLayout() {
      const groups = ActivityEdit.getChartLayoutGroups(this.timeSpans);

      return {
        groups,
        padding: 2,
      };
    },
    nonDeletedActivityTimeSpans() {
      return toDigUnitActivitySpans(
        this.localDigUnitActivities.filter(a => a.deleted !== true),
        this.materialTypes,
      );
    },

    level0AllocationTimeSpans() {
      return this.nonDeletedActivityTimeSpans.filter(a => a.level === 0);
    },
    errorAllocationTimeSpans() {
      return this.nonDeletedActivityTimeSpans.filter(a => a.level !== 0);
    },
  },
  watch: {
    errorAllocationTimeSpans: {
      immediate: true,
      handler(errors = []) {
        this.setErrorCount(errors.length);
      },
    },
  },
  mounted() {
    this.events = null;
    this.pane = 'timeline';
    this.setSelect(null);
    this.setLocalDigUnitActivities(this.digUnitActivities);
    this.localMinDatetime = copyDate(this.minDatetime);
    this.localMaxDatetime = copyDate(this.maxDatetime);
  },
  methods: {
    syncLocalDigUnitActivities() {
      this.setLocalDigUnitActivities(this.digUnitActivities);
    },
    setLocalDigUnitActivities(digUnitActivities = []) {
      this.localDigUnitActivities = ActivityEdit.toLocalDigUnitActivities(
        digUnitActivities,
        this.maxDatetime,
      );
    },
    setPane(pane) {
      const timeSpan = this.nonDeletedActivityTimeSpans.find(
        ts => ts.data.id === this.selectedActivityId,
      );

      if (timeSpan && timeSpan.level === 0 && pane !== 'timeline') {
        this.setSelect(null);
      }

      if (timeSpan && timeSpan.level !== 0 && pane !== 'errors') {
        this.setSelect(null);
      }

      if (pane === 'new') {
        this.setSelect(null);
      }

      this.newDigUnitActivity = ActivityEdit.defaultNewDigUnitActivity();

      this.pane = pane;
    },
    setErrorCount(count = 0) {
      this.errorCount = count;
      if (count === 0 && this.pane === 'errors') {
        // revert back to showing the timeline if there are no errors
        this.setPane('timeline');
      }
    },
    setSelect(timeSpan) {
      if (!timeSpan) {
        this.selectedActivityId = null;
        return;
      }

      if (timeSpan.group !== 'dig-unit-activity') {
        return;
      }

      const id = timeSpan.data.id;

      if (id === this.selectedActivityId) {
        this.selectedActivityId = null;
        return;
      }

      this.selectedActivityId = id;

      // change views to show where the element is located
      const pane = timeSpan.level === 0 ? 'timeline' : 'errors';
      this.setPane(pane);
    },
    timeSpanStyler(timeSpan, region) {
      let style = {};
      switch (timeSpan.group) {
        case 'allocation':
          style = allocationStyle(timeSpan, region);
          break;

        case 'dig-unit-activity':
          style = materialStyle(timeSpan, region, this.materialTypes);
          break;

        case 'device-assignment':
          style = loginStyle(timeSpan, region);
          break;

        case 'event':
          style = eventStyle(timeSpan, region);
          break;

        case 'shift':
          style = shiftStyle(timeSpan, region);
      }

      return ActivityEdit.styleSelected(timeSpan, style, this.selectedActivityId);
    },
    onRowSelect(timeSpan) {
      this.setSelect(timeSpan);

      // create a new timespan from the selection
      if (this.pane === 'new' && timeSpan.group !== 'dig-unit-activity') {
        const startTime = copyDate(
          Math.max(toEpoch(timeSpan.startTime), toEpoch(this.minDatetime)),
        );
        const endTime = copyDate(
          Math.min(toEpoch(timeSpan.endTime || timeSpan.activeEndTime), toEpoch(this.maxDatetime)),
        );
        this.newDigUnitActivity = {
          ...this.newDigUnitActivity,
          startTime,
          endTime,
        };
      }
    },
    onRowChanges(timeSpans) {
      this.setSelect(null);
      let localDigUnitActivities = this.localDigUnitActivities;
      ActivityEdit.nullifyDuplicateIds(timeSpans).forEach(ts => {
        const newActivity = {
          ...ts.data,
          id: ts.data.id || ActivityEdit.getNextId(),
          locationId: ts.data.locationId,
          startTime: copyDate(ts.startTime),
          endTime: copyDate(ts.endTime),
          deleted: ts.deleted || ts.data.deleted || false,
        };

        const originalIndex = localDigUnitActivities.findIndex(a => a.id === ts.data.id);

        if (originalIndex !== -1) {
          localDigUnitActivities = ActivityEdit.updateArrayAt(
            localDigUnitActivities,
            originalIndex,
            newActivity,
          );
        } else {
          // insert a new element
          localDigUnitActivities.push(newActivity);
        }
      });

      this.localDigUnitActivities = localDigUnitActivities;
    },
    onNewDigActivity(activity) {
      this.newDigUnitActivity = {};
      if (!this.asset.id) {
        console.error('[DigUnitActivityEditor] Cannot create new activity without an asset');
        return;
      }
      const newActivity = {
        id: ActivityEdit.getNextId(),
        assetId: this.asset.id,
        startTime: copyDate(activity.startTime),
        endTime: copyDate(activity.endTime),
        materialTypeId: activity.materialTypeId,
      };

      this.localDigUnitActivities.push(newActivity);
    },
    onNewDigActivityOverride(activity) {
      this.newDigUnitActivity = {};
      if (!this.asset.id) {
        console.error('[DigUnitActivityEditor] Cannot override new activity without an asset');
        return;
      }

      const newActivity = {
        id: ActivityEdit.getNextId(),
        assetId: this.asset.id,
        startTime: copyDate(activity.startTime),
        endTime: copyDate(activity.endTime),
        materialTypeId: activity.materialTypeId,
      };

      const newTimeSpan = toDigUnitActivitySpans([newActivity], this.materialTypes)[0];

      const overlapping = findOverlapping(newTimeSpan, this.nonDeletedActivityTimeSpans);
      const highestLevel = Math.max(...overlapping.map(ts => ts.level || 0));
      const timeSpansToOverride = overlapping
        .filter(ts => (ts.level || 0) === highestLevel)
        .map(copyTimeSpan);

      const changes = overrideAll(newTimeSpan, timeSpansToOverride);
      changes.forEach(ts => (ts.data.deleted = ts.deleted));
      this.onRowChanges(changes);
    },
    onTimeSpanEnd(timeSpan) {
      if (timeSpan.endTime) {
        console.error('[DigUnitActivityEditor] Cannot end timespan when end time exists');
        return;
      }

      // find the element for the given time span and update its end times
      const updateIndex = this.localDigUnitActivities.findIndex(lta => lta.id === timeSpan.data.id);

      if (updateIndex < 0) {
        console.error('[DigUnitActivityEditor] Cannot end time activity that does not exist');
        return;
      }

      const updatedActivity = this.localDigUnitActivities[updateIndex];
      updatedActivity.endTime = copyDate(timeSpan.activeEndTime);
      // updatedActivity.activeEndTime = null;

      const updatedActivities = ActivityEdit.updateArrayAt(
        this.localDigUnitActivities,
        updateIndex,
        updatedActivity,
      );

      // create a new activity the same as the ended one, with different start and ent time
      const newActivity = {
        data: timeSpan.data,
        id: ActivityEdit.getNextId(),
        assetId: timeSpan.data.assetId,
        materialTypeId: timeSpan.data.materialTypeId,
        locationId: timeSpan.data.locationId,
        startTime: copyDate(timeSpan.activeEndTime),
        endTime: null,
      };

      updatedActivities.push(newActivity);

      this.localDigUnitActivities = updatedActivities;
    },
    onUpdate() {
      // remove selection
      this.setSelect(null);

      // get a list of all the original ids
      const originalIds = this.digUnitActivities.map(ta => ta.id);

      const allIdsPresent = this.localDigUnitActivities
        .map(a => a.id)
        .filter(id => id && id > 0)
        .every(id => originalIds.some(oId => oId === id));

      if (!allIdsPresent) {
        console.error('[DigUnitActivityEditor] There are missing ids when trying to update');
        return;
      }

      // calculate the changes
      const changes = ActivityEdit.getActivityChanges(
        this.digUnitActivities,
        this.localDigUnitActivities,
      );
      this.submitChanges(changes);
    },
    onCancel() {
      this.$emit('cancel');
    },
    onReset() {
      this.setSelect(null);
      this.syncLocalDigUnitActivities();
    },
    submitChanges(changes = []) {
      if (changes.length === 0) {
        console.log('[DigUnitActivityEditor] No changes to submit');
        this.onCancel();
        return;
      }

      if (this.updateInTransit) {
        console.error('[DigUnitActivityEditor] Changes already in transit');
        return;
      }

      const payload = changes.map(c => {
        const id = !c.id || c.id < 0 ? null : c.id;
        return {
          id,
          asset_id: c.assetId,
          material_type_id: c.materialTypeId,
          location_id: c.locationId,
          start_time: c.startTime,
          end_time: c.endTime,
          deleted: c.deleted || false,
        };
      });

      this.pushTopic(
        'dig:edit',
        payload,
        'Editing Dig Unit Activities',
        'update',
        'Dig Unit Activities Updated',
      );
    },
    pushTopic(topic, payload, loadingMsg, emitEvent, toast) {
      const loading = this.$modal.create(
        LoadingModal,
        { message: loadingMsg },
        { clickOutsideClose: false },
      );

      this.updateInTransit = true;

      this.$channel
        .push(topic, payload)
        .receive('ok', () => {
          this.updateInTransit = false;
          loading.close();
          this.$emit(emitEvent);
          this.$toaster.info(toast);
        })
        .receive('error', error => {
          this.updateInTransit = false;
          loading.close();
          this.$toaster.error(error.error);
        })
        .receive('timeout', () => {
          this.updateInTransit = false;
          loading.close();
          this.$toaster.error('Request time out');
        });
    },
  },
};
</script>

<style>
@import '../../../assets/styles/hxInput.css';

/* --- modal styling --- */
.time-span-editor-modal .modal-container-wrapper > .modal-container {
  background-color: #121f26;
  max-width: 1000px;
}

.time-span-editor-modal > .modal-container-wrapper {
  padding: 4% 5%;
  max-height: 100%;
}

.time-span-editor-modal .hxCard {
  background-color: transparent;
  padding: 0;
}

/* --- chart styling --- */

.time-span-editor-modal .chart-area {
  width: 100%;
  height: 250px;
}

/* --- pane styling --- */
.time-span-editor-modal .add-report,
.time-span-editor-modal .remove-report {
  display: block;
  float: right;
  margin: 0.25rem 0;
}

.time-span-editor-modal .add-report {
  display: flex;
}

.time-span-editor-modal .add-report .loading-wrapper {
  margin-left: 0.5rem;
  width: 2rem;
  height: 2rem;
  padding: 5px;
}

.time-span-editor-modal .add-report .loading-wrapper svg {
  width: 100%;
  height: 100%;
}

.time-span-editor-modal .add-report[disabled] {
  opacity: 0.5;
}

.time-span-editor-modal .pane-selector {
  width: 100%;
  display: flex;
  align-items: stretch;
}

.time-span-editor-modal .pane {
  border: 2px solid #364c59;
  height: 280px;
}

.time-span-editor-modal .pane-selector .hx-btn {
  flex: 1;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
}

.time-span-editor-modal .pane-selector .hx-btn.selected {
  border: 2px solid #b6c3cc;
}

.time-span-editor-modal .pane-selector .hx-btn:disabled {
  background-color: #293238;
  color: #757575;
  cursor: default;
}

.time-span-editor-modal .gap {
  margin-top: 1rem;
}

.time-span-editor-modal .buttons {
  margin-top: 0.1rem;
  display: flex;
  align-items: stretch;
}

.time-span-editor-modal .buttons .hx-btn {
  flex: 1;
  margin: 0.1rem;
}
</style>
