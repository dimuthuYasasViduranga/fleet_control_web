<template>
  <div class="time-code-editor">
    <TimeCodeEditorModal
      :show="showEditModal"
      :timeCode="pendingTimeCode"
      :timeCodes="timeCodes"
      :timeCodeGroups="timeCodeGroups"
      :timeCodeCategories="timeCodeCategories"
      @close="onEditorClose"
    />
    <button class="hx-btn" @click="onSetEdit()">Create New</button>
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No Time Codes to show"
      :data="formattedTimeCodes"
      :show-caption="false"
      :show-filter="true"
      sort-by="code"
    >
      <table-column cell-class="table-cel" label="Code" show="code" />
      <table-column cell-class="table-cel" label="Name" show="name" />
      <table-column cell-class="table-cel" label="Group" show="groupName" />
      <table-column cell-class="table-cel" label="Category" show="categoryName" />
      <table-column cell-class="table-cel icon-cel">
        <template slot-scope="row">
          <div class="edit-wrapper">
            <Icon
              v-if="row.name !== 'No Task'"
              v-tooltip="'Edit'"
              class="edit-icon"
              :icon="editIcon"
              @click="onSetEdit(row)"
            />
          </div>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { attributeFromList } from '@/code/helpers';
import { TableComponent, TableColumn } from 'vue-table-component';
import TimeCodeEditorModal from './TimeCodeEditorModal.vue';

import EditIcon from '@/components/icons/Edit.vue';

export default {
  name: 'TimeCodeEditor',
  components: {
    TableComponent,
    TableColumn,
    Icon,
    TimeCodeEditorModal,
  },
  props: {
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    timeCodeCategories: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      search: '',
      editIcon: EditIcon,
      pendingTimeCode: null,
    };
  },
  computed: {
    showEditModal() {
      return !!this.pendingTimeCode;
    },
    formattedTimeCodes() {
      const groups = this.timeCodeGroups;
      const categories = this.timeCodeCategories;
      return this.timeCodes.map(tc => {
        const groupName = attributeFromList(groups, 'id', tc.groupId, 'name');
        const categoryName = attributeFromList(categories, 'id', tc.categoryId, 'name');
        return {
          id: tc.id,
          code: tc.code,
          name: tc.name,
          groupId: tc.groupId,
          groupName,
          categoryId: tc.categoryId,
          categoryName,
        };
      });
    },
  },
  methods: {
    onSetEdit(row) {
      const timeCode = row || {};
      this.pendingTimeCode = {
        id: timeCode.id,
        code: timeCode.code,
        name: timeCode.name,
        groupId: timeCode.groupId,
      };
    },
    onEditorClose() {
      this.pendingTimeCode = null;
    },
  },
};
</script>

<style>
.time-code-editor .icon-cel {
  width: 2rem;
  height: 3.5rem;
}

.time-code-editor .edit-icon {
  cursor: pointer;
  padding: 4px;
  height: 100%;
  margin-left: 1rem;
}

.time-code-editor .edit-icon:hover {
  stroke: orange;
}
</style>