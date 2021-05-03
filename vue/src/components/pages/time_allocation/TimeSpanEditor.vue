<template>
  <modal class="time-span-editor-modal" :show="show" @close="onClose" @tran-open-end="onFullyOpen">
    <hxCard :title="title" :icon="timeIcon">
      <div class="chart-area">
        <TimeSpanChart
          v-if="ready"
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
              <LoginTooltip
                v-else-if="timeSpan.group === 'device-assignment'"
                :timeSpan="timeSpan"
              />
              <TimeusageTooltip v-else-if="timeSpan.group === 'timeusage'" :timeSpan="timeSpan" />
              <CycleTooltip v-else-if="timeSpan.group === 'cycle'" :timeSpan="timeSpan" />
              <EventTooltip v-else-if="timeSpan.group === 'event'" :timeSpan="timeSpan" />
              <DefaultTooltip v-else :timeSpan="timeSpan" />
            </div>
          </template>
        </TimeSpanChart>
      </div>
    </hxCard>
    <hxCard class="pane-card" :hideTitle="true">
      <button
        v-if="!events"
        class="hx-btn add-report"
        :disabled="reportInTransit"
        @click="onGenerateReport"
      >
        <div class="text">Add report</div>
        <Loading :isLoading="reportInTransit" />
      </button>
      <button v-else class="hx-btn remove-report" @click="onRemoveReport">Remove Report</button>
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
            class="hx-btn errors"
            :class="{ selected: pane === 'errors' }"
            :disabled="errorCount === 0"
            @click="setPane('errors')"
          >
            Errors ({{ errorCount }})
          </button>
          <button
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
            :timeSpans="nonDeletedAllocationTimeSpans"
            :errorTimeSpans="errorAllocationTimeSpans"
            :selectedAllocationId="selectedAllocationId"
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
            v-model="newTimeAllocation"
            :allowedTimeCodeIds="allowedTimeCodeIds"
            :minDatetime="minDatetime"
            :maxDatetime="maxDatetime"
            :timezone="timezone"
            @create="onNewTimeAllocation"
            @override="onNewTimeAllocationOverride"
          />

          <TimelinePane
            v-else
            :height="paneHeight"
            :maxShown="paneMaxItems"
            :timeSpans="level0AllocationTimeSpans"
            :timeCodes="timeCodes"
            :allowedTimeCodeIds="allowedTimeCodeIds"
            :selectedAllocationId="selectedAllocationId"
            :minDatetime="localMinDatetime"
            :maxDatetime="localMaxDatetime"
            :timezone="timezone"
            @rowSelect="onRowSelect"
            @changes="onRowChanges"
            @end="onTimeSpanEnd"
          />
        </div>
        <div class="gap"></div>
        <div class="buttons" v-if="shiftId">
          <button class="hx-btn lock" @click="onConfirmLock">Lock All</button>
          <button class="hx-btn unlock" @click="onConfirmUnlock">Unlock All</button>
        </div>
        <div class="buttons">
          <button class="hx-btn update" @click="onUpdate">Submit Changes</button>
          <button class="hx-btn cancel" @click="onCancel">Cancel</button>
          <button class="hx-btn reset" @click="onReset">Reset</button>
        </div>
      </div>
    </hxCard>
  </modal>
</template>

<script>
import hxCard from 'hx-layout/Card.vue';
import Loading from 'hx-layout/Loading.vue';
import Modal from '../../modals/Modal.vue';
import LoadingModal from '../../modals/LoadingModal.vue';
import ConfirmModal from '../../modals/ConfirmModal.vue';

import TimeSpanChart from './chart/TimeSpanChart.vue';

import DefaultTooltip from './tooltips/DefaultTimeSpanTooltip.vue';
import AllocationTooltip from './tooltips/AllocationTimeSpanTooltip.vue';
import LoginTooltip from './tooltips/LoginTimeSpanTooltip.vue';
import TimeusageTooltip from './tooltips/TimeusageTimeSpanTooltip.vue';
import CycleTooltip from './tooltips/CycleTimeSpanTooltip.vue';
import EventTooltip from './tooltips/EventTimeSpanTooltip.vue';

import TimelinePane from './editor_panes/timeline/TimelineTable.vue';
import ErrorPane from './editor_panes/error/ErrorPane.vue';
import NewPane from './editor_panes/new/NewPane.vue';

import TimeIcon from '../../icons/Time.vue';
import AddIcon from '../../icons/Add.vue';

