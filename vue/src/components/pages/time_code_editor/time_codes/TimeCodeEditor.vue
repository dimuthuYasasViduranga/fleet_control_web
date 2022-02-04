<template>
  <div class="time-code-editor">
    <div v-if="!readonly" class="actions">
      <button class="hx-btn" @click="onCreate()">Create New</button>
      <button class="hx-btn" @click="onBulkAdd()">Bulk Add</button>
      <button class="hx-btn" @click="onExport()">Export To CSV</button>
    </div>

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
      <table-column cell-class="table-cel icon-cel" :hidden="readonly">
        <template slot-scope="row">
          <div class="edit-wrapper">
            <Icon
              v-if="!['No Task', 'Disabled'].includes(row.name)"
              v-tooltip="'Edit'"
              class="edit-icon"
              :icon="editIcon"
              @click="onEdit(row)"
            />
          </div>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import { writeToString } from '@fast-csv/format';

import Icon from 'hx-layout/Icon.vue';
import { attributeFromList, toLookup } from '@/code/helpers';
import { TableComponent, TableColumn } from 'vue-table-component';
import EditTimeCodeModal from './EditTimeCodeModal.vue';

import EditIcon from '@/components/icons/Edit.vue';
import { downloadFromText } from '@/code/io';

function exportAsCSV(timeCodes, groups, categories) {
  const groupLookup = toLookup(
    groups,
    g => g.id,
    g => g.name,
  );
  const catLookup = toLookup(
    categories,
    c => c.id,
    c => c.name,
  );

  const formattedTimeCodes = timeCodes
    .filter(tc => tc.id > 1)
    .map(tc => {
      return {
        code: tc.code,
        name: tc.name,
        group: groupLookup[tc.groupId],
        category: catLookup[tc.categoryId],
      };
    });

  const headers = ['code', 'name', 'group', 'category'];
  const rows = formattedTimeCodes.map(tc => headers.map(h => tc[h]));

  writeToString(rows, { headers }).then(text => {
    downloadFromText(text, `time_codes.csv`);
  });
}

export default {
  name: 'TimeCodeEditor',
  components: {
    TableComponent,
    TableColumn,
    Icon,
  },
  props: {
    readonly: Boolean,
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    timeCodeCategories: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      search: '',
      editIcon: EditIcon,
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
    onCreate() {
      const opts = {
        timeCodes: this.timeCodes,
        timeCodeGroups: this.timeCodeGroups,
        timeCodeCategories: this.timeCodeCategories,
      };

      this.$modal.create(EditTimeCodeModal, opts);
    },
    onEdit(timeCode) {
      const opts = {
        value: timeCode,
        timeCodes: this.timeCodes,
        timeCodeGroups: this.timeCodeGroups,
        timeCodeCategories: this.timeCodeCategories,
      };

      this.$modal.create(EditTimeCodeModal, opts);
    },
    onBulkAdd() {},
    onExport() {
      exportAsCSV(this.timeCodes, this.timeCodeGroups, this.timeCodeCategories);
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

.time-code-editor .actions {
  display: flex;
  padding-bottom: 1rem;
}

.time-code-editor .actions > * {
  margin-right: 0.25rem;
}
</style>