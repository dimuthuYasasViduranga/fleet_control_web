<template>
  <div class="time-code-group-editor">
    <TimeCodeGroupEditorModal :show="showEditModal" :group="pendingGroup" @close="onEditorClose" />
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No Operators to Show"
      :data="timeCodeGroups"
      :show-caption="false"
      :show-filter="false"
      sort-by="id"
    >
      <table-column cell-class="table-cel" label="Name" show="name" />
      <table-column cell-class="table-cel" label="Alias" show="alias" />
      <table-column cell-class="table-cel icon-cel">
        <template slot-scope="row">
          <div class="edit-wrapper">
            <Icon v-tooltip="'Edit'" class="edit-icon" :icon="editIcon" @click="onSetEdit(row)" />
          </div>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import EditIcon from '@/components/icons/Edit.vue';
import TimeCodeGroupEditorModal from './TimeCodeGroupEditorModal.vue';

export default {
  name: 'TimeCodeGroupEditor',
  components: {
    Icon,
    TableComponent,
    TableColumn,
    TimeCodeGroupEditorModal,
  },
  props: {
    timeCodeGroups: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      editIcon: EditIcon,
      pendingGroup: null,
    };
  },
  computed: {
    showEditModal() {
      return !!this.pendingGroup;
    },
  },
  methods: {
    onSetEdit(row) {
      const group = row || {};
      this.pendingGroup = {
        id: group.id,
        name: group.name,
        alias: group.alias,
      };
    },
    onEditorClose() {
      this.pendingGroup = null;
    },
  },
};
</script>

<style>
.time-code-group-editor .icon-cel {
  width: 2rem;
  height: 3.5rem;
}

.time-code-group-editor .edit-icon {
  cursor: pointer;
  padding: 4px;
  height: 100%;
  margin-left: 1rem;
}

.time-code-group-editor .edit-icon:hover {
  stroke: orange;
}
</style>

