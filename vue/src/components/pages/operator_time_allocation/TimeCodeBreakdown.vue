<template>
  <div class="time-code-breakdown">
    <table>
      <template v-for="group in allocsByGroup">
        <tr
          :key="group.groupName"
          class="group"
          :class="{ 'has-children': group.duration }"
          @click="onToggleShow(group.groupName, group.duration)"
        >
          <th>
            {{ group.groupAlias }}
            <span v-if="group.duration">{{ show[group.groupName] ? '-' : '+' }}</span>
          </th>
          <td>{{ formatDuration(group.duration) }}</td>
        </tr>
        <template v-if="show[group.groupName]">
          <tr class="time-code" v-for="timeCode in group.allocations" :key="timeCode.timeCode">
            <th>
              <ul class="name">
                {{
                  timeCode.timeCode
                }}
              </ul>
            </th>
            <td>{{ formatDuration(timeCode.duration) }}</td>
          </tr>
        </template>
      </template>
    </table>
  </div>
</template>

<script>
import { attributeFromList, Dictionary } from '@/code/helpers';
import { copyDate, formatSeconds } from '@/code/time';

const GROUP_ORDER = ['Ready', 'Process', 'Standby', 'Down'];

export default {
  name: 'TimeCodeBreakdown',
  props: {
    data: { type: Array, default: () => [] },
  },
  data: () => {
    const show = GROUP_ORDER.reduce((acc, key) => {
      acc[key] = false;
      return acc;
    }, {});
    return {
      show,
    };
  },
  computed: {
    timeCodeGroupAliases() {
      return this.$store.state.constants.timeCodeGroups.reduce((acc, group) => {
        acc[group.name] = group.siteName;
        return acc;
      }, {});
    },
    allocs() {
      return this.data.map(ts => {
        const duration = ts.endTime.getTime() - ts.startTime.getTime();
        return {
          startTime: ts.startTime,
          endTime: ts.endTime,
          duration,
          timeCode: ts.data.timeCode,
          timeCodeGroup: ts.data.timeCodeGroup,
        };
      });
    },
    allocsByGroup() {
      const byGroup = this.groupAllocsBy(this.allocs, 'timeCodeGroup');

      return GROUP_ORDER.map(groupName => {
        const group = attributeFromList(byGroup, 'timeCodeGroup', groupName) || {};

        const groupAlias = this.timeCodeGroupAliases[groupName];

        const allocations = this.groupAllocsBy(group.allocations || [], 'timeCode').sort((a, b) =>
          (a.timeCode || '').localeCompare(b.timeCode || ''),
        );

        return {
          groupName,
          groupAlias,
          allocations,
          duration: group.duration || 0,
          show: false,
        };
      });
    },
  },
  methods: {
    groupAllocsBy(allocs, key) {
      const dict = new Dictionary();

      allocs.forEach(a => dict.append(a[key], a));

      return dict.map((groupKey, values) => {
        const allocations = values || [];
        return {
          [key]: groupKey,
          allocations,
          duration: this.sumAllocs(allocations),
        };
      });
    },
    sumAllocs(allocs) {
      return allocs.reduce((acc, alloc) => acc + alloc.duration, 0);
    },
    formatDuration(ms) {
      const seconds = Math.trunc(ms / 1000);

      if (!seconds) {
        return '--';
      }
      return formatSeconds(seconds);
    },
    onToggleShow(groupName, duration) {
      if (duration) {
        this.show[groupName] = !this.show[groupName];
      }
    },
  },
};
</script>

<style>
.time-code-breakdown table {
  width: 100%;
  table-layout: fixed;
  text-align: left;
  border-collapse: collapse;
}

.time-code-breakdown table tr {
  height: 2.5rem;
  border-bottom: 0.05em solid #2c404c;
}

.time-code-breakdown table th {
  padding-left: 1rem;
}

.time-code-breakdown table .group {
  background-color: #232d3363;
}

.time-code-breakdown table .has-children {
  cursor: pointer;
}

.time-code-breakdown table .has-children :hover {
  opacity: 0.5;
}

.time-code-breakdown table .time-code ul {
  margin: 0rem;
}
</style>