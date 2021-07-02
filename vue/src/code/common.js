import TabletIcon from '@/components/icons/Tablet.vue';
import CrossIcon from 'hx-layout/icons/Error.vue';
import NoWifiIcon from '@/components/icons/NoWifi.vue';

export function getAssetTileSecondaryIcon(asset) {
  const activeAllocGroup = asset.activeTimeAllocation.groupName;

  if (!asset.hasDevice) {
    return TabletIcon;
  }

  if (asset.operator.id && !asset.present) {
    return NoWifiIcon;
  }

  if (activeAllocGroup === 'Down') {
    return CrossIcon;
  }

  return null;
}
