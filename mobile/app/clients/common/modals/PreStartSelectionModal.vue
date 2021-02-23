<template>
  <ScrollView class="pre-start-selection-modal">
    <StackLayout class="content">
      <CenteredLabel class="title" text="Offline Pre-Start" />
      <GridLayout rows="80 80" columns="* 3*">
        <!-- Employee ID -->
        <CenteredLabel row="0" col="0" text="ID" />
        <TextField
          row="0"
          col="1"
          class="employee-id"
          v-model="localEmployeeId"
          keyboardType="number"
          hint="Employee ID"
          returnKeyType="done"
        />

        <!-- Asset -->
        <CenteredLabel row="1" col="0" text="Asset" />
        <DropDown row="1" col="1" v-model="selectedAssetId" :options="assetOptions" label="name" />
      </GridLayout>
      <GridLayout class="actions" columns="* *">
        <Button col="0" class="button" text="Next" :isEnabled="!!localEmployeeId" @tap="onNext()" />
        <Button col="1" class="button" text="Cancel" @tap="onCancel()" />
      </GridLayout>
    </StackLayout>
  </ScrollView>
</template>

<script>
import CenteredLabel from '../CenteredLabel.vue';
import PreStartModal from './PreStartModal.vue';
import DropDown from '../DropDown.vue';
import { attributeFromList } from '../../code/helper';

export default {
  name: 'PreStartSelectionModal',
  components: {
    CenteredLabel,
    PreStartModal,
    DropDown,
  },
  props: {
    employeeId: { type: String, default: '' },
    assetId: { type: [String, Number], default: null },
    assets: { type: Array, default: () => [] },
    operators: { type: Array, default: () => [] },
    preStarts: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      localEmployeeId: '',
      selectedAssetId: null,
    };
  },
  computed: {
    assetOptions() {
      return this.assets.map(a => {
        const name = a.type ? `${a.name} (${a.type})` : a.name;
        return {
          id: a.id,
          name,
        };
      });
    },
    selectedAssetTypeId() {
      return attributeFromList(this.assets, 'id', this.selectedAssetId, 'typeId');
    },
    preStart() {
      return attributeFromList(this.preStarts, 'assetTypeId', this.selectedAssetTypeId);
    },
  },
  mounted() {
    this.localEmployeeId = this.employeeId;
    this.selectedAssetId = attributeFromList(this.assets, 'id', this.assetId, 'id');
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onCancel() {
      this.close();
    },
    onNext() {
      const preStart = this.preStart;
      const asset = attributeFromList(this.assets, 'id', this.selectedAssetId);

      if (!preStart || !asset) {
        this.$toaster.red('No Pre-Start available for this asset type', 'long').show();
        return;
      }

      const employeeId = this.localEmployeeId;
      const operator = attributeFromList(this.operators, 'employeeId', employeeId) || {
        employeeId,
      };

      const opts = {
        asset,
        operator,
        preStarts: this.preStarts,
      };

      this.$modalBus.open(PreStartModal, opts).onClose(this.close);
    },
  },
};
</script>

<style>
.pre-start-selection-modal {
  background-color: white;
  height: auto;
  width: 70%;
}

.pre-start-selection-modal .content {
  padding: 25 50;
}

.pre-start-selection-modal .title {
  background-color: rgb(226, 226, 226);
  margin-bottom: 15;
  font-weight: bold;
}

.pre-start-selection-modal .centered-label {
  font-size: 30;
}

.pre-start-selection-modal .employee-id {
  height: 100%;
  font-size: 30;
}

.pre-start-selection-modal .dropdown .dropdown-btn {
  font-size: 30;
}

.pre-start-selection-modal .actions {
  margin-top: 30;
}

.pre-start-selection-modal .button {
  font-size: 26;
  height: 80;
}

.pre-start-selection-modal .button[isEnabled='false'] {
  opacity: 0.5;
}
</style>