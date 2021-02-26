<template>
  <div>
    <div class="title">Mass Message</div>
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
                :class="{ selected: selectedAssetIds.includes(asset.id) }"
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
    <div class="controls"></div>
    <div class="text-box-wrapper">
      <input
        class="message-box-input"
        type="text"
        v-model="text"
        :placeholder="messagePlaceholder"
        :maxLength="maxLength"
        @keydown="sendOnEnter"
      />
      <input
        v-if="showAnswers"
        class="message-box-input message-box-answer"
        type="text"
        v-model="answers.a"
        placeholder="Answer A"
        :maxLength="maxAnswerLength"
        @keydown="sendOnEnter"
      />

      <input
        v-if="showAnswers"
        class="message-box-input message-box-answer"
        type="text"
        v-model="answers.b"
        placeholder="Answer B"
        :maxLength="maxAnswerLength"
        @keydown="sendOnEnter"
      />
      <div class="button-wrapper">
        <Icon
          v-if="filteredQuickMessages.length"
          v-tooltip="'Quick Message'"
          class="quick-message"
          :icon="tagIcon"
          @click="onOpenQuickMessages()"
        />
        <button class="hx-btn button-send" @click="onSendMsg" :disabled="!canSend">Send</button>
        <button class="hx-btn button-clear" @click="onClearMsg">Clear</button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import Icon from 'hx-layout/Icon.vue';
import TagIcon from '@/components/icons/Tag.vue';
import { attributeFromList, uniq } from '@/code/helpers';
import { firstBy } from 'thenby';
import QuickSelectModal from '@/components/modals/QuickSelectModal.vue';

const ENTER = 13;

function validateMessage(selectedAssetIds, message, answers = [], maxLength) {
  const length = message.length;

  if (length === 0) {
    return 'Empty message not allowed';
  }

  if (length > maxLength) {
    return `Message must be less than ${this.maxLength} characters`;
  }

  if (selectedAssetIds.length === 0) {
    return 'Assets not selected';
  }

  if (message.includes('?') && answers.length !== 2) {
    return 'Question must have 2 answers';
  }

  if (!message.includes('?') && answers.length !== 0) {
    return 'Message contains answers but no question';
  }

  return '';
}

function groupHaulTrucks(type, assets, dispatches, locations) {
  const groupMap = assets.reduce((acc, asset) => {
    const [loadId, dumpId] = attributeFromList(dispatches, 'assetId', asset.id, [
      'loadId',
      'dumpId',
    ]);

    const id = `${loadId}|${dumpId}`;
    (acc[id] = acc[id] || []).push(asset);

    return acc;
  }, {});

  const groups = Object.keys(groupMap).map(key => {
    const [loadId, dumpId] = key.split('|');
    const loadName = attributeFromList(locations, 'id', parseInt(loadId, 10), 'name');
    const dumpName = attributeFromList(locations, 'id', parseInt(dumpId, 10), 'name');

    let name = 'Unassigned';

    if (loadName || dumpName) {
      name = `${loadName || 'Unassigned'} \n \u27f9 \n ${dumpName || 'Unassigned'}`;
    }

    return {
      name,
      loadName,
      dumpName,
      assets: groupMap[key],
    };
  });

  groups.sort(
    firstBy(a => a.loadName && a.dumpName)
      .thenBy('loadName')
      .thenBy('dumpName'),
  );

  return { type, groups };
}

function groupDigUnit(type, assets, activities, locations) {
  const groupMap = assets.reduce((acc, asset) => {
    const loadId = attributeFromList(activities, 'assetId', asset.id, 'locationId');
    (acc[loadId] = acc[loadId] || []).push(asset);
    return acc;
  }, {});

  const groups = Object.keys(groupMap).map(loadId => {
    const name = attributeFromList(locations, 'id', loadId, 'name') || 'Unassigned';
    return { name, assets: groupMap[loadId] };
  });

  groups.sort(firstBy('name'));
  return { type, groups };
}

