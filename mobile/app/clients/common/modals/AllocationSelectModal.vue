<template>
  <GridLayout class="allocation-select-modal" rows="* 5*">
    <!-- may need to hide this one some times
      because it may be required that only an exception can be selected
      ie. when logging out
     -->
    <FlexboxLayout colSpan="4" flexDirection="row">
      <Button
        flexGrow="1"
        class="button group-selector"
        textTransform="capitalize"
        v-for="(name, index) in groups"
        :key="index"
        :isEnabled="selectedGroup !== name"
        :text="getGroupName(name)"
        @tap="setGroup(name)"
      />
    </FlexboxLayout>
    <NestedItemList row="1" :items="shownItems" @select="onTimeCodeSelect" />
  </GridLayout>
</template>

<script>
import { mapState } from 'vuex';
import { flattenTree, toTree } from '../../code/tree';
import NestedItemList from '../NestedItemList.vue';
import { attributeFromList } from '../../code/helper';

const ALLOWED_GROUPS = ['Ready', 'Process', 'Standby', 'Down'];

function toItem(timeCodes, element) {
  const timeCode = timeCodes.find(tc => tc.id === element.timeCodeId);
  const name = (timeCode || element).name;
  return {
    id: element.id,
    assetTypeId: element.assetTypeId,
    timeCodeId: element.timeCodeId,
    name,
    parentId: element.parentId,
    timeCodeGroupId: element.timeCodeGroupId,
  };
}

function copy(element) {
  return JSON.parse(JSON.stringify(element));
}

function childrenOf(tree, groups, groupName) {
  const group = groups.find(g => g.name === groupName);
  if (!group) {
    return [];
  }

  const treeRoot = tree.find(r => r.timeCodeGroupId === group.id);
  if (!treeRoot) {
    return [];
  }

  const children = flattenTree(treeRoot)
    .filter(e => e.id !== treeRoot.id)
    .map(copy);
  children.forEach(e => {
    if (e.parentId === treeRoot.id) {
      e.parentId = null;
    }
  });

  return children;
}

export default {
  name: 'AllocationSelectModal',
  components: {
    NestedItemList,
  },
  props: {
    asset: { type: Object, default: null },
    operator: { type: Object, default: null },
    group: { type: String, default: 'Process' },
    groups: { type: Array, default: () => ALLOWED_GROUPS },
  },
  data: () => {
    return {
      selectedGroup: 'Ready',
      tree: [],
      itemGroups: {
        Ready: [],
        Process: [],
        Standby: [],
        Down: [],
      },
    };
  },
  computed: {
    ...mapState('constants', {
      timeCodes: state => state.timeCodes,
      timeCodeGroups: state => state.timeCodeGroups,
      timeCodeTreeElements: state => state.timeCodeTreeElements,
    }),
    items() {
      return this.timeCodeTreeElements.map(e => toItem(this.timeCodes, e));
    },
    shownItems() {
      return this.itemGroups[this.selectedGroup] || [];
    },
    timeCodeGroupNames() {
      const map = {};
      this.timeCodeGroups.map(tcg => {
        map[tcg.name] = tcg.siteName;
      });
      return map;
    },
  },
  watch: {
    group: {
      immediate: true,
      handler(group, oldGroup) {
        if (!oldGroup) {
          this.setGroup(group);
        }
      },
    },
    timeCodeTreeElements: {
      immediate: true,
      handler(elements) {
        if (!elements) {
          return;
        }

        this.tree = toTree(this.items);

        const groups = this.timeCodeGroups;
        this.itemGroups = {
          Ready: childrenOf(this.tree, groups, 'Ready'),
          Process: childrenOf(this.tree, groups, 'Process'),
          Standby: childrenOf(this.tree, groups, 'Standby'),
          Down: childrenOf(this.tree, groups, 'Down'),
        };
      },
    },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    getGroupName(name) {
      return this.timeCodeGroupNames[name] || name;
    },
    setGroup(group) {
      if (this.groups.includes(group)) {
        this.selectedGroup = group;
      } else {
        console.error(`[AllocSelect] Cannot use group '${group}'`);
        this.selectedGroup = this.groups[0];
      }
    },
    onTimeCodeSelect(event) {
      this.close({ timeCodeId: event.timeCodeId });
    },
  },
};
</script>

<style>
.allocation-select-modal {
  width: 70%;
  height: 90%;
  background-color: #1c323d;
  padding: 20;
  border-width: 1;
  border-color: #d6d7d7;
}

.allocation-select-modal .group-selector {
  font-size: 24;
}

.allocation-select-modal .button:disabled {
  background-color: lightslategray;
  color: white;
}
</style>