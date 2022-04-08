<template>
  <div class="asset-selector">
    <div class="actions">
      <button class="hx-btn" @click="onDeselectAll">Deselect All</button>
      <button class="hx-btn" @click="onSelectAll">Select All</button>
    </div>
    <div class="asset-types">
      <div class="asset-type" v-for="assetType in assetTypes" :key="assetType.type">
        <div class="asset-icon">
          <Icon v-tooltip="assetType.type" :icon="icons[assetType.type]" />
        </div>
        <div class="asset-groups">
          <div
            class="asset-group"
            v-for="(group, groupIndex) in assetType.groups"
            :key="groupIndex"
          >
            <div class="group-name">{{ group.name }}</div>
            <div class="assets">
              <button
                class="hx-btn asset"
                v-for="(asset, assetIndex) in group.assets"
                :key="assetIndex"
                :class="{ selected: value.includes(asset.id) }"
                @click="onAssetClick(asset)"
              >
                {{ asset.name }}
              </button>
            </div>
            <div class="check-toggle">
              <input type="checkbox" :checked="group.state" @change="onCheckToggle(group)" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Icon from 'hx-layout/Icon.vue';

import { attributeFromList, Dictionary, uniq } from '@/code/helpers';
import { mapState } from 'vuex';
import { firstBy } from 'thenby';

function groupHaulTrucks(type, haulTrucks, allAssets, dispatches, activities, locations) {
  const groupDic = new Dictionary();
  haulTrucks.forEach(ht => {
    const [loadId, digUnitId, dumpId] = attributeFromList(dispatches, 'assetId', ht.id, [
      'loadId',
      'digUnitId',
      'dumpId',
    ]);
    groupDic.append([loadId, digUnitId, dumpId], ht);
  });
  const groups = groupDic.map(([loadId, digUnitId, dumpId], hts) => {
    const { source, dump } = getDispatchRouteNames(
      loadId,
      digUnitId,
      dumpId,
      allAssets,
      locations,
      activities,
    );
    let routeName = 'Unassigned';
    if (source || dump) {
      routeName = `${source || 'No Source'} \n \u27f9 \n ${dump || 'No Dump'}`;
    }
    return {
      name: routeName,
      source,
      dump,
      assets: hts,
    };
  });
  groups.sort(
    firstBy(a => a.source && a.dump)
      .thenBy('source')
      .thenBy('dump'),
  );
  return { type, groups };
}

function getDispatchRouteNames(loadId, digUnitId, dumpId, assets, locations, activities) {
  const dump = attributeFromList(locations, 'id', dumpId, 'name');
  if (digUnitId) {
    const digUnit = attributeFromList(assets, 'id', digUnitId) || {};
    const digUnitLocationId = attributeFromList(activities, 'assetId', digUnitId, 'locationId');
    const digUnitLocation = attributeFromList(locations, 'id', digUnitLocationId, 'name');
    const sourceName = digUnitLocation ? `${digUnit.name} (${digUnitLocation})` : digUnit.name;
    return { source: sourceName, dump };
  } else {
    const loadName = attributeFromList(locations, 'id', loadId, 'name');
    return { source: loadName, dump };
  }
}

function groupDigUnit(type, digUnits, activities, locations) {
  const dict = new Dictionary();
  digUnits.forEach(digUnit => {
    const loadId = attributeFromList(activities, 'assetId', digUnit.id, 'locationId') || null;
    dict.append(loadId, digUnit);
  });
  const groups = dict
    .map((loadId, assets) => {
      const loadName = attributeFromList(locations, 'id', loadId, 'name');
      return { name: loadName, assets };
    })
    .sort(firstBy('name'));
  return { type, groups };
}

