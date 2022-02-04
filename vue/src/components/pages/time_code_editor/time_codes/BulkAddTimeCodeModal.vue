<template>
  <div class="bulk-add-time-code-modal">
    <h1>Upload Time Codes</h1>
    <div>Supported files</div>
    <div class="supported-definitions">
      <button
        class="hx-btn"
        v-for="(definition, index) in definitions"
        :key="index"
        :class="{ selected: definition === selectedDefinition }"
        @click="onSetDefinition(definition)"
      >
        {{ definition.type }}
      </button>
    </div>
    <div v-if="selectedDefinition" class="definition">
      <div class="extensions">Expected extensions: {{ selectedDefinition.extensions }}</div>
      <div class="notes">
        <ul>
          <li v-for="(item, index) in selectedDefinition.notes" :key="index">
            <template v-if="Array.isArray(item)">
              {{ item[0] }}
              <ul>
                <li v-for="(subItem, index) in item[1]" :key="`sub-${index}`">
                  {{ subItem }}
                </li>
              </ul>
            </template>
            <template v-else>
              {{ item }}
            </template>
          </li>
        </ul>
      </div>
      <pre class="example">{{ selectedDefinition.example }}</pre>
      <button class="hx-btn" @click="onDownloadExample(selectedDefinition)">
        Download Example
      </button>
    </div>
    <FileInput
      :accepts="'.csv'"
      :multiple="true"
      :loading="processingFile"
      @upload="onUploadFile"
    />

    <template v-if="pendingTimeCodes.length">
      <table-component
        table-wrapper="#content"
        table-class="table"
        tbody-class="table-body"
        thead-class="table-head"
        filterNoResults="No Operators to upload"
        :data="pendingTimeCodes"
        :show-caption="false"
        :show-filter="false"
        sort-by="name"
      >
        <table-column cell-class="table-cel" label="Code">
          <template slot-scope="row">
            {{ row.code }}
          </template>
        </table-column>

        <table-column cell-class="table-cel" label="Name">
          <template slot-scope="row">
            <input
              v-tooltip="{ content: row.name ? '' : 'Missing name' }"
              class="typeable"
              :class="{ missing: !row.name }"
              v-model="row.name"
              placeholder="Name"
              type="text"
              autocomplete="off"
            />
          </template>
        </table-column>

        <table-column cell-class="table-cel" label="Group">
          <template slot-scope="row">
            <DropDown
              v-tooltip="{ content: row.groupId ? '' : 'Missing Group' }"
              :class="{ missing: !row.groupId }"
              value-is-id
              v-model="row.groupId"
              :options="timeCodeGroups"
              keyLabel="siteName"
              :clearable="false"
            />
          </template>
        </table-column>

        <table-column cell-class="table-cel" label="Category">
          <template slot-scope="row">
            <DropDown
              value-is-id
              v-model="row.categoryId"
              :options="timeCodeCategories"
              keyLabel="name"
            />
          </template>
        </table-column>

        <table-column :sortable="false" :filterable="false" cell-class="table-btn-cel action-cel">
          <template slot-scope="row">
            <Icon class="delete-icon" :icon="crossIcon" @click="onRemove(row.code)" />
          </template>
        </table-column>
      </table-component>

      <div class="actions">
        <button class="hx-btn" :disabled="!dataValid" @click="onSubmit()">Submit</button>
        <button class="hx-btn" @click="onClear()">Clear</button>
        <button class="hx-btn" @click="onCancel()">Cancel</button>
      </div>
    </template>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import FileInput from '@/components/FileInput.vue';
import { TableComponent, TableColumn } from 'vue-table-component';
import DropDown from '@/components/dropdown/DropDown.vue';
import { getDefinitions, parseFile } from './parsers/parser.js';
import { toLookup, uniq } from '@/code/helpers.js';

function linkTimeCodes(newTimeCodes, timeCodes, groups, categories) {
  const timeCodeLookup = toLookup(
    timeCodes,
    tc => tc.code.toLowerCase(),
    () => true,
  );

  const groupLookup = toLookup(
    groups,
    g => g.name.toLowerCase(),
    g => g.id,
  );
  const catLookup = toLookup(
    categories,
    c => c.name.toLowerCase(),
    c => c.id,
  );

  return newTimeCodes
    .filter(tc => !timeCodeLookup[(tc.code || '').toLowerCase()])
    .map(tc => {
      const groupName = (tc.group || '').toLowerCase();
      const categoryName = (tc.category || '').toLowerCase();
      return {
        name: tc.name,
        code: `${tc.code}`,
        groupId: groupLookup[groupName],
        categoryId: catLookup[categoryName],
      };
    });
}

