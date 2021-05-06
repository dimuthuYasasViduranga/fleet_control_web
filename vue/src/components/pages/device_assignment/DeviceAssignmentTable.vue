<template>
  <div class="device-assignment-table">
    <table-component
      table-wrapper="#content"
      table-class="table"
      tbody-class="table-body"
      thead-class="table-head"
      filterNoResults="No Authorized Devices"
      :data="assignments"
      :show-caption="false"
      :show-filter="true"
      sort-by="formattedDeviceName"
    >
      <table-column cell-class="indicator-cel">
        <template slot-scope="row">
          <div
            v-if="highlightUUIDs.includes(row.deviceUUID)"
            v-tooltip="'Recently Added'"
            class="indicator"
          />
        </template>
      </table-column>

      <table-column cell-class="table-cel" show="formattedDeviceName" label="Device" />

      <table-column label="Asset" cell-class="table-cel" show="assetName">
        <template slot-scope="row">
          <div class="asset-selection">
            <DropDown
              v-model="row.assetId"
              :items="dropdownAssets"
              label="label"
              :useScrollLock="false"
              @change="onChange(row)"
            />
            <Icon
              v-if="row.hasMultipleAssignments"
              v-tooltip="getMultipleAssignmentTooltip(row)"
              :icon="alertIcon"
            />
          </div>
        </template>
      </table-column>

      <table-column cell-class="table-icon-cel">
        <template slot-scope="row">
          <span :class="setPresenceIconColor(row.present)">
            <Icon :icon="icons[row.assetType] || tabletIcon" />
          </span>
        </template>
      </table-column>

      <table-column
        cell-class="table-cel table-operator-cel"
        label="Operator"
        show="operatorName"
      />

      <table-column cell-class="table-action-cel">
        <template slot-scope="row">
          <div class="action-cel">
            <div class="actions">
              <lockable-button @click="onForceLogout(row)" :lock="!row.operatorId">
                Logout
              </lockable-button>
              <lockable-button @click="onOpenRevokeConfirm(row)" :lock="!!row.assetId">
                Revoke
              </lockable-button>
            </div>
            <div class="icons">
              <Icon
                v-tooltip="'More Info'"
                class="info-icon"
                :icon="infoIcon"
                @click="onOpenDeviceInfo(row)"
              />
            </div>
          </div>
        </template>
      </table-column>
    </table-component>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';
import { TableComponent, TableColumn } from 'vue-table-component';

import ConfirmModal from '../../modals/ConfirmModal.vue';
import DeviceInfoModal from './DeviceInfoModal.vue';
import DeviceLogoutModal from './DeviceLogoutModal.vue';

import LockableButton from '../../LockableButton.vue';
import DropDown from '../../dropdown/DropDown.vue';

import TabletIcon from '../../icons/Tablet.vue';
import InfoIcon from '../../icons/Info.vue';
import AlertIcon from '../../icons/Alert.vue';
import { attributeFromList } from '@/code/helpers';

const WARNING = `Revoking a device will prevent it from being able to log into FleetControl.

Revoked devices can only be re-authorized by following the 'Device Authorization' procedure.
`;

export default {
  name: 'DeviceAssignmentTable',
  components: {
    Icon,
    TableComponent,
    TableColumn,
    DropDown,
    LockableButton,
  },
  props: {
    assignments: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
    allocations: { type: Array, default: () => [] },
    fullTimeCodes: { type: Array, default: () => [] },
    icons: { type: Object, default: () => ({}) },
    highlightUUIDs: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      tabletIcon: TabletIcon,
      infoIcon: InfoIcon,
      alertIcon: AlertIcon,
    };
  },
  computed: {
    dropdownAssets() {
      const userAssetIds = this.assignments.filter(a => a.deviceId).map(a => a.assetId);

      const dropdownAssets = this.assets.map(asset => {
        const label = asset.type ? `${asset.name} (${asset.type})` : asset.name;
        return {
          id: asset.id,
          name: asset.name,
          type: asset.type,
          label,
          disabled: userAssetIds.includes(asset.id),
        };
      });

      const unassignedOpt = { id: null, label: 'Not Assigned' };

      return [unassignedOpt].concat(dropdownAssets);
    },
  },
  methods: {
    setPresenceIconColor(isPresent) {
      if (isPresent) {
        return 'green-icon';
      }
      return 'grey-icon';
    },
    onChange(row) {
      this.$emit('change', row);
    },
    onForceLogout({ deviceId, assetId, assetTypeId }) {
      if (!assetTypeId) {
        console.error('[Device Assign] No asset type, forcing logout');
        this.$emit('logout', { deviceId });
        return;
      }

      const allowedTimeCodeIds = this.fullTimeCodes
        .filter(tc => !tc.isReady && tc.assetTypeIds.includes(assetTypeId))
        .map(tc => tc.id);

      const activeTimeCodeId = attributeFromList(
        this.allocations,
        'assetId',
        assetId,
        'timeCodeId',
      );

      this.$modal
        .create(DeviceLogoutModal, { timeCodeId: activeTimeCodeId, allowedTimeCodeIds })
        .onClose(answer => {
          if (answer && answer.timeCodeId) {
            this.$emit('logout', { deviceId, timeCodeId: answer.timeCodeId });
          }
        });
    },
    onOpenRevokeConfirm(row) {
      this.$modal
        .create(ConfirmModal, { title: 'Warning - Permanent Change', body: WARNING, ok: 'Revoke' })
        .onClose(answer => {
          if (answer === 'Revoke' && row.deviceId) {
            this.$emit('revoke', row.deviceId);
          }
        });
    },
    onOpenDeviceInfo(row) {
      this.$modal.create(DeviceInfoModal, { device: row });
    },
    getMultipleAssignmentTooltip(row) {
      const items = row.multipleAssignmentAssetNames.map(name => `<li>${name}</li>`).join('');
      const assetList = `<ul>${items}</ul>`;

      const content = `Multiple assets assigned to this device\n${assetList}\nPlease unassign`;

      return {
        html: true,
        content,
      };
    },
  },
};
</script>

<style>
.device-assignment-table .dropdown-wrapper {
  width: 100%;
  height: 2rem;
}

.device-assignment-table .info-icon {
  cursor: pointer;
  padding: 4px;
  margin-left: 2rem;
}

.device-assignment-table .indicator-cel {
  width: 1rem;
  padding: 0;
}

.device-assignment-table .indicator-cel .indicator {
  background-color: orange;
  width: 1rem;
  height: 2rem;
}

.device-assignment-table .table-icon-cel {
  width: 0.1rem;
}

.device-assignment-table .table-action-cel {
  width: 6rem;
}

.device-assignment-table .action-cel {
  display: flex;
  height: 100%;
}

.device-assignment-table .actions {
  display: flex;
}

.device-assignment-table .actions span {
  margin-left: 2rem;
  line-height: 2rem;
}

.device-assignment-table .asset-selection {
  display: flex;
}

.device-assignment-table .asset-selection .hx-icon {
  stroke: orange;
  margin-left: 10px;
}

.device-assignment-table .asset-selection .hx-icon svg {
  stroke-width: 2;
}

@media screen and (max-width: 950px) {
  .device-assignment-table .table-operator-cel {
    display: none;
  }
}
</style>