import { copyDate, isDateEqual, toUtcDate } from '../../../code/time';
import { uniq, chunkEvery } from '../../../code/helpers';
import {
  toAllocationTimeSpans,
  allocationStyle,
  allocationColors,
} from './timespan_formatters/timeAllocationTimeSpans';
import {
  toDeviceAssignmentSpans,
  loginStyle,
} from './timespan_formatters/deviceAssignmentTimeSpans';
import { toTimeusageTimeSpans, timeusageStyle } from './timespan_formatters/timeusageTimeSpans';
import { toCycleTimeSpans, cycleStyle } from './timespan_formatters/cycleTimeSpans';
import { toEventTimeSpans, eventStyle } from './timespan_formatters/eventTimeSpans';
import {
  addDynamicLevels,
  overrideAll,
  findOverlapping,
  copyTimeSpan,
  isOverlapping,
} from './timeSpan';

const LOCK_WARNING = `
Are you sure you want lock the given allocations?

You may not be able to unlock them
`;

const UNLOCK_WARNING = `
Are you sure you want to unlock the given allocations?

Users will be able to edit the given allocations
`;

let ID = -1;

function getNextId() {
  const id = ID;
  ID -= 1;
  return id;
}

function toLocalAllocation(allocation) {
  return {
    id: allocation.id,
    assetId: allocation.assetId,
    startTime: copyDate(allocation.startTime),
    endTime: copyDate(allocation.endTime),
    timeCodeId: allocation.timeCodeId,
    lockId: allocation.lockId,
  };
  return allocation;
}

function addActiveEndTime(timeSpan, activeEndTime) {
  if (!timeSpan.endTime) {
    timeSpan.activeEndTime = activeEndTime;
  }

  return timeSpan;
}

function updateArrayAt(arr, index, item) {
  if (index > arr.length) {
    return arr;
  }

  const newArr = arr.slice();
  newArr[index] = item;
  return newArr;
}

function getChartLayoutGroups([TASpans, DASpans, TUSpans, cycleSpans, eventSpans], asset) {
  const allocation = {
    group: 'allocation',
    label: 'Al',
    percent: 0.5,
    subgroups: uniq(TASpans.map(ts => ts.level || 0)),
  };

  const otherGroups = [
    {
      group: 'device-assignment',
      label: 'Op',
      subgroups: uniq(DASpans.map(ts => ts.level || 0)),
    },
    {
      group: 'timeusage',
      label: 'TU',
      subgroups: uniq((TUSpans || []).map(ts => ts.level || 0)),
    },
    {
      group: 'cycle',
      label: 'C',
      subgroups: uniq((cycleSpans || []).map(ts => ts.level || 0)),
    },
    {
      group: 'event',
      label: 'Ev',
      subgroups: uniq((eventSpans || []).map(ts => ts.level || 0)),
    },
  ].filter(g => g.subgroups.length !== 0);

  const nOtherGroups = otherGroups.length;
  otherGroups.forEach(g => (g.percent = (1 - allocation.percent) / nOtherGroups));

  return otherGroups.concat([allocation]);
}

function styleSelected(timeSpan, style, selectedAllocId) {
  if (!selectedAllocId) {
    return style;
  }

  if (timeSpan.group === 'allocation' && timeSpan.data.id === selectedAllocId) {
    return style;
  }

  return {
    ...style,
    opacity: 0.1,
    strokeOpacity: 0.2,
  };
}

function getAllocChanges(originalAllocs, newAllocs) {
  const changes = [];
  newAllocs.forEach(na => {
    // if no id or negative id (ie newly created)
    if (!na || na.id < 0) {
      changes.push(na);
      return;
    }

    const originalAlloc = originalAllocs.find(a => a.id === na.id);
    if (isDifferentAlloc(originalAlloc, na)) {
      changes.push(na);
    }
  });
  return changes;
}

function isDifferentAlloc(a, b) {
  return (
    a.deleted !== b.deleted ||
    a.timeCodeId !== b.timeCodeId ||
    !isDateEqual(a.startTime, b.startTime) ||
    !isDateEqual(a.endTime, b.endTime)
  );
}

function nullifyDuplicateIds(timeSpans) {
  const length = timeSpans.length;
  chunkEvery(timeSpans, length, 1).map(list => {
    const first = list.shift();
    list.forEach(ts => {
      if (ts.data.id === first.data.id) {
        ts.data.id = null;
      }
    });
  });
  return timeSpans;
}

function defaultNewTimeAllocation() {
  return {
    timeCodeId: null,
    startTime: null,
    endTime: null,
  };
}

