<template>
  <div class="agents-page">
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
import hxCard from 'hx-layout/Card.vue';
import Icon from 'hx-layout/Icon.vue';
import DatabaseIcon from '../../icons/Database.vue';
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
      agents: AGENTS,
    };
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
  },
};
</script>

<style>
.agents-page .agent {
  padding-bottom: 2rem;
  display: flex;
}

.agents-page .name {
  width: 15rem;
  line-height: 2rem;
}
</style>