export default {
  name: 'BulkAddTimeCodeModal',
  wrapperClass: 'bulk-add-time-code-modal-wrapper',
  components: {
    FileInput,
    TableComponent,
    TableColumn,
    Icon,
    DropDown,
  },
  props: {
    timeCodes: { type: Array, default: () => [] },
    timeCodeGroups: { type: Array, default: () => [] },
    timeCodeCategories: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      processingFile: false,
      pendingTimeCodes: [],
      crossIcon: CrossIcon,
      definitions: getDefinitions(),
      selectedDefinition: null,
    };
  },
  computed: {
    existingTimeCodes() {
      return toLookup(
        this.timeCodes,
        tc => tc.code,
        () => true,
      );
    },
    dataValid() {
      const hasData = this.pendingTimeCodes.length !== 0;
      const hasNames = this.pendingTimeCodes.every(tc => tc.name);
      const hasGroups = this.pendingTimeCodes.every(tc => tc.groupId);

      const codes = this.pendingTimeCodes.map(tc => tc.code);
      const hasUniqCodes =
        uniq(codes).length === codes.length && codes.every(c => !this.existingTimeCodes[c]);

      return hasData && hasNames && hasGroups && hasUniqCodes;
    },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onSetDefinition(definition) {
      if (this.selectedDefinition === definition) {
        this.selectedDefinition = null;
      } else {
        this.selectedDefinition = definition;
      }
    },
    onDownloadExample(definition) {
      definition.download();
    },
    onUploadFile(files) {
      this.processingFile = true;
      Promise.all(files.map(f => parseFile(f, this.definitions)))
        .then(resps => {
          const rawTimeCodes = resps.flat().filter(tc => tc.name && tc.code);

          if (rawTimeCodes.length === 0) {
            this.$toaster.error('No valid data found in the files');
            return;
          }

          const timeCodes = linkTimeCodes(
            rawTimeCodes,
            this.timeCodes,
            this.timeCodeGroups,
            this.timeCodeCategories,
          );
          this.processingFile = false;

          if (timeCodes.length === 0) {
            this.$toaster.info('Data source only contained duplicates');
            return;
          }

          this.pendingTimeCodes = timeCodes;
        })
        .catch(error => {
          this.processingFiles = false;

          if (files.length === 1) {
            this.$toaster.error('Could not process the uploaded file');
          } else {
            this.$toaster.error('Could not process one of the uploaded files');
          }
          console.error(error);
        });
    },
    onRemove(code) {
      this.pendingTimeCodes = this.pendingTimeCodes.filter(o => o.code !== code);
    },
    onClear() {
      this.pendingTimeCodes = [];
    },
    onCancel() {
      this.close();
    },
    onSubmit() {
      const timeCodes = this.pendingTimeCodes.map(tc => {
        return {
          name: tc.name,
          code: tc.code,
          group_id: tc.groupId,
          category_id: tc.categoryId || null,
        };
      });

      const payload = { time_codes: timeCodes };

      this.$channel
        .push('bulk add time codes', payload)
        .receive('ok', () => this.close())
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to bulk update at this time'));
    },
  },
};
</script>

<style>
.bulk-add-time-code-modal-wrapper .modal-container {
  max-width: 45rem;
}

.bulk-add-time-code-modal h1 {
  text-align: center;
}

/* examples */
.bulk-add-time-code-modal .supported-definitions {
  display: flex;
}

.bulk-add-time-code-modal .supported-definitions button {
  opacity: 0.9;
  border: 1px solid #364c59;
}

.bulk-add-time-code-modal .supported-definitions button.selected {
  border-color: #b6c3cc;
  opacity: 1;
}

.bulk-add-time-code-modal .definition {
  border-bottom: 1px solid #677e8c;
  margin-top: 1rem;
  padding-left: 1rem;
}

.bulk-add-time-code-modal .definition .notes {
  margin-top: 0.5rem;
}

.bulk-add-time-code-modal .definition .notes li {
  padding: 0.1rem 0;
}

.bulk-add-time-code-modal .definition .example {
  padding: 0.5rem;
  background-color: #2c404c;
  overflow-x: auto;
}

/* file input */
.bulk-add-time-code-modal .file-input {
  margin-top: 2rem;
}

/* table */
.bulk-add-time-code-modal input.missing,
.bulk-add-time-code-modal input.duplicate {
  background-color: darkred;
}

.bulk-add-time-code-modal input.missing:focus,
.bulk-add-time-code-modal input.duplicate:focus {
  color: #b6c3cc;
}

.bulk-add-time-code-modal .delete-icon {
  cursor: pointer;
  height: 1.5rem;
}

.bulk-add-time-code-modal .delete-icon:hover svg {
  stroke: #ff6565;
}

/* actions */
.bulk-add-time-code-modal .actions {
  display: flex;
}

.bulk-add-time-code-modal .actions .hx-btn {
  width: 100%;
  margin-left: 0.25rem;
}

.bulk-add-time-code-modal .actions .hx-btn:first-child {
  margin-left: 0;
}

.bulk-add-time-code-modal .actions .hx-btn[disabled] {
  cursor: default;
  opacity: 0.5;
}

.bulk-add-time-code-modal .actions .hx-btn[disabled]:hover {
  background-color: #425866;
}
</style>