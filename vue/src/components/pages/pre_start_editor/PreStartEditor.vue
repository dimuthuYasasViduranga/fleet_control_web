<template>
  <div class="pre-start-editor">
    <hxCard title="Pre-Start Editor" :icon="reportIcon">
      <div class="actions">
        <DropDown
          placeholder="Select Asset"
          :value="assetTypeId"
          :items="assetTypes"
          label="type"
          @change="onAssetTypeChange"
        />
        <button v-if="assetTypeId" class="hx-btn" @click="onConfirmSubmit">Submit</button>
      </div>
      <PreStartFormEditor v-if="assetTypeId" v-model="form" />
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import PreStartFormEditor from './PreStartFormEditor.vue';
import ConfirmModal from '@/components/modals/ConfirmModal.vue';

import DropDown from '@/components/dropdown/DropDown.vue';

import ReportIcon from '@/components/icons/Report.vue';

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
          };
        }),
      };
    }),
  };
}

function toForm(preStart) {
  if (!preStart) {
    return null;
  }
  return {
    title: '',
    details: '',
    sections: preStart.sections.map(s => {
      return {
        title: s.title,
        details: s.details,
        controls: s.controls.map(c => {
          return {
            label: c.label,
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
  },
  data: () => {
    return {
      reportIcon: ReportIcon,
      form: null,
      assetTypeId: null,
    };
  },
  computed: {
    ...mapState('constants', {
      assetTypes: state => [{ type: 'Select Asset' }].concat(state.assetTypes),
      preStarts: state => state.preStarts,
    }),
  },
  methods: {
    onAssetTypeChange(typeId) {
      this.assetTypeId = typeId;
      const preStart = this.preStarts.find(ps => ps.assetTypeId === typeId);
      this.form = toForm(preStart);
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
.pre-start-editor .dropdown-wrapper {
  width: 10rem;
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