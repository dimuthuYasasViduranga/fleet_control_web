<template>
  <span class="timezone-selector" @click="onOpenSelector">{{ display }} </span>
</template>

<script>
import { DateTime } from 'luxon';
import { zones } from 'tzdata';
import SelectModal from '@/components/modals/SelectModal.vue';

const VALID_TIMEZONES = Object.entries(zones)
  .filter(([_zoneName, value]) => Array.isArray(value))
  .map(([zoneName]) => zoneName)
  .filter(isValidTz)
  .sort((a, b) => a.localeCompare(b));

function isValidTz(tz) {
  return DateTime.local().setZone(tz).isValid;
}

function getHighlight(current) {
  if (current.isSite) {
    return 'site';
  }

  if (current.isLocal) {
    return 'local';
  }

  return current.timezone;
}

export default {
  name: 'TimezoneSelector',
  computed: {
    current() {
      return this.$timely.current;
    },
    display() {
      const current = this.current;
      const tz = current.timezone;
      if (current.isSite && current.isLocal) {
        return `${tz} (site/local)`;
      }

      if (current.isSite) {
        return `${tz} (site)`;
      }

      if (current.isLocal) {
        return `${tz} (local)`;
      }

      return tz;
    },
    timezoneOptions() {
      const localZone = this.$timely.localZone;
      const siteZone = this.$timely.siteZone;

      const normalTimezones = VALID_TIMEZONES.map(tz => ({ id: tz, name: tz }));

      if (localZone === siteZone) {
        return [{ id: 'site', name: `site/local (${localZone})` }].concat(normalTimezones);
      }
      return [
        { id: 'local', name: `local (${localZone})` },
        { id: 'site', name: `site (${siteZone})` },
      ].concat(normalTimezones);
    },
  },
  methods: {
    onOpenSelector() {
      const opts = {
        highlight: getHighlight(this.current),
        options: this.timezoneOptions,
      };
      this.$modal.create(SelectModal, opts).onClose(resp => {
        if (resp) {
          this.$timely.setCurrent(resp.id);
        }
      });
    },
  },
};
</script>

<style>
.timezone-selector {
  cursor: pointer;
  line-height: 2rem;
  margin: 0 0.5rem;
}

.timezone-selector:hover {
  opacity: 0.75;
}
</style>