export default {
  name: 'MassMsgModal',
  wrapperClass: 'mass-msg-modal',
  components: {
    Icon,
  },
  props: {
    assets: { type: Array, default: () => [] },
    maxLength: { type: Number, default: 40 },
    maxAnswerLength: { type: Number, default: 15 },
    quickMessages: { type: Array, default: () => [] },
  },
  data: () => {
    return {
      tagIcon: TagIcon,
      selectedAssetIds: [],
      text: '',
      answers: {
        a: '',
        b: '',
      },
    };
  },
  computed: {
    ...mapState('constants', {
      locations: state => state.locations,
      icons: state => state.icons,
    }),
    ...mapState({
      haulTruckDispatches: state => state.haulTruck.currentDispatches,
      digUnitActivities: state => state.digUnit.currentActivities,
    }),
    messagePlaceholder() {
      return `Enter message here (${this.maxLength}) characters max`;
    },
    canSend() {
      return this.selectedAssetIds.length !== 0 && this.text;
    },
    showAnswers() {
      return this.text.includes('?');
    },
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
            return groupHaulTrucks(type, assets, this.haulTruckDispatches, this.locations);

          case 'Excavator':
          case 'Loader':
            return groupDigUnit(type, assets, this.digUnitActivities, this.locations);

          default:
            return { type, groups: [{ assets }] };
        }
      });
    },
    filteredQuickMessages() {
      return this.quickMessages.filter(m => {
        const validAnswers = (m.answers || []).filter(a => a.length < this.maxAnswerLength);
        return m.message.length < this.maxLength && (validAnswers.length === 2 || !m.answers);
      });
    },
  },
  watch: {
    showAnswers: {
      immediate: true,
      handler(bool) {
        if (bool === false) {
          this.answers.a = '';
          this.answers.b = '';
        } else {
          this.answers.a = 'Yes';
          this.answers.b = 'No';
        }
      },
    },
  },
  methods: {
    close(resp) {
      this.$emit('close', resp);
    },
    onAssetClick(asset) {
      const index = this.selectedAssetIds.indexOf(asset.id);
      if (index > -1) {
        this.selectedAssetIds = this.selectedAssetIds.filter(id => id !== asset.id);
      } else {
        this.selectedAssetIds.push(asset.id);
      }
    },
    onCheckToggle(group) {
      const doRemoveAssets = group.state;
      const assetIds = group.assets.map(a => a.id);
      group.state = !doRemoveAssets;

      if (doRemoveAssets) {
        this.selectedAssetIds = this.selectedAssetIds.filter(
          assetId => !assetIds.includes(assetId),
        );
      } else {
        this.selectedAssetIds = uniq(this.selectedAssetIds.concat(assetIds));
      }
    },
    onSelectAll() {
      this.selectedAssetIds = uniq(this.assets.map(a => a.id));
      this.assetTypes.forEach(a => a.groups.forEach(g => (g.state = true)));
    },
    onDeselectAll() {
      this.selectedAssetIds = [];
      this.assetTypes.forEach(a => a.groups.forEach(g => (g.state = false)));
    },
    sendOnEnter(event) {
      if (event.keyCode === ENTER) {
        this.onSendMsg();
      }
    },
    onClearMsg() {
      this.text = '';
    },
    onOpenQuickMessages() {
      const items = this.filteredQuickMessages.map(m => {
        const label =
          (m.answers || []).length === 2 ? `${m.message} [${m.answers.join('|')}]` : m.message;
        return {
          label,
          message: m.message,
          answers: m.answers,
        };
      });

      const opts = { title: 'Quick Message', items, label: 'label' };
      this.$modal.create(QuickSelectModal, opts).onClose(resp => {
        if (!resp) {
          return;
        }

        this.text = resp.message;

        if ((resp.answers || []).length === 2) {
          this.answers.a = resp.answers[0];
          this.answers.b = resp.answers[1];
        }
      });
    },
    onSendMsg() {
      const message = this.text;
      const answers = Object.values(this.answers).filter(ans => ans);
      const error = validateMessage(this.selectedAssetIds, message, answers, this.maxLength);
      if (error) {
        this.$toasted.global.error(error);
        return;
      }

      if (this.selectedAssetIds.length === 1) {
        this.sendSingleMsg(this.selectedAssetIds[0], message, answers);
      } else {
        this.sendMassMsg(this.selectedAssetIds, message, answers);
      }
    },
    sendSingleMsg(assetId, message, answers = []) {
      const validAnswers = answers.length === 0 ? null : answers.map(a => a.toLowerCase());
      const payload = {
        message,
        asset_id: assetId,
        answers: validAnswers,
        timestamp: Date.now(),
      };

      this.$channel
        .push('add dispatcher message', payload)
        .receive('ok', () => this.close())
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to send message'));
    },
    sendMassMsg(assetIds, message, answers = []) {
      const validAnswers = answers.length === 0 ? null : answers.map(a => a.toLowerCase());
      const payload = {
        message,
        asset_ids: assetIds,
        answers: validAnswers,
        timestamp: Date.now(),
      };

      this.$channel
        .push('add mass dispatcher message', payload)
        .receive('ok', () => this.close())
        .receive('error', resp => this.$toasted.global.error(resp.error))
        .receive('timeout', () => this.$toasted.global.noComms('Unable to send message'));
    },
  },
};
</script>

<style>
.mass-msg-modal .modal-container {
  max-width: 70rem;
}
</style>

<style scoped>
@import '../../../assets/hxInput.css';

.title {
  font-size: 2rem;
  text-align: center;
  margin-bottom: 0.25rem;
}

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

.text-box-wrapper {
  padding-top: 2rem;
  width: 100%;
  display: flex;
}

.text-box-wrapper .message-box-input {
  margin-right: 0.5rem;
  flex: 1 1 auto;
  height: 2rem;
  border: none;
  border-radius: 0;
  border-bottom: 1px solid #677e8c;
  padding: 0 0.33rem;
  color: #b6c3cc;
  background-color: transparent;
  transition: background 0.4s, border-color 0.4s, color 0.4s;
}

.text-box-wrapper .message-box-input:focus {
  background-color: white;
  outline: none;
  color: #0c1419;
}

.text-box-wrapper .message-box-input::placeholder {
  color: #757575;
}

.text-box-wrapper .message-box-input:disabled {
  background-color: #293238;
  border-color: transparent;
  color: #0c1419;
}

.text-box-wrapper .message-box-answer {
  margin-right: 0.5rem;
  width: 4rem;
}

.text-box-wrapper .hx-btn:disabled {
  background-color: #333b41;
  color: #757575;
  cursor: default;
}

.text-box-wrapper .button-wrapper {
  display: flex;
}

.text-box-wrapper .button-wrapper .quick-message {
  padding-top: 0.5rem;
  cursor: pointer;
}

.text-box-wrapper .button-wrapper .button-send {
  margin-right: 0.1rem;
}
</style>