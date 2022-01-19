<template>
  <div class="bulk-add-operator-modal">
    <h1>Upload Operators</h1>
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

    <template v-if="pendingOperators.length">
      <table-component
        v-if="pendingOperators.length"
        table-wrapper="#content"
        table-class="table"
        tbody-class="table-body"
        thead-class="table-head"
        filterNoResults="No Operators to upload"
        :data="pendingOperators"
        :show-caption="false"
        :show-filter="false"
        sort-by="name"
      >
        <table-column cell-class="table-cel" label="Legal Name">
          <template slot-scope="row">
            <input
              v-tooltip="{ content: row.name ? '' : 'Missing name' }"
              class="typeable"
              :class="{ missing: !row.name }"
              v-model="row.name"
              placeholder="Legal Name"
              type="text"
              autocomplete="off"
            />
          </template>
        </table-column>

        <table-column cell-class="table-cel" label="Name">
          <template slot-scope="row">
            <input
              class="typeable"
              v-model="row.nickname"
              placeholder="Short Name (optional)"
              type="text"
              autocomplete="off"
            />
          </template>
        </table-column>

        <table-column cell-class="table-cel" label="Employee ID">
          <template slot-scope="row">
            <input
              v-tooltip="{ content: row.employeeId ? '' : 'Missing employeeId' }"
              class="typeable"
              :class="{ missing: !row.employeeId, duplicate: employeeIdCount[row.employeeId] > 1 }"
              v-model="row.employeeId"
              placeholder="Employee Id"
              type="number"
              autocomplete="off"
              pattern="\d+"
              min="0"
              step="1"
            />
          </template>
        </table-column>

        <table-column :sortable="false" :filterable="false" cell-class="table-btn-cel action-cel">
          <template slot-scope="row">
            <Icon class="delete-icon" :icon="crossIcon" @click="onRemove(row.employeeId)" />
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

import { getDefinitions, parseFile } from './parsers/parser.js';
import { Dictionary, toLookup, uniqBy } from '@/code/helpers.js';

export default {
  name: 'BulkAddOperatorModal',
  wrapperClass: 'bulk-add-operator-modal-wrapper',
  components: {
    FileInput,
    TableComponent,
    TableColumn,
    Icon,
  },
  props: {
    operators: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      processingFile: false,
      pendingOperators: [],
      crossIcon: CrossIcon,
      definitions: getDefinitions(),
      selectedDefinition: null,
    };
  },
  computed: {
    existingEmployeeIds() {
      return toLookup(
        this.operators,
        o => o.employeeId,
        () => true,
      );
    },
    employeeIdCount() {
      const dict = new Dictionary();
      this.operators.forEach(o => dict.append(o.employeeId));

      this.pendingOperators.forEach(o => dict.append(o.employeeId));

      return dict.reduce((acc, key, arr) => {
        acc[key] = arr.length;
        return acc;
      }, {});
    },
    dataValid() {
      const hasData = this.pendingOperators.length !== 0;
      const hasNames = this.pendingOperators.every(o => o.name);
      const hasEmployeeIds = this.pendingOperators.every(o => o.employeeId);
      const uniqEmployeeIds = Object.values(this.employeeIdCount).every(count => count === 1);

      return hasData && hasNames && hasEmployeeIds && uniqEmployeeIds;
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
          this.processingFile = false;
          const operators = resps.flat().filter(o => o.employeeId && o.name);
          const uniqOperators = uniqBy(operators, o => o.employeeId);

          if (uniqOperators.length === 0) {
            this.$toaster.error('No valid data found in the files');
            return;
          }

          const culledOperators = uniqOperators.filter(
            o => this.existingEmployeeIds[o.employeeId] !== true,
          );

          if (culledOperators.length === 0) {
            this.$toaster.info(
              'Data source only contained duplicates of existing operators',
              'long',
            );
            return;
          }

          this.pendingOperators = culledOperators;
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
    onRemove(employeeId) {
      this.pendingOperators = this.pendingOperators.filter(o => o.employeeId !== employeeId);
    },
    onClear() {
      this.pendingOperators = [];
    },
    onCancel() {
      this.close();
    },
    onSubmit() {
      const operators = this.pendingOperators.map(o => {
        return {
          name: o.name,
          nickname: o.name,
          employee_id: o.employeeId,
        };
      });

      const payload = { operators };
      this.$channel
        .push('bulk add operators', payload)
        .receive('ok', () => this.close())
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.noComms('Unable to bulk update at this time'));
    },
  },
};
</script>

<style>
.bulk-add-operator-modal-wrapper .modal-container {
  max-width: 45rem;
}

.bulk-add-operator-modal h1 {
  text-align: center;
}

/* examples */
.bulk-add-operator-modal .supported-definitions {
  display: flex;
}

.bulk-add-operator-modal .supported-definitions button {
  opacity: 0.9;
  border: 1px solid #364c59;
}

.bulk-add-operator-modal .supported-definitions button.selected {
  border-color: #b6c3cc;
  opacity: 1;
}

.bulk-add-operator-modal .definition {
  border-bottom: 1px solid #677e8c;
  margin-top: 1rem;
  padding-left: 1rem;
}

.bulk-add-operator-modal .definition .notes {
  margin-top: 0.5rem;
}

.bulk-add-operator-modal .definition .notes li {
  padding: 0.1rem 0;
}

.bulk-add-operator-modal .definition .example {
  padding: 0.5rem;
  background-color: #2c404c;
  overflow-x: auto;
}

/* file input */
.bulk-add-operator-modal .file-input {
  margin-top: 2rem;
}

/* table */
.bulk-add-operator-modal input.missing,
.bulk-add-operator-modal input.duplicate {
  background-color: darkred;
}

.bulk-add-operator-modal input.missing:focus,
.bulk-add-operator-modal input.duplicate:focus {
  color: #b6c3cc;
}

.bulk-add-operator-modal .delete-icon {
  cursor: pointer;
  height: 1.5rem;
}

.bulk-add-operator-modal .delete-icon:hover svg {
  stroke: #ff6565;
}

/* actions */
.bulk-add-operator-modal .actions {
  display: flex;
}

.bulk-add-operator-modal .actions .hx-btn {
  width: 100%;
  margin-left: 0.25rem;
}

.bulk-add-operator-modal .actions .hx-btn:first-child {
  margin-left: 0;
}

.bulk-add-operator-modal .actions .hx-btn[disabled] {
  cursor: default;
  opacity: 0.5;
}

.bulk-add-operator-modal .actions .hx-btn[disabled]:hover {
  background-color: #425866;
}
</style>