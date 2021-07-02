import TabletIcon from '@/components/icons/Tablet.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import NoWifiIcon from '@/components/icons/NoWifi.vue';

export function getAssetTileSecondaryIcon(asset) {
  const activeAllocGroup = asset.activeTimeAllocation.groupName;

  if (!asset.hasDevice) {
    return TabletIcon;
  }

  // if the operator is a non-empty string, or if the operator has an id
  const hasOperator = asset.operator && (typeof asset.operator === 'string' || asset.operator.id);
  if (hasOperator && !asset.present) {
    return NoWifiIcon;
  }

  if (activeAllocGroup === 'Down') {
    return CrossIcon;
  }

  return null;
}
