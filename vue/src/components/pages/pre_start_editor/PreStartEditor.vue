<template>
  <div class="pre-start-editor">
    <hxCard title="Pre-Start Editor" :icon="reportIcon">
      <div class="mode-selector">
        <button
          class="hx-btn"
          v-for="(mode, index) in ['forms', 'categories']"
          :key="index"
          :class="{ selected: mode === selectedMode }"
          @click="setMode(mode)"
        >
          {{ mode }}
        </button>
      </div>

      <div v-if="selectedMode === 'forms'" class="form-editor-wrapper">
        <div class="actions">
          <DropDown
            :value="assetTypeId"
            :options="assetTypes"
            placeholder="Select Asset"
            label="type"
            clearable
            @change="onAssetTypeChange"
          />
          <template v-if="!readonly && assetTypeId">
            <button class="hx-btn" @click="onConfirmSubmit()">Submit</button>
            <button class="hx-btn" @click="onReset()">Reset</button>
          </template>
        </div>
        <template v-if="assetTypeId">
          <button v-if="!readonly" class="hx-btn" @click="onCopyFrom()">Copy From</button>
          <PreStartFormEditor v-if="assetTypeId" v-model="form" :readonly="readonly" />
        </template>
      </div>
      <PreStartCategoryEditor v-else :readonly="readonly" />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import { DropDown } from 'hx-vue';

import PreStartFormEditor from './PreStartFormEditor.vue';
import PreStartCategoryEditor from './PreStartCategoryEditor.vue';
import ConfirmModal from '@/components/modals/ConfirmModal.vue';

import ReportIcon from '@/components/icons/Report.vue';
import CopyFromModal from './CopyFromModal.vue';

function getFirstValidationError(form) {
  if (form.sections.length === 0) {
    return 'Must have at least 1 section';
  }

  for (const s of form.sections) {
    if (!s.title) {
      return 'All sections must have titles';
    }

    if (s.controls.length === 0) {
      return `'${s.title}' must have at least 1 criteria`;
    }

    for (const c of s.controls) {
      if (!c.label) {
        return `'${s.title}' has empty criteria`;
      }
    }
  }
}

function formToPayload(assetTypeId, form) {
  return {
    asset_type_id: assetTypeId,
    sections: form.sections.map(s => {
      return {
        title: s.title,
        details: s.details,
        controls: s.controls.map(c => {
          return {
            label: c.label,
            requires_comment: c.requiresComment,
            category_id: c.categoryId,
          };
        }),
      };
    }),
  };
}

function toForm(preStartForm) {
  if (!preStartForm) {
    return null;
  }
  return {
    title: '',
    details: '',
    sections: preStartForm.sections.map(s => {
      return {
        title: s.title,
        details: s.details,
        controls: s.controls.map(c => {
          return {
            label: c.label,
            requiresComment: c.requiresComment,
            categoryId: c.categoryId,
          };
        }),
      };
    }),
  };
}

export default {
  name: 'PreStartEditor',
  components: {
    hxCard,
    PreStartFormEditor,
    DropDown,
    PreStartCategoryEditor,
  },
  data: () => {
    return {
      reportIcon: ReportIcon,
      form: null,
      assetTypeId: null,
      selectedMode: 'forms',
    };
  },
  computed: {
    ...mapState('constants', {
      readonly: state => !state.permissions.fleet_control_edit_pre_starts,
      assetTypes: state => state.assetTypes,
      preStartForms: state => state.preStartForms,
      categories: state => state.preStartControlCategories,
    }),
  },
  methods: {
    setMode(mode) {
      this.selectedMode = mode;
    },
    onAssetTypeChange(typeId) {
      this.assetTypeId = typeId;
      const preStartForm = this.preStartForms.find(ps => ps.assetTypeId === typeId);
      this.form = toForm(preStartForm);
    },
    onReset() {
      this.onAssetTypeChange(this.assetTypeId);
    },
    onCopyFrom() {
      const opts = {
        preStartForms: this.preStartForms,
        assetTypes: this.assetTypes,
        categories: this.categories,
      };

      this.$modal.create(CopyFromModal, opts).onClose(resp => {
        if (resp) {
          this.form = toForm(resp);
        }
      });
    },
    onConfirmSubmit() {
      this.$modal
        .create(ConfirmModal, {
          title: 'Submit Pre-Start?',
          body: 'Are you sure you want to create this Pre-Start?',
        })
        .onClose(answer => {
          if (answer === 'ok') {
            this.submit();
          }
        });
    },
    submit() {
      if (!this.assetTypeId) {
        this.$toaster.error('Must select asset type');
        return;
      }

      const error = getFirstValidationError(this.form);

      if (error) {
        this.$toaster.error(error);
        return;
      }

      const payload = formToPayload(this.assetTypeId, this.form);

      this.$channel
        .push('pre-start:add form', payload)
        .receive('ok', () => this.$toaster.info('Pre-start submitted'))
        .receive('error', resp => this.$toaster.error(resp.error))
        .receive('timeout', () => this.$toaster.error('Unable to update pre-start'));
    },
  },
};
</script>

<style>
.pre-start-editor .mode-selector {
  margin-bottom: 1rem;
}

.pre-start-editor .mode-selector .hx-btn {
  width: 12rem;
  border-left: 1px solid #364c59;
  border-right: 1px solid #364c59;
  text-transform: capitalize;
}

.pre-start-editor .mode-selector .hx-btn.selected {
  background-color: #2c404c;
  border: 1px solid #898f94;
}

.pre-start-editor .actions .drop-down {
  display: inline-flex;
  min-width: 10rem;
}

.pre-start-editor .actions .drop-down .v-select {
  width: 100%;
}

.pre-start-editor .actions {
  padding-bottom: 2rem;
}

.pre-start-editor .actions .hx-btn {
  width: 8rem;
  margin-left: 0.5rem;
}

.pre-start-editor .pre-start-form-editor {
  margin: auto;
  max-width: 60rem;
}
</style>