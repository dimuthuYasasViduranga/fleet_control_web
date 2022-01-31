<template>
  <div class="agents-page">
    <hxCard title="Settings" :icon="cogIcon">
      <table>
        <tr v-for="[key, bool] in Object.entries(settings)" :key="key">
          <td>{{ key }}</td>
          <td>{{ bool }}</td>
        </tr>
      </table>
    </hxCard>
    <hxCard title="Use device GPS" :icon="locationIcon">
      <button class="hx-btn" :class="{ selected: useDeviceGPS }" @click="onSetUseGPS(true)">
        Use
      </button>
      <button class="hx-btn" :class="{ selected: !useDeviceGPS }" @click="onSetUseGPS(false)">
        Ignore
      </button>
    </hxCard>
    <hxCard title="Agents" :icon="databaseIcon">
      <div class="agent" v-for="(agent, index) in agents" :key="index">
        <Icon :icon="databaseIcon" />
        <span class="name">{{ agent.name }}</span>
        <button class="hx-btn" @click="onConfirmRefresh(agent)">Refresh</button>
      </div>
    </hxCard>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import DatabaseIcon from '@/components/icons/Database.vue';
import LocationIcon from '@/components/icons/Location.vue';
import CogIcon from '@/components/icons/Cog.vue';
import ConfirmModal from '../../modals/ConfirmModal.vue';

const AGENTS = [
  { name: 'Asset Agent', topic: 'asset agent' },
  { name: 'Location Agent', topic: 'location agent' },
  { name: 'Calendar Agent', topic: 'calendar agent' },
  { name: 'Device Agent', topic: 'device agent' },
  { name: 'Operator Agent', topic: 'operator agent' },
  { name: 'Operator Message Agent', topic: 'operator message agent' },
  { name: 'Time Code Agent', topic: 'time code agent' },
  { name: 'FleetOps Agent', topic: 'fleetops agent' },
  { name: 'Pre-Start Agent', topic: 'pre-start agent' },
  { name: 'Pre-Start Submission Agent', topic: 'pre-start submission agent' },
];

export default {
  name: 'Agents',
  components: {
    hxCard,
    Icon,
  },
  data: () => {
    return {
      databaseIcon: DatabaseIcon,
      locationIcon: LocationIcon,
      cogIcon: CogIcon,
      agents: AGENTS,
    };
  },
  computed: {
    ...mapState('settings', {
      settings: state => state,
      useDeviceGPS: state => state.use_device_gps,
    }),
  },
  methods: {
    onConfirmRefresh(agent) {
      this.$modal
        .create(ConfirmModal, {
          title: agent.name,
          body: 'Are you sure you want to refresh this agent?',
        })
        .onClose(answer => {
          if (answer === 'ok') {
            this.refresh(agent);
          }
        });
    },
    refresh(agent) {
      console.log(`[Agents] Requesting refresh for agent '${agent.topic}'`);
      this.$channel
        .push(`refresh:${agent.topic}`, {})
        .receive('ok', () => {
          this.$toaster.info(`${agent.name} updated`);
        })
        .receive('error', error => this.$toaster.error(error.error))
        .receive('timeout', () => this.$toaster.noComms(`Unable to update ${agent.name} `));
    },
    onSetUseGPS(bool) {
      if (bool === this.useDeviceGPS) {
        return;
      }

      this.$modal
        .create(ConfirmModal, {
          title: 'Change GPS Mode',
          body: 'Are you sure that you want to change the GPS aquisition mode?',
          ok: 'yes',
        })
        .onClose(resp => {
          if (resp === 'yes') {
            this.setUseGPS(bool);
          }
        });
    },
    setUseGPS(bool) {
      console.log(`[Device GPS] Requesting use device GPS = ${bool}`);
      this.$channel
        .push('track:set use device gps', { state: bool })
        .receive('ok', () => {
          this.$toaster.info('Device GPS Mode updated');
        })
        .receive('error', error => this.$toaster.error(error.error))
        .receive('timeout', () =>
          this.$toaster.noComms('Unable to update device GPS mode at this time'),
        );
    },
  },
};
</script>

<style>
.agents-page .selected {
  background-color: #2c404c;
  border: 1px solid #898f94;
}

.agents-page .agent {
  padding-bottom: 2rem;
  display: flex;
}

.agents-page .name {
  width: 15rem;
  line-height: 2rem;
}
</style>