export default {
  name: 'AssetSelector',
  components: {
    Icon,
  },
  props: {
    value: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
  },
  computed: {
    ...mapState('constants', {
      icons: state => state.icons,
      locations: state => state.locations,
    }),
    ...mapState({
      haulTruckDispatches: state => state.haulTruck.currentDispatches,
      digUnitActivities: state => state.digUnit.currentActivities,
    }),
    assetTypes() {
      const typeMap = this.assets.reduce((acc, asset) => {
        (acc[asset.type] = acc[asset.type] || []).push(asset);
        return acc;
      }, {});

      const types = Object.keys(typeMap).sort((a, b) => a.localeCompare(b));
      return types.map(type => {
        const assets = typeMap[type];
        assets.sort((a, b) => a.name.localeCompare(b.name));
        switch (type) {
          case 'Haul Truck':
            return groupHaulTrucks(
              type,
              assets,
              this.assets,
              this.haulTruckDispatches,
              this.digUnitActivities,
              this.locations,
            );

          case 'Excavator':
          case 'Loader':
            return groupDigUnit(type, assets, this.digUnitActivities, this.locations);

          default:
            return { type, groups: [{ assets }] };
        }
      });
    },
  },
  methods: {
    onDeselectAll() {
      this.setSelected([]);
      this.assetTypes.forEach(a => a.groups.forEach(g => (g.state = false)));
    },
    onSelectAll() {
      const selected = uniq(this.assets.map(a => a.id));
      this.setSelected(selected);
      this.assetTypes.forEach(a => a.groups.forEach(g => (g.state = true)));
    },
    onAssetClick(asset) {
      const index = this.value.indexOf(asset.id);
      if (index > -1) {
        const selected = this.value.filter(id => id !== asset.id);
        this.setSelected(selected);
      } else {
        const selected = this.value.slice();
        selected.push(asset.id);
        this.setSelected(selected);
      }
    },
    onCheckToggle(group) {
      const doRemoveAssets = group.state;
      const assetIds = group.assets.map(a => a.id);
      group.state = !doRemoveAssets;

      if (doRemoveAssets) {
        const selected = this.value.filter(assetId => !assetIds.includes(assetId));
        this.setSelected(selected);
      } else {
        const selected = uniq(this.value.concat(assetIds));
        this.setSelected(selected);
      }
    },
    setSelected(arr) {
      this.$emit('input', arr);
    },
  },
};
</script>

<style scoped>
.actions {
  display: flex;
  width: 100%;
  margin-bottom: 0.25rem;
  border-bottom: 1px solid #677e8c;
}

.actions button {
  width: 100%;
  margin: 0.1rem;
}

.asset-type {
  display: flex;
  padding-top: 0.25rem;
  padding-bottom: 0.25rem;
  border-bottom: 1px solid #677e8c;
}

.asset-type .asset-icon {
  margin: auto 0;
  margin-right: 1rem;
}

.asset-type .asset-icon .hx-icon {
  width: 3rem;
  height: 3rem;
}

.asset-groups {
  width: 100%;
}

.asset-groups .asset-group {
  display: flex;
  padding: 1rem 0;
  border-top: 1px solid #4d5f69;
}

.asset-groups .asset-group:nth-child(1) {
  border: none;
}

.asset-groups .asset-group .group-name {
  white-space: pre;
  text-align: center;
  min-width: 8rem;
  padding: 0.1rem;
  margin: auto 0;
  text-transform: capitalize;
}

.asset-groups .asset-group .assets {
  margin: auto 0;
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-start;
  flex-grow: 1;
}

.asset-groups .asset-group .asset {
  border: 0.05rem solid rgba(255, 255, 255, 0.1);
  opacity: 0.75;
  background-color: #425866;
}

.asset-groups .asset-group .asset.selected {
  opacity: 1;
  border-color: orange;
  background-color: #6e5a33;
}

.asset-groups .asset-group .check-toggle {
  text-align: center;
  margin: auto 0;
  width: 3rem;
}

.asset-groups .asset-group .check-toggle input {
  cursor: pointer;
  width: 1.25em;
  height: 1.25rem;
}
</style>