function parseEvent(event) {
  return {
    event: event.event,
    startTime: toUtcDate(event.start_time),
    endTime: toUtcDate(event.end_time),
    spans: event.spans,
    compliance: event.compliance,
    details: event.details,
  };
}

function toEpoch(date) {
  return date ? date.getTime() : null;
}

export default {
  name: 'TimeSpanEditor',
  components: {
    hxCard,
    Loading,
    Modal,
    TimeSpanChart,
    DefaultTooltip,
    AllocationTooltip,
    LoginTooltip,
    TimeusageTooltip,
    CycleTooltip,
    EventTooltip,
    TimelinePane,
    ErrorPane,
    NewPane,
  },
  props: {
    show: { type: Boolean, default: false },
    asset: { type: Object, required: true },
    timeAllocations: { type: Array, default: () => [] },
    deviceAssignments: { type: Array, default: () => [] },
    activeEndTime: { type: Date, default: () => new Date() },
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
    shiftId: { type: Number, default: null },
  },
  data: () => {
    return {
      updateInTransit: false,
      timeIcon: TimeIcon,
      addIcon: AddIcon,
      pane: 'timeline',
      ready: false,
      selectedAllocationId: null,
      localTimeAllocations: [],
      localMinDatetime: null,
      localMaxDatetime: null,
      contextHeight: 80,
      paneHeight: 250,
      paneMaxItems: 5,
      lockWarning: LOCK_WARNING,
      unlockWarning: UNLOCK_WARNING,
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
      newTimeAllocation: defaultNewTimeAllocation(),
      errorCount: 0,
      events: null,
      reportInTransit: false,
    };
  },
  computed: {
    title() {
      return `Time Span Editor - ${this.asset.name}`;
    },
    timeSpanColors() {
      return allocationColors();
    },
    timeSpans() {
      const activeEndTime = this.activeEndTime;
      const timeAllocations = this.localTimeAllocations.filter(lta => lta.deleted !== true);
      const transientAllocation = this.newTimeAllocation;
      if (transientAllocation.startTime && transientAllocation.endTime) {
        timeAllocations.push(transientAllocation);
      }
      const TASpans = toAllocationTimeSpans(
        timeAllocations,
        this.timeCodes,
        this.timeCodeGroups,
      ).map(ts => addActiveEndTime(ts, activeEndTime));

      const DASpans = toDeviceAssignmentSpans(
        this.deviceAssignments,
        this.devices,
        this.operators,
      ).map(ts => addActiveEndTime(ts, activeEndTime));

      const TUSpans = toTimeusageTimeSpans(this.timeusage)
        .map(ts => addActiveEndTime(ts, activeEndTime))
        .reverse();

      const cycleSpans = toCycleTimeSpans(this.cycles).map(ts =>
        addActiveEndTime(ts, activeEndTime),
      );

      const eventSpans = toEventTimeSpans(this.events || []).map(ts =>
        addActiveEndTime(ts, activeEndTime),
      );
      const [validEventSpans] = addDynamicLevels(eventSpans);

      return [TASpans, DASpans, TUSpans, cycleSpans, validEventSpans];
    },
    chartLayout() {
      const groups = getChartLayoutGroups(this.timeSpans, this.asset);

      return {
        groups,
        padding: 2,
      };
    },
    nonDeletedAllocationTimeSpans() {
      return toAllocationTimeSpans(
        this.localTimeAllocations.filter(a => a.deleted !== true),
        this.timeCodes,
        this.timeCodeGroups,
      );
    },
    level0AllocationTimeSpans() {
      return this.nonDeletedAllocationTimeSpans.filter(a => a.level === 0);
    },
    errorAllocationTimeSpans() {
      return this.nonDeletedAllocationTimeSpans.filter(a => a.level !== 0);
    },
  },
  watch: {
    show: {
      immediate: true,
      handler(doShow) {
        this.events = null;
        if (doShow) {
          this.pane = 'timeline';
          this.setLocalTimeAllocations(this.timeAllocations);
        }
      },
    },
    errorAllocationTimeSpans: {
      immediate: true,
      handler(errors = []) {
        this.setErrorCount(errors.length);
      },
    },
  },
  methods: {
    syncLocalTimeAllocations() {
      this.setLocalTimeAllocations(this.timeAllocations);
    },
    setLocalTimeAllocations(allocations = []) {
      this.localTimeAllocations = allocations.map(toLocalAllocation);
    },
    onClose() {
      this.ready = false;
      this.$emit('close');
    },
    onFullyOpen() {
      this.setSelect(null);
      this.setLocalTimeAllocations(this.timeAllocations);
      this.localMinDatetime = copyDate(this.minDatetime);
      this.localMaxDatetime = copyDate(this.maxDatetime);
      this.ready = true;
    },
    setPane(pane) {
      const timeSpan = this.nonDeletedAllocationTimeSpans.find(
        ts => ts.data.id === this.selectedAllocationId,
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

      this.newTimeAllocation = defaultNewTimeAllocation();

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
        this.selectedAllocationId = null;
        return;
      }

      if (timeSpan.group !== 'allocation') {
        return;
      }

      const id = timeSpan.data.id;

      if (id === this.selectedAllocationId) {
        this.selectedAllocationId = null;
        return;
      }

      this.selectedAllocationId = id;

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

        case 'device-assignment':
          style = loginStyle(timeSpan, region);
          break;

        case 'timeusage':
          style = timeusageStyle(timeSpan, region);
          break;

        case 'cycle':
          style = cycleStyle(timeSpan, region);
          break;

        case 'event':
          style = eventStyle(timeSpan, region);
          break;
      }

      return styleSelected(timeSpan, style, this.selectedAllocationId);
    },
    onRowSelect(timeSpan) {
      this.setSelect(timeSpan);

      // create a new timespan from the selection
      if (this.pane === 'new' && timeSpan.group !== 'allocation') {
        const startTime = copyDate(
          Math.max(toEpoch(timeSpan.startTime), toEpoch(this.minDatetime)),
        );
        const endTime = copyDate(
          Math.min(toEpoch(timeSpan.endTime || timeSpan.activeEndTime), toEpoch(this.maxDatetime)),
        );
        this.newTimeAllocation = {
          ...this.newTimeAllocation,
          startTime,
          endTime,
        };
      }
    },
    onRowChanges(timeSpans) {
      this.setSelect(null);
      let localAllocations = this.localTimeAllocations;
      nullifyDuplicateIds(timeSpans).forEach(ts => {
        const newAllocation = {
          ...ts.data,
          id: ts.data.id || getNextId(),
          startTime: copyDate(ts.startTime),
          endTime: copyDate(ts.endTime),
          deleted: ts.deleted || ts.data.deleted || false,
        };

        const originalIndex = localAllocations.findIndex(a => a.id === ts.data.id);

        if (originalIndex !== -1) {
          localAllocations = updateArrayAt(localAllocations, originalIndex, newAllocation);
        } else {
          // insert a new element
          localAllocations.push(newAllocation);
        }
      });

      this.localTimeAllocations = localAllocations;
    },
    onNewTimeAllocation(allocation) {
      this.newTimeAllocation = {};
      if (!this.asset.id) {
        console.error('[TimeAllocEditor] Cannot create new allocation without an asset');
        return;
      }
      const newAlloc = {
        id: getNextId(),
        assetId: this.asset.id,
        startTime: copyDate(allocation.startTime),
        endTime: copyDate(allocation.endTime),
        timeCodeId: allocation.timeCodeId,
      };

      this.localTimeAllocations.push(newAlloc);
    },
    onNewTimeAllocationOverride(allocation) {
      this.newTimeAllocation = {};
      if (!this.asset.id) {
        console.error('[TimeAllocEditor] Cannot override new allocation without an asset');
        return;
      }

      const newAlloc = {
        id: getNextId(),
        assetId: this.asset.id,
        startTime: copyDate(allocation.startTime),
        endTime: copyDate(allocation.endTime),
        timeCodeId: allocation.timeCodeId,
      };

      const newTimeSpan = toAllocationTimeSpans([newAlloc], this.timeCodes, this.timeCodeGroups)[0];

      const overlapping = findOverlapping(newTimeSpan, this.nonDeletedAllocationTimeSpans);
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
        console.error('[TimeAllocEditor] Cannot end timespan when end time exists');
        return;
      }

      // find the element for the given time span and update its end times
      const updateIndex = this.localTimeAllocations.findIndex(lta => lta.id === timeSpan.data.id);

      if (updateIndex < 0) {
        console.error('[TimeAllocEditor] Cannot end time allocation that does not exist');
        return;
      }

      const updatedAlloc = this.localTimeAllocations[updateIndex];
      updatedAlloc.endTime = copyDate(timeSpan.activeEndTime);
      updatedAlloc.activeEndTime = null;
      const updatedAllocations = updateArrayAt(
        this.localTimeAllocations,
        updateIndex,
        updatedAlloc,
      );

      // create a new allocation the same as the ended one, with different start and ent time
      const newAllocation = {
        ...timeSpan.data,
        id: getNextId(),
        startTime: copyDate(timeSpan.activeEndTime),
        endTime: null,
      };
      updatedAllocations.push(newAllocation);

      this.localTimeAllocations = updatedAllocations;
    },
    onUpdate() {
      // remove selection
      this.setSelect(null);

      // get a list of all the original ids
      const originalIds = this.timeAllocations.map(ta => ta.id);

      const allIdsPresent = this.localTimeAllocations
        .map(a => a.id)
        .filter(id => id && id > 0)
        .every(id => originalIds.some(oId => oId === id));

      if (!allIdsPresent) {
        console.error('[TimeAllocEditor] There are missing ids when trying to update');
        return;
      }

      // calculate the changes
      const changes = getAllocChanges(this.timeAllocations, this.localTimeAllocations);
      this.submitChanges(changes);
    },
    onCancel() {
      this.$emit('cancel');
      this.onClose();
    },
    onReset() {
      this.$emit('reset');
      this.setSelect(null);
      this.syncLocalTimeAllocations();
    },
    submitChanges(changes = []) {
      if (changes.length === 0) {
        console.log('[TimeAllocEditor] No changes to submit');
        this.onClose();
        return;
      }

      if (this.updateInTransit) {
        console.error('[TimeAllocEditor] Changes already in transit');
        return;
      }

      const payload = changes.map(c => {
        const id = !c.id || c.id < 0 ? null : c.id;
        return {
          id,
          asset_id: c.assetId,
          time_code_id: c.timeCodeId,
          start_time: c.startTime,
          end_time: c.endTime,
          deleted: c.deleted || false,
        };
      });

      this.pushTopic('edit time allocations', payload, 'Editing Time Allocations', 'update');
    },
    pushTopic(topic, payload, loadingMsg, emitEvent) {
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
          this.$emit('update');
          this.onClose();
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
    onConfirmLock() {
      this.$modal
        .create(ConfirmModal, { title: 'Lock Time Allocations', body: LOCK_WARNING })
        .onClose(answer => {
          if (answer !== 'ok') {
            return;
          }

          if (this.updateInTransit) {
            console.error('[TimeAllocEditor] Changes already in transit');
            return;
          }

          if (!this.shiftId) {
            console.error('[TimeAllocEditor] Cannot lock elements without a given shift');
            return;
          }

          const ids = this.timeAllocations.filter(a => a.id > 0 && !a.lockId).map(a => a.id);

          if (ids.length === 0) {
            console.error('[TimeAllocEditor] No ids to lock');
            return;
          }

          const payload = {
            ids,
            calendar_id: this.shiftId,
          };

          this.pushTopic('lock time allocations', payload, 'Locking Time Allocations', 'lock');
        });
    },
    onConfirmUnlock() {
      this.$modal
        .create(ConfirmModal, { title: 'Unlock Time Allocations', body: UNLOCK_WARNING })
        .onClose(answer => {
          if (answer !== 'ok') {
            return;
          }

          if (this.updateInTransit) {
            console.error('[TimeAllocEditor] Changes already in transit');
            return;
          }

          const ids = this.timeAllocations.filter(a => a.lockId).map(a => a.id);

          if (ids.length === 0) {
            console.error('[TimeAllocEditor] No ids to lock');
            return;
          }

          this.pushTopic('unlock time allocations', ids, 'Unlocking Time Allocations', 'unlock');
        });
    },
    onGenerateReport() {
      const payload = {
        start_time: this.minDatetime,
        end_time: this.maxDatetime,
        asset_ids: [this.asset.id],
      };

      this.reportInTransit = true;

      this.$channel
        .push('report:time allocation', payload)
        .receive('ok', data => {
          this.reportInTransit = false;
          const reports = data.reports;

          if (!reports) {
            this.events = null;
          } else {
            this.events = (reports || []).map(r => r.events.map(parseEvent)).flat();
          }
        })
        .receive('error', () => {
          console.error('[TimeAllocEditor] Could not get report');
          this.$toaster.error('Could not fetch report');
          this.reportInTransit = false;
        })
        .receive('timeout', () => {
          console.error('[TimeAllocEditor] Could not get report. Timed out');
          this.$toaster.noComms('Unable to fetch report');
          this.reportInTransit = false;
        });
    },
    onRemoveReport() {
      this.events = null;
    },
  },
};
</script>

<style>
@import '../../../assets/hxInput.css';

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